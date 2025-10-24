// TODO :: DIVIDE INTO 3 CLASS
// NEXT INTEGRATE WITH HUAWEI API

// import 'package:aura/model/health_data.dart';
// import 'package:aura/model/health_day_data.dart';
// import 'package:aura/services/notification_service.dart';
// import 'package:aura/utils/storage_helper.dart';
// import 'package:health/health.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:uuid/uuid.dart';

// class HealthService {
//   static final Health _health = Health();
//   static const int _panicThreshold = 85;
//   static const index = Uuid();

//   /// ✅ Minta permission runtime
//   static Future<void> requestRuntimePermissions() async {
//     final activityGranted = await Permission.activityRecognition.request();
//     final sensorGranted = await Permission.sensors.request();

//     final allGranted = activityGranted.isGranted && sensorGranted.isGranted;
//     await StorageHelper.permissionGranted(allGranted);
//   }

//   /// ✅ Pastikan permission sudah granted
//   static Future<void> ensurePermissions() async {
//     final fromStorage = await StorageHelper.isPermissionGranted();
//     if (!fromStorage) {
//       throw Exception('Health permissions not granted (saved status)');
//     }

//     final types = [HealthDataType.HEART_RATE, HealthDataType.STEPS];
//     final has = await _health.hasPermissions(types);
//     if (has != true) {
//       throw Exception('Health permissions not granted (recheck)');
//     }
//   }

//   /// ✅ Fetch raw data dari Health API
//   static Future<List<HealthDataPoint>> fetchHealthDataRaw(
//     DateTime start,
//     DateTime end,
//   ) async {
//     await ensurePermissions();
//     final types = [HealthDataType.HEART_RATE, HealthDataType.STEPS];
//     return await _health.getHealthDataFromTypes(
//       startTime: start,
//       endTime: end,
//       types: types,
//     );
//   }

//   /// ✅ Proses raw data jadi HealthData + HealthDayData
//   static Map<String, HealthData> groupedHealthData(List<HealthDataPoint> raw) {
//     final Map<String, HealthData> grouped = {};

//     for (var p in raw) {
//       final dateKey =
//           "${p.dateFrom.year}-${p.dateFrom.month.toString().padLeft(2, '0')}-${p.dateFrom.day.toString().padLeft(2, '0')}";

//       int? hr;
//       int? steps;
//       String kategori = '';

//       if (p.type == HealthDataType.HEART_RATE) {
//         hr = _parseToInt(p.value);
//         kategori = _mapCategory(hr);
//       }
//       if (p.type == HealthDataType.STEPS) {
//         steps = _parseToInt(p.value);
//       }

//       grouped.putIfAbsent(dateKey, () {
//         return HealthData(id: dateKey, date: dateKey, details: []);
//       });

//       grouped[dateKey]!.details.add(
//         HealthDayData(
//           kategori,
//           p.dateFrom.toLocal().toIso8601String(),
//           hr,
//           steps,
//         ),
//       );
//     }

//     return grouped;
//   }

//   //initial fetch
//   static Future<void> intitalFetch() async {
//     final now = DateTime.now();
//     final start = now.subtract(const Duration(days: 1));
//     final raw = await fetchHealthDataRaw(start, now);
//     final grouped = groupedHealthData(raw);

//     for (final entry in grouped.entries) {
//       final date = entry.key;
//       final details = entry.value.details;

//       final existingID = await StorageHelper.getDetailIdsForDate(date);

//       final newDetails = details
//           .where((d) => !existingID.contains(d.time))
//           .toList();

//       if (newDetails.isEmpty) continue;

//       await StorageHelper.addHealthDayDataBatch(date, newDetails);

//       final newPanicCount = newDetails
//           .where((d) => d.kategori == 'panic')
//           .length;
//       if (newPanicCount > 0) {
//         await StorageHelper.incrementPanicCount(date, newPanicCount);
//         // opsi: notifikasi bisa dikirim juga untuk initialFetch, atau skip to avoid spam
//         // await NotificationService.showNotification(title: "...", body: "...");
//       }

