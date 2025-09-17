import 'package:aura/model/health_data.dart';
import 'package:aura/model/health_day_data.dart';
import 'package:aura/services/notification_service.dart';
import 'package:aura/utils/storage_helper.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class HealthService {
  static final Health _health = Health();
  static const int _panicThreshold = 85;
  static const _uuid = Uuid();
  static const String _groupedKey = 'health_grouped_data';
  static const String _lastUpdatedKey = 'health_data_last_update';

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

  static Future<List<HealthDataPoint>> fetchHealthDataRaw(
    DateTime start,
    DateTime end,
  ) async {
    final types = [HealthDataType.HEART_RATE, HealthDataType.STEPS];
    await requestRuntimePermissions();
    await ensurePermissions();
    return await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: types,
    );
  }

  static Map<String, List<HealthDayData>> groupedHealthData(
    List<HealthDataPoint> raw,
  ) {
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
    return grouped;
  }

  static Future<Map<String, List<HealthDayData>>> getHealthData({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && await isCacheValid()) {
      final cached = await StorageHelper.loadGroupedData();
      if (cached != null) return cached;
    }

    final now = DateTime.now();

    //start time seharusnya dari data terakhir time yang tersimpan, bukan satu hari terakhir
    final start = now.subtract(const Duration(days: 7));
    final raw = await fetchHealthDataRaw(start, now);
    final grouped = groupedHealthData(raw);
    await StorageHelper.saveGroupedData(grouped);
    return grouped;
  }

  // static Future<Map<String, List<HealthDayData>>?> loadGroupedData() async {
  //   //load data dari lokal penyimpanan (di tangani di storage helper seharusnya)
  // }

  static Future<bool> isCacheValid() async {
    final lastUpdated = await StorageHelper.getLastUpdated();
    if (lastUpdated == null) return false;
    return DateTime.now().difference(lastUpdated) < const Duration(minutes: 30);
  }

  static Future<void> addManualLabel(
    String kategori, {
    int? hr,
    int? steps,
  }) async {
    final now = DateTime.now();
    final dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final grouped = await StorageHelper.loadGroupedData() ?? {};
    final newDetail = HealthDayData(
      kategori,
      now.toIso8601String(),
      hr ?? 0,
      steps ?? 0,
    );
    grouped.putIfAbsent(dateKey, () => []);
    grouped[dateKey]!.add(newDetail);
    await StorageHelper.saveGroupedData(grouped);
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

  //with data categorized per date
  // Helper: validasi HR dan Steps
//   bool _isValidHR(int? hr) => hr != null && hr > 30 && hr < 220;
//   bool _isValidSteps(int? steps) => steps != null && steps >= 0;

//   // Helper: parsing integer aman
//   int? _parseToInt(dynamic val) {
//     if (val == null) return null;
//     if (val is num) return val.toInt();
//     return int.tryParse(val.toString());
//   }

//   // Helper: buat kunci tanggal (YYYY-MM-DD)
//   String _dateKey(DateTime dt) =>
//       "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

//   static Future<List<HealthData>> fetchData(bool fromBackground) async {
//     final now = DateTime.now();

//     // 1. Ambil data lokal
//     final localData = await StorageHelper.loadFromLocal() ?? [];

//     print("=== DEBUG STEP 1: Local Data Sebelum Fetch ===");
//     print("LocalData Count: ${localData.length}");
//     for (var d in localData) {
//       print("  Local -> date: ${d.date}, details: ${d.details.length}");
//       for (var detail in d.details) {
//         print(
//           "     ⏰ ${detail.time}, HR: ${detail.hr}, Steps: ${detail.steps}",
//         );
//       }
//     }

//     // 2. Tentukan start time (ambil 30 menit sebelum data terakhir)
//     DateTime start;
//     if (localData.isNotEmpty) {
//       final latestDetail = localData.first.details.isNotEmpty
//           ? DateTime.parse(localData.first.details.last.time)
//           : DateTime.parse(localData.first.date);
//       start = latestDetail.isBefore(now)
//           ? latestDetail.subtract(const Duration(minutes: 30))
//           : now.subtract(const Duration(minutes: 30));
//     } else {
//       start = now.subtract(
//         const Duration(days: 1),
//       ); // pertama kali ambil 1 hari
//     }
//     print("=== DEBUG STEP 2: Fetch Range ===");
//     print("Start: $start, End: $now");

//     // 3. Permissions
//     if (!fromBackground) {
//       await requestRuntimePermissions();
//       await ensurePermissions();
//     }

//     // 4. Ambil raw data
//     final types = [HealthDataType.HEART_RATE, HealthDataType.STEPS];
//     final raw = await _health.getHealthDataFromTypes(
//       startTime: start.toUtc(),
//       endTime: now.toUtc(),
//       types: types,
//     );

//     print("=== DEBUG STEP 3: Raw Data dari Google Health ===");
//     print("Raw Count: ${raw.length}");
//     for (var r in raw) {
//       print(
//         "  Raw -> type: ${r.type}, from: ${r.dateFrom}, to: ${r.dateTo}, value: ${r.value}",
//       );
//     }

//     // 5. Group data per tanggal (dengan filter duplikat & validasi)
//     final grouped = <String, List<HealthDayData>>{};
//     for (var p in raw) {
//       final dateKey = HealthService()._dateKey(p.dateFrom);
//       int? hr;
//       int? steps;
//       String kategori = '';

//       if (p.type == HealthDataType.HEART_RATE) {
//         hr = HealthService()._parseToInt(p.value);
//         if (!HealthService()._isValidHR(hr)) continue;
//         kategori = _mapCategory(hr);
//       }
//       if (p.type == HealthDataType.STEPS) {
//         steps = HealthService()._parseToInt(p.value);
//         if (!HealthService()._isValidSteps(steps)) continue;
//       }

//       grouped.putIfAbsent(dateKey, () => []);

//       // Cek duplikat time sebelum masuk
//       final timeStr = p.dateFrom.toLocal().toIso8601String();
//       final exists = grouped[dateKey]!.any((d) => d.time == timeStr);
//       if (!exists) {
//         grouped[dateKey]!.add(HealthDayData(kategori, timeStr, hr, steps));
//       } else {
//         print("DEBUG: Duplikat diabaikan untuk $timeStr");
//       }
//     }

//     print("=== DEBUG STEP 4: Grouped Data ===");
//     for (var entry in grouped.entries) {
//       print("DateKey: ${entry.key}, Count: ${entry.value.length}");
//       for (var d in entry.value) {
//         print("   ⏰ ${d.time}, HR: ${d.hr}, Steps: ${d.steps}");
//       }
//     }
//     // 6. Ubah grouped jadi List<HealthData>
//     final fetchedList = grouped.entries.map((entry) {
//       final panicCount = entry.value
//           .where((d) => d.hr != null && d.hr! > _panicThreshold)
//           .length;
//       return HealthData(_uuid.v4(), entry.key, panicCount, entry.value);
//     }).toList();

//     print("=== DEBUG STEP 5: FetchedList (Siap Merge) ===");
//     for (var f in fetchedList) {
//       print(
//         "Fetched -> date: ${f.date}, panicCount: ${f.panicCount}, details: ${f.details.length}",
//       );
//     }

//     // 7. Merge dengan data lokal
//     final mergedMap = {for (var d in localData) d.date: d};

//     for (var fetched in fetchedList) {
//       if (!mergedMap.containsKey(fetched.date)) {
//         // Data baru → langsung masuk
//         mergedMap[fetched.date] = fetched;
//         print("DEBUG: Data baru ditambahkan untuk ${fetched.date}");

//         if (fetched.panicCount > 0) {
//           _notifyPanic(fetched.date, fetched.panicCount, fetched.details);
//         }
//       } else {
//         // Data lama → merge detail baru saja
//         final existing = mergedMap[fetched.date]!;
//         final existingTimes = existing.details.map((d) => d.time).toSet();

//         final newDetails = fetched.details
//             .where((d) => !existingTimes.contains(d.time))
//             .toList();

//         if (newDetails.isNotEmpty) {
//           var mergedDetails = [...existing.details, ...newDetails];

//           final uniqueMap = {for (var d in mergedDetails) d.time: d};

//           mergedDetails = uniqueMap.values.toList()
//             ..sort((a, b) => a.time.compareTo(b.time));

//           final newPanicCount = newDetails
//               .where((d) => d.hr != null && d.hr! > _panicThreshold)
//               .length;

//           if (newPanicCount > 0) {
//             _notifyPanic(fetched.date, newPanicCount, newDetails);
//           }

//           mergedMap[fetched.date] = HealthData(
//             existing.id,
//             fetched.date,
//             mergedDetails
//                 .where((d) => d.hr != null && d.hr! > _panicThreshold)
//                 .length,
//             mergedDetails,
//           );
//         }
//       }
//     }

//     // 8. Urutkan hasil akhir
//     final mergedList = mergedMap.values.toList()
//       ..sort((a, b) => b.date.compareTo(a.date));

//     print("=== DEBUG STEP 6: Final MergedList ===");
//     for (var m in mergedList) {
//       print(
//         "Final -> date: ${m.date}, panic: ${m.panicCount}, details: ${m.details.length}",
//       );
//       for (var d in m.details) {
//         print("   ⏰ ${d.time}, HR: ${d.hr}, Steps: ${d.steps}");
//       }
//     }

//     // 9. Simpan ke local storage
//     await StorageHelper.saveData(mergedList);

//     return mergedList;
//   }

//   // ===============================
//   // Helper untuk notifikasi
//   // ===============================
//   static void _notifyPanic(
//     String date,
//     int count,
//     List<HealthDayData> details,
//   ) {
//     print("🔥 Panic terdeteksi pada $date, jumlah: $count");
//     for (var d in details.where(
//       (d) => d.hr != null && d.hr! > _panicThreshold,
//     )) {
//       print("   ⏰ Jam: ${d.time}, HR: ${d.hr}");
//     }
//     NotificationService().showNotification(
//       title: "Deteksi Panic",
//       body: "Ada $count panic baru pada $date",
//     );
//   }

//   static String _mapCategory(int? hr) {
//     if (hr == null) return 'No HR';
//     if (hr > _panicThreshold) return 'panic';
//     if (hr < 60) return 'low';
//     return 'normal';
//   }
// }
