// services/workmanager_service.dart
import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firestore_service.dart';
import 'package:aura_bluetooth/models/heart_rate_model.dart';
import 'package:aura_bluetooth/models/hrv_metric.dart';
import 'package:aura_bluetooth/models/spatio.model.dart';

class WorkmanagerService {
  static final WorkmanagerService _instance = WorkmanagerService._internal();
  factory WorkmanagerService() => _instance;
  
  final FirestoreService _firestoreService = FirestoreService();
  
  static const String healthDataSyncTask = 'health_data_sync';
  static const String panicDataSyncTask = 'panic_data_sync';
  static const String cleanupTask = 'cleanup_task';

  WorkmanagerService._internal();

  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Set to false in production
    );
    
    // Register periodic tasks
    await _registerPeriodicTasks();
    
    print('[Workmanager] Initialized successfully');
  }

  Future<void> _registerPeriodicTasks() async {
    // Sync health data every 15 minutes
    await Workmanager().registerPeriodicTask(
      healthDataSyncTask,
      healthDataSyncTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(networkType: NetworkType.connected),
    );

    // Sync panic data every 30 minutes
    await Workmanager().registerPeriodicTask(
      panicDataSyncTask,
      panicDataSyncTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(networkType: NetworkType.connected),
    );

    // Cleanup old data daily
    await Workmanager().registerPeriodicTask(
      cleanupTask,
      cleanupTask,
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(hours: 1),
    );
  }

  Future<void> triggerImmediateSync() async {
    await Workmanager().registerOneOffTask(
      'immediate_sync',
      healthDataSyncTask,
      initialDelay: Duration.zero,
    );
  }

  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    print('[Workmanager] All tasks cancelled');
  }
}

// === WORKMANAGER CALLBACK DISPATCHER ===
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('[Workmanager] Task started: $task at ${DateTime.now()}');
    
    try {
      switch (task) {
        case WorkmanagerService.healthDataSyncTask:
          return await _handleHealthDataSync();
        case WorkmanagerService.panicDataSyncTask:
          return await _handlePanicDataSync();
        case WorkmanagerService.cleanupTask:
          return await _handleCleanupTask();
        default:
          print('[Workmanager] Unknown task: $task');
          return false;
      }
    } catch (e, st) {
      print('[Workmanager ERROR] $e');
      print('[Workmanager STACKTRACE] $st');
      return false;
    }
  });
}

Future<bool> _handleHealthDataSync() async {
  try {
    print('[Workmanager] Starting health data sync...');
    
    // Initialize Hive in background
    await Hive.initFlutter();
    final box = await Hive.openBox('sync_queue');
    
    final keys = box.keys.toList();
    print('[Workmanager] Found ${keys.length} items to sync');
    
    if (keys.isEmpty) {
      await Hive.close();
      return true;
    }
    
    final firestoreService = FirestoreService();
    int successCount = 0;
    
    for (final key in keys) {
      try {
        final data = box.get(key);
        if (data != null && data['type'] == 'heart_rate') {
          final hrData = _convertMapToHeartRateData(data);
          if (hrData != null) {
            await firestoreService.syncHeartRateData(hrData);
            await box.delete(key);
            successCount++;
          }
        }
      } catch (e) {
        print('[Workmanager] Error syncing item $key: $e');
      }
    }
    
    await Hive.close();
    print('[Workmanager] Sync completed: $successCount/$keys.length items synced');
    return true;
    
  } catch (e) {
    print('[Workmanager ERROR] Health data sync failed: $e');
    await Hive.close();
    return false;
  }
}

Future<bool> _handlePanicDataSync() async {
  try {
    print('[Workmanager] Starting panic data sync...');
    
    await Hive.initFlutter();
    final box = await Hive.openBox('panic_events');
    
    final keys = box.keys.toList();
    print('[Workmanager] Found ${keys.length} panic events to sync');
    
    if (keys.isEmpty) {
      await Hive.close();
      return true;
    }
    
    final firestoreService = FirestoreService();
    final batchData = <Map<String, dynamic>>[];
    
    for (final key in keys) {
      try {
        final event = box.get(key);
        if (event != null) {
          batchData.add(Map<String, dynamic>.from(event));
          await box.delete(key);
        }
      } catch (e) {
        print('[Workmanager] Error processing panic event $key: $e');
      }
    }
    
    // Sync all panic events in batch
    if (batchData.isNotEmpty) {
      await _syncPanicEventsBatch(batchData, firestoreService);
    }
    
    await Hive.close();
    print('[Workmanager] Panic data sync completed');
    return true;
    
  } catch (e) {
    print('[Workmanager ERROR] Panic data sync failed: $e');
    await Hive.close();
    return false;
  }
}

Future<void> _syncPanicEventsBatch(
  List<Map<String, dynamic>> events, 
  FirestoreService firestoreService,
) async {
  try {
    // You can implement batch sync to a separate panic_events collection
    for (final event in events) {
      // Add to Firestore under panic_events collection
      // This is just an example - adjust based on your Firestore structure
      print('[Workmanager] Would sync panic event: $event');
    }
  } catch (e) {
    print('[Workmanager] Error in batch panic sync: $e');
  }
}

Future<bool> _handleCleanupTask() async {
  try {
    print('[Workmanager] Starting cleanup task...');
    
    await Hive.initFlutter();
    final hrBox = await Hive.openBox('hr_box');
    final syncBox = await Hive.openBox('sync_queue');
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - (24 * 60 * 60 * 1000); // 24 hours ago
    
    // Clean up old HR data
    final hrKeys = hrBox.keys.toList();
    int hrCleaned = 0;
    for (final key in hrKeys) {
      try {
        final data = hrBox.get(key);
        if (data != null && data['timestamp'] < cutoff) {
          await hrBox.delete(key);
          hrCleaned++;
        }
      } catch (e) {
        print('[Workmanager] Error cleaning HR data $key: $e');
      }
    }
    
    // Clean up old sync queue items (older than 1 hour)
    final syncCutoff = now - (60 * 60 * 1000);
    final syncKeys = syncBox.keys.toList();
    int syncCleaned = 0;
    for (final key in syncKeys) {
      try {
        final data = syncBox.get(key);
        if (data != null && data['timestamp'] < syncCutoff) {
          await syncBox.delete(key);
          syncCleaned++;
        }
      } catch (e) {
        print('[Workmanager] Error cleaning sync data $key: $e');
      }
    }
    
    await Hive.close();
    print('[Workmanager] Cleanup completed: $hrCleaned HR items, $syncCleaned sync items removed');
    return true;
    
  } catch (e) {
    print('[Workmanager ERROR] Cleanup failed: $e');
    await Hive.close();
    return false;
  }
}

HeartRateData? _convertMapToHeartRateData(Map<dynamic, dynamic> data) {
  try {
    return HeartRateData(
      data['bpm'] as int,
      DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
      (data['rrIntervals'] as List?)?.cast<double>(),
      data['hrv10s'] != null ? HRVMetrics.fromJson(Map<String, dynamic>.from(data['hrv10s'])) : null,
      data['hrv30s'] != null ? HRVMetrics.fromJson(Map<String, dynamic>.from(data['hrv30s'])) : null,
      data['hrv60s'] != null ? HRVMetrics.fromJson(Map<String, dynamic>.from(data['hrv60s'])) : null,
      (data['rhr'] as num).toDouble(),
      SpatioTemporal.fromJson(Map<String, dynamic>.from(data['phoneSensor'])),
    );
  } catch (e) {
    print('[Workmanager] Error converting data: $e');
    return null;
  }
}