//       // Simpan/update daily meta (merge)
//       await StorageHelper.saveHealthData(
//         HealthData(
//           id: date,
//           date: date,
//           panicCount: 0, // actual count di Firestore via increment
//           details: [], // details stored in subcollection
//         ),
//       );

//       await StorageHelper.saveLastFetchTime(now);
//     }
//   }

//   /// ✅ Jalankan background fetch setiap 15–30 menit
//   static Future<void> backgroundFetch() async {
//     final now = DateTime.now();
//     final lastFetch = await StorageHelper.getLastFetchTime();
//     final start = lastFetch ?? DateTime.now().subtract(const Duration(minutes: 30));

//     final raw = await fetchHealthDataRaw(start, now);
//     final grouped = groupedHealthData(raw);

//     final List<HealthDayData> newPanics = [];

//     for (final entry in grouped.entries) {
//       final date = entry.key;
//       final details = entry.value.details;

//       final existingIds = await StorageHelper.getDetailIdsForDate(date);
//       final newDetails = details
//           .where((d) => !existingIds.contains(d.time))
//           .toList();
//       if (newDetails.isEmpty) continue;

//       // batch insert newDetail
//       await StorageHelper.addHealthDayDataBatch(date, newDetails);

//       // hitung panic baru dan increment panicCount
//       final newPanicCount = newDetails
//           .where((d) => d.kategori == 'panic')
//           .length;
//       if (newPanicCount > 0) {
//         await StorageHelper.incrementPanicCount(date, newPanicCount);
//         newPanics.addAll(newDetails.where((d) => d.kategori == 'panic'));
//       }

//       // update daily meta (merge)
//       await StorageHelper.saveHealthData(
//         HealthData(id: date, date: date, panicCount: 0, details: []),
//       );
//     }

//     // Kirim notifikasi ringkasan untuk panic baru — hanya jika ada panic baru
//     if (newPanics.isNotEmpty) {
//       // kita kirim single notification summarizing times
//       final times = newPanics.map((p) => p.time.substring(11, 19)).join(', ');
//       await NotificationService().showNotification(
//         title: "⚠️ Panic Detected",
//         body: "${newPanics.length} event(s) at $times",
//       );
//     }
//   }

//   /// ✅ Tambah label manual
//   static Future<void> addManualLabel(
//     String kategori, {
//     int? hr,
//     int? steps,
//   }) async {
//     final now = DateTime.now();
//     final dateKey =
//         "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

//     final detail = HealthDayData(kategori, now.toIso8601String(), hr, steps);

//     await StorageHelper.addHealthDayData(dateKey, detail);
//   }

//   /// ✅ Map kategori berdasarkan HR
//   static String _mapCategory(int? hr) {
//     if (hr == null) return 'No HR';
//     if (hr > _panicThreshold) return 'panic';
//     if (hr < 60) return 'low';
//     return 'normal';
//   }

//   /// ✅ Helper konversi value ke int
//   static int? _parseToInt(dynamic value) {
//     if (value == null) return null;
//     if (value is int) return value;
//     if (value is double) return value.round();
//     if (value is String) return int.tryParse(value);

//     // NumericHealthValue fallback
//     if (value.runtimeType.toString() == 'NumericHealthValue') {
//       try {
//         final numVal = value.numericValue;
//         if (numVal is int) return numVal;
//         if (numVal is double) return numVal.round();
//       } catch (_) {}
//     }
//     return null;
//   }
// }

//WITH HUAWEI INTEGRATION

// import 'dart:developer';
// import 'package:aura/model/health_data.dart';
// import 'package:aura/model/health_day_data.dart';
// import 'package:aura/model/category_model.dart';
// import 'package:aura/services/notification_service.dart';
// import 'package:aura/utils/storage_helper.dart';
// import 'package:huawei_health/huawei_health.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:uuid/uuid.dart';

// class HealthService {
//   static final _uuid = const Uuid();
//   static bool _isAuthorized = false;
//   static const int _panicThreshold = 85;
//   late DataCollector _dataCollector;

