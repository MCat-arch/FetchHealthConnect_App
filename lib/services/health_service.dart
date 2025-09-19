import 'package:aura/model/health_data.dart';
import 'package:aura/model/health_day_data.dart';
import 'package:aura/services/notification_service.dart';
import 'package:aura/utils/storage_helper.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class HealthService {
  static final Health _health = Health();
  static const int _panicThreshold = 85;
  static const index = Uuid();

  /// ✅ Minta permission runtime
  static Future<void> requestRuntimePermissions() async {
    final activityGranted = await Permission.activityRecognition.request();
    final sensorGranted = await Permission.sensors.request();

    final allGranted = activityGranted.isGranted && sensorGranted.isGranted;
    await StorageHelper.permissionGranted(allGranted);
  }

  /// ✅ Pastikan permission sudah granted
  static Future<void> ensurePermissions() async {
    final fromStorage = await StorageHelper.isPermissionGranted();
    if (!fromStorage) {
      throw Exception('Health permissions not granted (saved status)');
    }

    final types = [HealthDataType.HEART_RATE, HealthDataType.STEPS];
    final has = await _health.hasPermissions(types);
    if (has != true) {
      throw Exception('Health permissions not granted (recheck)');
    }
  }

  /// ✅ Fetch raw data dari Health API
  static Future<List<HealthDataPoint>> fetchHealthDataRaw(
    DateTime start,
    DateTime end,
  ) async {
    await ensurePermissions();
    final types = [HealthDataType.HEART_RATE, HealthDataType.STEPS];
    return await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: types,
    );
  }

  /// ✅ Proses raw data jadi HealthData + HealthDayData
  static Map<String, HealthData> groupedHealthData(List<HealthDataPoint> raw) {
    final Map<String, HealthData> grouped = {};

    for (var p in raw) {
      final dateKey =
          "${p.dateFrom.year}-${p.dateFrom.month.toString().padLeft(2, '0')}-${p.dateFrom.day.toString().padLeft(2, '0')}";

      int? hr;
      int? steps;
      String kategori = '';

      if (p.type == HealthDataType.HEART_RATE) {
        hr = _parseToInt(p.value);
        kategori = _mapCategory(hr);
      }
      if (p.type == HealthDataType.STEPS) {
        steps = _parseToInt(p.value);
      }

      grouped.putIfAbsent(dateKey, () {
        return HealthData(id: dateKey, date: dateKey, details: []);
      });

      grouped[dateKey]!.details.add(
        HealthDayData(
          kategori,
          p.dateFrom.toLocal().toIso8601String(),
          hr,
          steps,
        ),
      );
    }

    return grouped;
  }

  //initial fetch
  static Future<void> intitalFetch() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 1));
    final raw = await fetchHealthDataRaw(start, now);
    final grouped = groupedHealthData(raw);

    for (final entry in grouped.entries) {
      final date = entry.key;
      final details = entry.value.details;

      final existingID = await StorageHelper.getDetailIdsForDate(date);

      final newDetails = details
          .where((d) => !existingID.contains(d.time))
          .toList();

      if (newDetails.isEmpty) continue;

      await StorageHelper.addHealthDayDataBatch(date, newDetails);

      final newPanicCount = newDetails
          .where((d) => d.kategori == 'panic')
          .length;
      if (newPanicCount > 0) {
        await StorageHelper.incrementPanicCount(date, newPanicCount);
        // opsi: notifikasi bisa dikirim juga untuk initialFetch, atau skip to avoid spam
        // await NotificationService.showNotification(title: "...", body: "...");
      }

      // Simpan/update daily meta (merge)
      await StorageHelper.saveHealthData(
        HealthData(
          id: date,
          date: date,
          panicCount: 0, // actual count di Firestore via increment
          details: [], // details stored in subcollection
        ),
      );

      await StorageHelper.saveLastFetchTime(now);
    }
  }

  /// ✅ Jalankan background fetch setiap 15–30 menit
  static Future<void> backgroundFetch() async {
    final now = DateTime.now();
    final lastFetch = await StorageHelper.getLastFetchTime();
    final start = lastFetch ?? DateTime.now().subtract(const Duration(minutes: 30));

    final raw = await fetchHealthDataRaw(start, now);
    final grouped = groupedHealthData(raw);

    final List<HealthDayData> newPanics = [];

    for (final entry in grouped.entries) {
      final date = entry.key;
      final details = entry.value.details;

      final existingIds = await StorageHelper.getDetailIdsForDate(date);
      final newDetails = details
          .where((d) => !existingIds.contains(d.time))
          .toList();
      if (newDetails.isEmpty) continue;

      // batch insert newDetail
      await StorageHelper.addHealthDayDataBatch(date, newDetails);

      // hitung panic baru dan increment panicCount
      final newPanicCount = newDetails
          .where((d) => d.kategori == 'panic')
          .length;
      if (newPanicCount > 0) {
        await StorageHelper.incrementPanicCount(date, newPanicCount);
        newPanics.addAll(newDetails.where((d) => d.kategori == 'panic'));
      }

      // update daily meta (merge)
      await StorageHelper.saveHealthData(
        HealthData(id: date, date: date, panicCount: 0, details: []),
      );
    }

    // Kirim notifikasi ringkasan untuk panic baru — hanya jika ada panic baru
    if (newPanics.isNotEmpty) {
      // kita kirim single notification summarizing times
      final times = newPanics.map((p) => p.time.substring(11, 19)).join(', ');
      await NotificationService().showNotification(
        title: "⚠️ Panic Detected",
        body: "${newPanics.length} event(s) at $times",
      );
    }
  }

  /// ✅ Tambah label manual
  static Future<void> addManualLabel(
    String kategori, {
    int? hr,
    int? steps,
  }) async {
    final now = DateTime.now();
    final dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final detail = HealthDayData(kategori, now.toIso8601String(), hr, steps);

    await StorageHelper.addHealthDayData(dateKey, detail);
  }

  /// ✅ Map kategori berdasarkan HR
  static String _mapCategory(int? hr) {
    if (hr == null) return 'No HR';
    if (hr > _panicThreshold) return 'panic';
    if (hr < 60) return 'low';
    return 'normal';
  }

  /// ✅ Helper konversi value ke int
  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);

    // NumericHealthValue fallback
    if (value.runtimeType.toString() == 'NumericHealthValue') {
      try {
        final numVal = value.numericValue;
        if (numVal is int) return numVal;
        if (numVal is double) return numVal.round();
      } catch (_) {}
    }
    return null;
  }
}
