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
  static const _uuid = Uuid();

  static Future<void> requestRuntimePermissions() async {
    final activityGranted = await Permission.activityRecognition.request();
    final sensorGranted = await Permission.sensors.request();

    final allGranted = activityGranted.isGranted && sensorGranted.isGranted;

    await StorageHelper.permissionGranted(allGranted);
  }

  static Future<void> ensurePermissions() async {
    // Cek dulu dari Storage
    final fromStorage = await StorageHelper.isPermissionGranted();
    if (!fromStorage) {
      throw Exception('Health Connect permissions not granted (saved status)');
    }

    final types = [HealthDataType.HEART_RATE, HealthDataType.STEPS];
    final has = await _health.hasPermissions(types);
    if (has != true) {
      throw Exception('Health Connect permissions not granted (recheck)');
    }
  }

  //with data categorized per date
  static Future<List<HealthData>> fetchData(bool fromBackground) async {
    final now = DateTime.now();

    final localData = await StorageHelper.loadFromLocal() ?? [];

    DateTime start;
    if (localData.isNotEmpty) {
      final latestDateStr = localData.first.date;
      start = DateTime.parse(latestDateStr).subtract(const Duration(days: 1));
    } else {
      start = now.subtract(const Duration(days: 7)); // ambil 7 hari terakhi
    }
    final types = [HealthDataType.HEART_RATE, HealthDataType.STEPS];

    // await requestRuntimePermissions();
    // await ensurePermissions();
    if (!fromBackground) {
      await requestRuntimePermissions();
      await ensurePermissions();
    }

    final raw = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: now,
      types: types,
    );

    // Kelompokkan berdasarkan tanggal
    final Map<String, List<HealthDayData>> grouped = {};

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

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(
        HealthDayData(
          kategori,
          p.dateFrom.toLocal().toIso8601String(),
          hr,
          steps,
        ),
      );
    }

    // // Buat list HealthData per tanggal
    // final List<HealthData> result = [];
    // grouped.forEach((date, details) {
    //   final panicCount = details
    //       .where((d) => d.hr != null && d.hr! > _panicThreshold)
    //       .length;
    //   result.add(HealthData(_uuid.v4(), date, panicCount, details));
    // });

    final List<HealthData> fetchedList = grouped.entries.map((entry) {
      final panicCount = entry.value
          .where((d) => d.hr != null && d.hr! > _panicThreshold)
          .length;
      return HealthData(_uuid.v4(), entry.key, panicCount, entry.value);
    }).toList();

    // Urutkan dari tanggal terbaru
    // fetchedList.sort((a, b) => b.date.compareTo(a.date));

    final Map<String, HealthData> mergedMap = {
      for (var data in localData) data.date: data,
      for (var data in fetchedList) data.date: data,
    };

    final mergedList = mergedMap.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    print('=== DEBUG: HealthData per tanggal ===');
    for (var hd in mergedList) {
      for (var kategori in hd.details) {
        if (kategori.kategori == "panic") {
          await NotificationService().showNotification(
            title: "Panic Detected",
            body: "Heart rate tinggi terdeteksi pada salah satu hari Anda!",
          );
        }
      }
      print(
        'Tanggal: ${hd.date}, Panic: ${hd.panicCount}, Detail: ${hd.details.length}',
      );
    }
    await StorageHelper.saveData(mergedList);
    return mergedList;
  }

  static String _mapCategory(int? hr) {
    if (hr == null) return 'No HR';
    if (hr > _panicThreshold) return 'panic';
    if (hr < 60) return 'low';
    return 'normal';
  }

  static int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    // Tambahan: handle NumericHealthValue
    if (value.runtimeType.toString() == 'NumericHealthValue') {
      // Coba akses field numericValue secara dinamis
      try {
        final numVal = value.numericValue;
        if (numVal is int) return numVal;
        if (numVal is double) return numVal.round();
      } catch (_) {}
    }
    return null;
  }
}

// // lib/services/health_service.dart
// import 'package:aura/model/health_data.dart';
// import 'package:aura/model/health_day_data.dart';
// import 'package:aura/services/notification_service.dart';
// import 'package:health/health.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:uuid/uuid.dart';

// class HealthService {
//   static final Health _health = Health();
//   static const int _panicThreshold = 85;
//   static const _uuid = Uuid();

//   /// Request runtime permissions (Android 10+/13+)
//   static Future<void> requestRuntimePermissions() async {
//     await Permission.activityRecognition.request();
//     await Permission.sensors.request();
//   }

//   /// Request Health Connect permissions
//   static Future<void> ensurePermissions() async {
//     final types = [HealthDataType.HEART_RATE, HealthDataType.STEPS];
//     final has = await _health.hasPermissions(types);
//     if (has != true) {
//       final granted = await _health.requestAuthorization(types);
//       if (!granted) throw Exception('Health Connect permissions not granted');
//     }
//   }

//   /// Fetch and process health data
//   static Future<List<HealthData>> fetchData() async {
//     final now = DateTime.now();
//     final yesterday = now.subtract(const Duration(days: 1));
//     final types = [HealthDataType.HEART_RATE, HealthDataType.STEPS];
//     // Set waktu mulai dan akhir untuk hari kemarin
//     final start = DateTime(
//       yesterday.year,
//       yesterday.month,
//       yesterday.day,
//       0,
//       0,
//       0,
//     );
//     final end = DateTime(
//       yesterday.year,
//       yesterday.month,
//       yesterday.day,
//       23,
//       59,
//       59,
//     );
//     // 1. Request runtime permissions
//     await requestRuntimePermissions();

//     // 2. Request Health Connect permissions
//     await ensurePermissions();

//     // 3. Fetch data
//     final raw = await _health.getHealthDataFromTypes(
//       startTime: start,
//       endTime: end,
//       types: types,
//     );

//     // Gabungkan data berdasarkan waktu (timestamp)
//     final Map<String, HealthDayData> dataMap = {};

//     for (var p in raw) {
//       final timeKey = p.dateFrom.toLocal().toIso8601String();
//       final existing = dataMap[timeKey];

//       int hr = existing!.hr;
//       int? steps = existing?.steps;

//       if (p.type == HealthDataType.HEART_RATE) {
//         hr = _parseToInt(p.value)!;
//       } else if (p.type == HealthDataType.STEPS) {
//         steps = _parseToInt(p.value);
//       }

//       dataMap[timeKey] = HealthDayData(_mapCategory(hr), timeKey, hr, steps);
//     }

//     final dayDetails = dataMap.values.toList();
//     int panicCount =
//         dayDetails.where((d) => d.hr != null && d.hr! > _panicThreshold).length;
//     for (var d in dayDetails) {
//       if (d.hr != null && d.hr! > _panicThreshold) {
//         NotificationService().showNotification();
//       }
//     }

//     final dateString =
//         '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
//     return [HealthData(_uuid.v4(), dateString, panicCount, dayDetails)];
//   }

//   static String _mapCategory(int hr) {
//     // if (hr == null) return 'No HR';
//     if (hr > _panicThreshold) return 'panic';
//     if (hr < 60) return 'low';
//     return 'normal';
//   }

//   static int? _parseToInt(dynamic value) {
//     if (value == null) return null;
//     if (value is int) return value;
//     if (value is double) return value.round();
//     if (value is String) return int.tryParse(value);
//     return null;
//   }
// }