//   /// ✅ Request runtime permissions
//   static Future<void> requestRuntimePermissions() async {
//     final activityGranted = await Permission.activityRecognition.request();
//     final sensorGranted = await Permission.sensors.request();
//     final allGranted = activityGranted.isGranted && sensorGranted.isGranted;
//     await StorageHelper.permissionGranted(allGranted);
//   }

//   /// Initializes a DataController instance with a list of HiHealtOptions.
//   void initDataController() async {
//     log('init', _dataTextController, LogOptions.call);
//     try {
//       _dataController = await DataController.init();
//       log('init', _dataTextController, LogOptions.success);
//     } on PlatformException catch (e) {
//       log('init', _dataTextController, LogOptions.error, error: e.message);
//     }
//   }

//   /// ✅ Huawei Health authorization
//   static Future<void> _ensureHuaweiPermissions() async {
//     final List<Scope> scopes = <Scope>[
//       Scope.HEALTHKIT_ACTIVITY_READ,
//       Scope.HEALTHKIT_BLOODPRESSURE_READ,
//       Scope.HEALTHKIT_DISTANCE_READ,
//       Scope.HEALTHKIT_HEARTHEALTH_READ,
//       Scope.HEALTHKIT_HEARTRATE_READ,
//       Scope.HEALTHKIT_BODYTEMPERATURE_READ,
//       Scope.HEALTHKIT_STRESS_READ,
//       Scope.HEALTHKIT_SLEEP_READ,
//       Scope.HEALTHKIT_OXYGENSTATURATION_READ,
//       Scope.HEALTHKIT_HISTORYDATA_OPEN_WEEK,
//     ];

//     try {
//       final result = await HealthAuth.signIn(scopes);
//       log("✅ Huawei Health Authorized for ${result?.displayName}");
//       _isAuthorized = true;
//       await StorageHelper.getaAcessToken(result?.accessToken ?? '');
//     } catch (e) {
//       log('❌ Huawei Auth Error: $e');
//       rethrow;
//     }
//   }

//   /// ✅ Fetch data from Huawei Health (SamplePoints)
//   static Future<List<SamplePoint>> _fetchHuaweiSamples(
//     DateTime start,
//     DateTime end,
//   ) async {
//     if (!_isAuthorized) await _ensureHuaweiPermissions();

//     final types = [
//       DataType.DT_CONTINUOUS_STEPS_DELTA,
//       DataType.DT_INSTANTANEOUS_HEART_RATE,
//       DataType.DT_INSTANTANEOUS_STRESS,
//       DataType.DT_INSTANTANEOUS_BODY_TEMPERATURE,
//       DataType.DT_CONTINUOUS_CALORIES_BURNT,
//       DataType.DT_INSTANTANEOUS_SPO2,
//       DataType.DT_INSTANTANEOUS_BLOOD_PRESSURE,
//       DataType.DT_CONTINUOUS_DISTANCE_DELTA,
//       DataType.DT_CONTINUOUS_ACTIVE_TIME,
//       DataType.DT_CONTINUOUS_EXERCISE_INTENSITY,
//       // DataType.DT_SLEEP_STAGE,
//     ];

//     final List<SamplePoint> points = [];
//     for (final type in types) {
//       try {
//         ReadReply? readReply = await _dataCollector.read(
//           ReadOptions(dataTypes: type, startTime: start, endTime: end),
//         );
//         if (result.samplePoints.isNotEmpty) {
//           points.addAll(result.samplePoints);
//         }
//       } catch (e) {
//         log('⚠️ Fetch failed for $type: $e');
//       }
//     }

//     return points;
//   }

//   /// ✅ Convert Huawei SamplePoints → HealthData structure
//   static Map<String, HealthData> groupedHealthData(List<SamplePoint> samples) {
//     final Map<String, HealthData> grouped = {};

//     for (final s in samples) {
//       final dateKey = _formatDate(
//         DateTime.fromMillisecondsSinceEpoch(s.startTime),
//       );
//       final kategori = _defineCategory(s.dataType);

