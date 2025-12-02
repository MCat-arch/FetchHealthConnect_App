import 'package:aura_bluetooth/models/heart_rate_model.dart';
import 'package:aura_bluetooth/models/hrv_metric.dart';
import 'package:aura_bluetooth/models/spatio.model.dart';
import 'package:aura_bluetooth/services/firestore_service.dart';
import 'package:aura_bluetooth/services/ml_panic_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _dataBoxName = 'hr_box';
  static const String _syncQueueBoxName = 'sync_queue';
  static const String _settingsBoxName = 'app_settings';
  static const String _feedbackQueueBoxName = 'feedback queue';

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isBoxOpen(_dataBoxName)) await Hive.openBox(_dataBoxName);
    if (!Hive.isBoxOpen(_syncQueueBoxName))
      await Hive.openBox(_syncQueueBoxName);
    if (!Hive.isBoxOpen(_settingsBoxName)) await Hive.openBox(_settingsBoxName);
    if (!Hive.isBoxOpen(_feedbackQueueBoxName))
      await Hive.openBox(_feedbackQueueBoxName);
  }

  Future<void> savePermissionStatus(bool isGranted) async {
    final box = Hive.box(_settingsBoxName);
    await box.put('all_permissions_granted', isGranted);
    print('Permission status saved to storage: $isGranted');
  }

  bool getStoredPermissionStatus() {
    if (!Hive.isBoxOpen(_settingsBoxName)) return false;
    final box = Hive.box(_settingsBoxName);
    return box.get('all_permissions_grated', defaultValue: false);
  }

  Future<void> saveHeartRateData(HeartRateData data) async {
    final dataMap = data.toJson();
    final key = data.timestamp.millisecondsSinceEpoch.toString();

    final historyBox = Hive.box(_dataBoxName);
    await historyBox.put(key, dataMap);

    final syncBox = Hive.box(_syncQueueBoxName);
    await syncBox.put(key, dataMap);
  }

  List<HeartRateData> getUnsyncedData() {
    final syncBox = Hive.box(_syncQueueBoxName);
    List<HeartRateData> pendingData = [];

    for (var key in syncBox.keys) {
      final data = syncBox.get(key);

      if (data != null) {
        try {
          final mapData = Map<String, dynamic>.from(data as Map);
          final hrData = HeartRateData.fromJson(mapData);
          pendingData.add(hrData);
        } catch (e) {
          print("❌ Error parsing cached data: $e");
        }
      }
    }
    return pendingData;
  }

  Future<void> clearSyncedData(List<String> keys) async {
    final syncBox = Hive.box(_syncQueueBoxName);
    await syncBox.deleteAll(keys);
  }

  Box get syncBox => Hive.box(_syncQueueBoxName);

  Future<void> savePendingFeedback(String isoTimestamp, String status) async {
    final feedbackBox = Hive.box(_feedbackQueueBoxName);

    feedbackBox.put(isoTimestamp, status);
    print("💾 Feedback saved locally for later sync: $status");
  }

  Future<void> clearSyncedFeedback(List<dynamic> keys) async {
    final feedbackBox = Hive.box(_feedbackQueueBoxName);
    await feedbackBox.deleteAll(keys);
  }

  Map<dynamic, dynamic> getPendingFeedbacks() {
    final feedbackBox = Hive.box(_feedbackQueueBoxName);
    return feedbackBox.toMap();
  }
}

// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:aura_bluetooth/models/heart_rate_model.dart';
// import 'package:aura_bluetooth/services/firestore_service.dart';

// class StorageService {
//   static final StorageService _instance = StorageService._internal();
//   factory StorageService() => _instance;
//   StorageService._internal();

//   static const String _dataBoxName = 'heart_rate_data';
//   static const String _syncQueueBoxName = 'sync_queue';
//   static const String _settingsBoxName = 'app_settings';

//   // Initialize Hive (Call this in main.dart)
//   Future<void> init() async {
//     await Hive.initFlutter();
//     await Hive.openBox(_dataBoxName); // For history display
//     await Hive.openBox(_syncQueueBoxName); // For background sync
//     await Hive.openBox(_settingsBoxName); // For permissions/settings
//   }

//   // --- 1. Manage Permissions & Settings ---

//   Future<void> savePermissionStatus(String permissionName, bool isGranted) async {
//     final box = Hive.box(_settingsBoxName);
//     await box.put('perm_$permissionName', isGranted);
//   }

//   bool getPermissionStatus(String permissionName) {
//     final box = Hive.box(_settingsBoxName);
//     return box.get('perm_$permissionName', defaultValue: false);
//   }

//   // --- 2. Manage Heart Rate Data ---

//   /// Saves data locally and adds to sync queue
//   Future<void> saveHeartRateData(HeartRateData data) async {
//     final dataMap = data.toJson();
//     final key = data.timestamp.millisecondsSinceEpoch.toString();

//     // 1. Save to History Box (for UI display)
//     final historyBox = Hive.box(_dataBoxName);
//     await historyBox.put(key, dataMap);

//     // 2. Save to Sync Queue (for Workmanager/Firestore)
//     // We save it separately so we can delete it easily after successful sync
//     final syncBox = Hive.box(_syncQueueBoxName);
//     await syncBox.put(key, dataMap);
//   }

//   /// Get all data waiting to be synced
//   List<HeartRateData> getUnsyncedData() {
//     final syncBox = Hive.box(_syncQueueBoxName);
//     List<HeartRateData> pendingData = [];

//     for (var key in syncBox.keys) {
//       final data = syncBox.get(key);
//       if (data != null) {

//          final jsonData = {
//         'bpm': data.bpm,
//         'timestamp': data.timestamp.millisecondsSinceEpoch,
//         'rrIntervals': data.rrIntervals,
//         'hrv10s': data.HRV10s?.toJson(),
//         'hrv30s': data.HRV30s?.toJson(),
//         'hrv60s': data.HRV60s?.toJson(),
//         'rhr': data.rhr,
//         'phoneSensor': data.phoneSensor.toJson(),
//         'prediction': data.prediction.toJson(),
//         'device_id': 'armband_device', // bisa diganti dengan actual device ID
//         'user_id': 'current_user_id', // perlu diintegrasikan dengan auth
//       };
//         // Convert Map back to Object (Simplified logic here)
//         // In reality, you might just pass the Map to FirestoreService

//         pendingData.add(HeartRateData.fromJson(data)); 
//       }
//     }
//     return pendingData;
//   }

//   /// Remove items from sync queue after successful upload
//   Future<void> clearSyncedData(List<String> keys) async {
//     final syncBox = Hive.box(_syncQueueBoxName);
//     await syncBox.deleteAll(keys);
//   }
  
//   // Helper to access boxes directly if needed
//   Box get syncBox => Hive.box(_syncQueueBoxName);
// }