//       final exercise = ExerciseData();
//       final panic = PanicVariableData();

//       // classify and map values
//       switch (s.dataType) {
//         case DataType.DT_CONTINUOUS_STEPS_DELTA:
//           exercise.dailyActivitySummary = _parseToDouble(s.fields.first.value);
//           break;
//         case DataType.DT_CONTINUOUS_DISTANCE_DELTA:
//           exercise.distance = _parseToDouble(s.fields.first.value);
//           break;
//         case DataType.DT_INSTANTANEOUS_HEART_RATE:
//           panic.heartRate = _parseToInt(s.fields.first.value);
//           break;
//         case DataType.DT_INSTANTANEOUS_STRESS:
//           panic.stress = _parseToDouble(s.fields.first.value);
//           break;
//         // case DataType.DT_INSTANTANEOUS_SPO2:
//         //   panic.spo2 = _parseToDouble(s.fields.first.value);
//         //   break;
//         // case DataType.DT_INSTANTANEOUS_BODY_TEMPERATURE:
//         //   panic.bodyTemperature = _parseToDouble(s.fields.first.value);
//         //   break;
//         // case DataType.DT_INSTANTANEOUS_BLOOD_PRESSURE:
//         //   panic.systolicBP = _parseToInt(s.fields[0].value);
//         //   panic.diastolicBP = _parseToInt(s.fields[1].value);
//         //   break;
//         default:
//           break;
//       }

//       final healthDay = HealthDayData(
//         kategori,
//         DateTime.fromMillisecondsSinceEpoch(s.startTime).toIso8601String(),
//         exercise,
//         panic,
//       );

//       grouped.putIfAbsent(
//         dateKey,
//         () => HealthData(id: dateKey, date: dateKey, details: []),
//       );
//       grouped[dateKey]!.details.add(healthDay);
//     }

//     return grouped;
//   }

//   /// ✅ Initial fetch for past 1 day
//   static Future<void> initialFetch() async {
//     final now = DateTime.now();
//     final start = now.subtract(const Duration(days: 1));
//     final samples = await _fetchHuaweiSamples(start, now);
//     final grouped = groupedHealthData(samples);

//     for (final entry in grouped.entries) {
//       final date = entry.key;
//       final newDetails = entry.value.details;

//       final existingIds = await StorageHelper.getDetailIdsForDate(date);
//       final uniqueDetails = newDetails
//           .where((d) => !existingIds.contains(d.time))
//           .toList();

//       if (uniqueDetails.isEmpty) continue;

//       await StorageHelper.addHealthDayDataBatch(date, uniqueDetails);

//       final panicCount = uniqueDetails
//           .where((d) => d.kategori == 'panic')
//           .length;
//       if (panicCount > 0) {
//         await StorageHelper.incrementPanicCount(date, panicCount);
//       }

//       await StorageHelper.saveHealthData(
//         HealthData(id: date, date: date, panicCount: panicCount, details: []),
//       );

//       await StorageHelper.saveLastFetchTime(now);
//     }
//   }

//   /// ✅ Background fetch since last record
//   static Future<void> backgroundFetch() async {
//     final now = DateTime.now();
//     final lastFetch = await StorageHelper.getLastFetchTime();
//     final start = lastFetch ?? now.subtract(const Duration(minutes: 30));

//     final samples = await _fetchHuaweiSamples(start, now);
//     final grouped = groupedHealthData(samples);
//     final List<HealthDayData> newPanics = [];

//     for (final entry in grouped.entries) {
//       final date = entry.key;
//       final newDetails = entry.value.details;

//       final existingIds = await StorageHelper.getDetailIdsForDate(date);
//       final uniqueDetails = newDetails
//           .where((d) => !existingIds.contains(d.time))
//           .toList();
//       if (uniqueDetails.isEmpty) continue;

//       await StorageHelper.addHealthDayDataBatch(date, uniqueDetails);

//       final panicCount = uniqueDetails
//           .where((d) => d.kategori == 'panic')
//           .length;
//       if (panicCount > 0) {
//         await StorageHelper.incrementPanicCount(date, panicCount);
//         newPanics.addAll(uniqueDetails.where((d) => d.kategori == 'panic'));
//       }

//       await StorageHelper.saveHealthData(
//         HealthData(id: date, date: date, panicCount: panicCount, details: []),
//       );
//     }

//     if (newPanics.isNotEmpty) {
//       final times = newPanics.map((p) => p.time.substring(11, 19)).join(', ');
//       await NotificationService().showNotification(
//         title: "⚠️ Panic Detected",
//         body: "${newPanics.length} event(s) at $times",
//       );
//     }
//   }

//   /// ✅ Manual labeling
//   static Future<void> addManualLabel(
//     String kategori, {
//     ExerciseData? exerciseData,
//     PanicVariableData? panicData,
//   }) async {
//     final now = DateTime.now();
//     final dateKey = _formatDate(now);

//     final detail = HealthDayData(
//       kategori,
//       now.toIso8601String(),
//       exerciseData ?? ExerciseData(),
//       panicData ?? PanicVariableData(),
//     );

//     await StorageHelper.addHealthDayData(dateKey, detail);
//   }

//   /// --- Helpers ---
//   static String _formatDate(DateTime dt) =>
//       "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

//   static String _defineCategory(DataType type) {
//     const panicTypes = [
//       DataType.DT_INSTANTANEOUS_HEART_RATE,
//       DataType.DT_INSTANTANEOUS_STRESS,

//       // DataType.DT_INSTANTANEOUS_BODY_TEMPERATURE,
//       // DataType.DT_INSTANTANEOUS_BLOOD_PRESSURE,
//       // DataType.DT_INSTANTANEOUS_SPO2,
//     ];
//     return panicTypes.contains(type) ? 'panic' : 'exercise';
//   }

//   static int? _parseToInt(dynamic value) {
//     if (value == null) return null;
//     if (value is int) return value;
//     if (value is double) return value.round();
//     return int.tryParse(value.toString());
//   }

//   static double? _parseToDouble(dynamic value) {
//     if (value == null) return null;
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     return double.tryParse(value.toString());
//   }
// }

import 'package:aura/model/category_model.dart';
import 'package:aura/model/health_data.dart';
import 'package:aura/model/health_day_data.dart';
import 'package:aura/services/health_data_fetcher.dart';
import 'package:aura/services/health_data_processor.dart';
import 'package:aura/services/notification_service.dart';
import 'package:aura/utils/storage_helper.dart';
import 'package:uuid/uuid.dart';

//using newest gpt generate
class HealthService {
  static final Uuid _uuid = const Uuid();

  /// Background fetch
  static Future<void> backgroundFetch() async {
    final now = DateTime.now();
    final lastFetch = await StorageHelper.getLastFetchTime();
    final start = lastFetch ?? now.subtract(const Duration(minutes: 30));

    final points = await HealthDataFetcher().fetchHuaweiSamples(start, now);
    if (points.isEmpty) return;

    final Map<String, List<HealthDayData>> grouped = {};

    for (final p in points) {
      final dateKey =
          "${p.startTime!.year}-${p.startTime!.month.toString().padLeft(2, '0')}-${p.startTime!.day.toString().padLeft(2, '0')}";
      final mapped = HealthDataProcessor.mapSampleToDayData(p);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(mapped);
    }

    final List<HealthDayData> newPanics = [];

    for (final entry in grouped.entries) {
      final date = entry.key;
      final details = entry.value;

      final existingIds = await StorageHelper.getDetailIdsForDate(date);
      final newDetails = details
          .where((d) => !existingIds.contains(d.time))
          .toList();
      if (newDetails.isEmpty) continue;

      await StorageHelper.addHealthDayDataBatch(date, newDetails);

      final newPanicCount = newDetails
          .where((d) => d.kategori == 'panic')
          .length;
      if (newPanicCount > 0) {
        await StorageHelper.incrementPanicCount(date, newPanicCount);
        newPanics.addAll(newDetails.where((d) => d.kategori == 'panic'));
      }

      await StorageHelper.saveHealthData(
        HealthData(id: date, date: date, panicCount: 0, details: []),
      );
    }

    if (newPanics.isNotEmpty) {
      final times = newPanics.map((d) => d.time.substring(11, 19)).join(', ');
      await NotificationService().showNotification(
        title: "⚠️ Panic Detected",
        body: "${newPanics.length} event(s) at $times",
      );
    }

    await StorageHelper.saveLastFetchTime(now);
  }

  /// Manual label injection
  static Future<void> addManualLabel(String kategori) async {
    final now = DateTime.now();
    final dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final detail = HealthDayData(
      kategori,
      now.toIso8601String(),
      ExerciseData(),
      PanicVariableData(),
    );

    await StorageHelper.addHealthDayData(dateKey, detail);
  }

  static Future<void> initialFetch() async {
    print("📅 Fetching initial health data...");
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 24));
    final points = await HealthDataFetcher().fetchHuaweiSamples(start, now);
    if (points.isEmpty) {
      print("ℹ️ No health data found for the last 24 hours.");
      return;
    }
    print("✅ Retrieved ${points.length} health samples.");
    await HealthService.backgroundFetch(); // reuse existing logic
  }
}





/// 4️⃣ HealthService (Integration Layer)

// class HealthService {
//   static const int _panicThreshold = 85;
//   static final _uuid = const Uuid();
  

//   /// Background fetch: get new data since last fetch
//   Future<void> backgroundFetch() async {
//     final now = DateTime.now();
//     final lastFetch = await StorageHelper.getLastFetchTime();
//     final start = lastFetch ?? now.subtract(const Duration(minutes: 30));

//     final points = await HealthDataFetcher().fetchHuaweiSamplePoints(
//       start,
//       now,
//       type,
//     );

//     if (points.isEmpty) return;

//     final Map<String, List<HealthDayData>> grouped = {};

//     for (final p in points) {
//       final dateKey =
//           "${p.startTime!.year}-${p.startTime!.month.toString().padLeft(2, '0')}-${p.startTime!.day.toString().padLeft(2, '0')}";
//       final mapped = HealthDataProcessor.mapSampleToDayData(p);
//       grouped.putIfAbsent(dateKey, () => []);
//       grouped[dateKey]!.add(mapped);
//     }

//     final List<HealthDayData> newPanics = [];

//     for (final entry in grouped.entries) {
//       final date = entry.key;
//       final details = entry.value;
//       final existingIds = await StorageHelper.getDetailIdsForDate(date);
//       final newDetails = details
//           .where((d) => !existingIds.contains(d.time))
//           .toList();
//       if (newDetails.isEmpty) continue;

//       await StorageHelper.addHealthDayDataBatch(date, newDetails);

//       final newPanicCount = newDetails
//           .where((d) => d.kategori == 'panic')
//           .length;
//       if (newPanicCount > 0) {
//         await StorageHelper.incrementPanicCount(date, newPanicCount);
//         newPanics.addAll(newDetails.where((d) => d.kategori == 'panic'));
//       }

//       await StorageHelper.saveHealthData(
//         HealthData(id: date, date: date, panicCount: 0, details: []),
//       );
//     }

//     if (newPanics.isNotEmpty) {
//       final times = newPanics.map((p) => p.time.substring(11, 19)).join(', ');
//       await NotificationService().showNotification(
//         title: "⚠️ Panic Detected",
//         body: "${newPanics.length} event(s) at $times",
//       );
//     }

//     await StorageHelper.saveLastFetchTime(now);
//   }

//   /// Manual label injection
//   static Future<void> addManualLabel(String kategori) async {
//     final now = DateTime.now();
//     final dateKey =
//         "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

//     final detail = HealthDayData(
//        kategori,
//       now.toIso8601String(),
//       ExerciseData(),
//       PanicVariableData(),
//     );

//     await StorageHelper.addHealthDayData(dateKey, detail);
//   }
// }
