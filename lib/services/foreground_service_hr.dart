// services/foreground_service_hr.dart
import 'dart:async';
import 'dart:io';
import 'package:aura_bluetooth/firebase_options.dart';
import 'package:aura_bluetooth/models/heart_rate_model.dart';
import 'package:aura_bluetooth/models/hrv_metric.dart';
import 'package:aura_bluetooth/models/spatio.model.dart';
import 'package:aura_bluetooth/providers/ble_provider.dart';
import 'package:aura_bluetooth/services/firestore_service.dart';
import 'package:aura_bluetooth/services/hrv_service.dart';
import 'package:aura_bluetooth/services/ml_panic_service.dart';
import 'package:aura_bluetooth/services/rhr_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/ble_service.dart';
import '../services/phone_sensor_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ForegroundMonitorService {
  static final ForegroundMonitorService _instance =
      ForegroundMonitorService._internal();
  factory ForegroundMonitorService() => _instance;

  final PhoneSensorService _phoneSensorService = PhoneSensorService();
  final BLEService _bleService = BLEService();
  final FirestoreService _firestoreService = FirestoreService();
  final MLPanicService _mlService = MLPanicService();

  // Timer? _watchdogTimer;
  // Timer? _dataSyncTimer;
  // Timer? _panicCheckTimer;
  // StreamSubscription<HeartRateData>? _hrSubscription;
  // StreamSubscription<PanicPrediction>? _panicSubscription;

  bool _isRunning = false;
  int _dataPointsCollected = 0;

  ForegroundMonitorService._internal();

  // Initialize foreground task configuration
  Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'health_monitoring',
        channelName: 'Health Monitoring Service',
        channelDescription: 'Monitoring heart rate and sensors in background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // icon: const DrawableResourceAndroidIcon('mipmap/ic_launcher'),
        onlyAlertOnce: true,
        enableVibration: false,
        playSound: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000), // 30 seconds
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  // Request necessary permissions
  // Future<void> _requestPermissions() async {
  //   // Notification permission for Android 13+
  //   final NotificationPermission notificationPermission =
  //       await FlutterForegroundTask.checkNotificationPermission();
  //   if (notificationPermission != NotificationPermission.granted) {
  //     await FlutterForegroundTask.requestNotificationPermission();
  //   }

  //   if (Platform.isAndroid) {
  //     // Battery optimization permission
  //     if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
  //       await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  //     }

  //     // Exact alarm permission (optional, for precise timing)
  //     if (!await FlutterForegroundTask.canScheduleExactAlarms) {
  //       // Note: This will open settings page
  //       // await FlutterForegroundTask.openAlarmsAndRemindersSettings();
  //     }
  //   }
  // }

  Future<void> start() async {
    if (_isRunning) return;

    print('[ForegroundService] Starting foreground monitoring...');

    // final NotificationPermission notificationPermissionStatus =
    //     await FlutterForegroundTask.checkNotificationPermission();

    // if (notificationPermissionStatus != NotificationPermission.granted) {
    //   print('[ForegroundService] Requesting Notification Permission...');
    //   final newStatus =
    //       await FlutterForegroundTask.requestNotificationPermission();
    //   if (newStatus != NotificationPermission.granted) {
    //     print(
    //       '[ForegroundService] ❌ Gagal: Izin notifikasi ditolak user. Service tidak bisa jalan.',
    //     );
    //     return; // JANGAN LANJUT
    //   }
    // }

    print('[ForegroundService] Starting foreground monitoring...');
    try {
      init();
      // Initialize Hive
      // await _initializeHive();

      // Request permissions
      // await _requestPermissions();

      // Initialize foreground task

      // Start the foreground service
      // final result = await FlutterForegroundTask.startService(
      //   notificationTitle: 'AURA Health Monitor',
      //   notificationText: 'Monitoring heart rate and sensors...',
      //   notificationButtons: [
      //     const NotificationButton(id: 'panic_help', text: 'Get Help'),
      //     const NotificationButton(id: 'stop_service', text: 'Stop'),
      //   ],
      //   callback: startCallback,
      // );

      // 3. Start Service
      final result = await FlutterForegroundTask.startService(
        notificationTitle: 'AURA Health Monitor',
        notificationText: 'Monitoring active',
        callback: startCallback,
      );
      _isRunning = true;
      ServiceRequestResult? resultscan;

      if (_isRunning == true) {
        // Perhatikan .success enum
        _isRunning = true;

        print('[ForegroundService] ✅ Started successfully');
      } else {
        // Ini log yang Anda dapatkan sekarang
        print('[ForegroundService] ❌ Failed to start service: $result');
        print('[ForegroundService] 💡 Hint: Cek AndroidManifest.xml Anda!');
      }
    } catch (e) {
      print('[ForegroundService] Exception starting service: $e');
    }
    //   if (result == ServiceRequestSuccess) {
    //     // Start monitoring services
    //     // await _phoneSensorService.initialize();
    //     // await _bleService.startScan();
    //     // _setupDataListeners();
    //     // _startTimers();

    //     _isRunning = true;
    //     print('[ForegroundService] Started successfully');
    //   } else {
    //     print('[ForegroundService] Failed to start service: $result');
    //   }
    // } catch (e) {
    //   print('[ForegroundService] Error starting service: $e');
    // }
  }

  // Future<void> _initializeHive() async {
  //   await Hive.initFlutter();
  //   if (!Hive.isBoxOpen('hr_box')) {
  //     await Hive.openBox('hr_box');
  //   }
  //   if (!Hive.isBoxOpen('sync_queue')) {
  //     await Hive.openBox('sync_queue');
  //   }
  //   if (!Hive.isBoxOpen('panic_events')) {
  //     await Hive.openBox('panic_events');
  //   }
  // }

  Future<void> stop() async {
    if (!_isRunning) return;

    print('[ForegroundService] Stopping...');

    try {
      // // Cancel subscriptions
      // await _hrSubscription?.cancel();
      // await _panicSubscription?.cancel();

      // // Cancel timers
      // _watchdogTimer?.cancel();
      // _dataSyncTimer?.cancel();
      // _panicCheckTimer?.cancel();

      // Stop services
      await _bleService.disconnect();
      _phoneSensorService.stop();

      // Stop foreground task
      await FlutterForegroundTask.stopService();

      // Close Hive boxes
      await Hive.close();

      _isRunning = false;
      print('[ForegroundService] Stopped successfully');
    } catch (e) {
      print('[ForegroundService] Error stopping service: $e');
    }
  }

  bool get isRunning => _isRunning;
  int get dataPointsCollected => _dataPointsCollected;
}

// === FOREGROUND TASK HANDLER ===
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(HealthMonitoringTaskHandler());
}

class HealthMonitoringTaskHandler extends TaskHandler {
  int _monitoringCount = 0;
  Timer? _monitoringTimer;

  // STATE DAN INSTANCE YANG DIPERLUKAN UNTUK AGREGASI
  // final HRVService? _hrvService = HRVService();
  // final RHRService? _rhrService = RHRService();
  // final FirestoreService? _firestoreService = FirestoreService();
  // final MLPanicService? _mlService = MLPanicService();
  // final PhoneSensorService? _phoneSensorService = PhoneSensorService();
  // late final BLEService? _bleService;

  HRVService? _hrvService;
  RHRService? _rhrService;
  FirestoreService? _firestoreService;
  MLPanicService? _mlService;
  PhoneSensorService? _phoneSensorService;
  BLEService? _bleService;

  final List<double>? _accumulateRR = [];
  final List<HeartRateData>? _history = [];

  StreamSubscription? _bleSub;
  Timer? _aggregationTimer;

  // Timers untuk maintenance/watchdog
  Timer? _watchdogTimer;
  Timer? _dataSyncTimer;
  Timer? _panicCheckTimer;

  final StreamController<HeartRateData> _finalHrCtrl =
      StreamController<HeartRateData>.broadcast();

  // Debug counters
  int _totalDataPoints = 0;
  int _successfulAggregations = 0;
  int _failedAggregations = 0;
  int _panicDetections = 0;

  void _debugLog(String message, {String type = "INFO"}) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [BackgroundTask-$type] $message';

    print('🔵 $logMessage');

    // Send to main isolate for UI debugging if needed
    try {
      FlutterForegroundTask.sendDataToMain({
        'type': 'debug_log',
        'message': message,
        'timestamp': timestamp,
      });
    } catch (e) {
      print('❌ Failed to send debug log to main isolate: $e');
    }
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _debugLog('🚀 Health monitoring task STARTING at $timestamp');

    try {
      // Firestore butuh ini karena ini adalah Isolate baru
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // 3. BARU INISIALISASI SERVICE DISINI (Safe Zone)
      _hrvService = HRVService();
      _rhrService = RHRService();
      _firestoreService =
          FirestoreService(); // Sekarang aman karena Firebase sudah init
      _mlService = MLPanicService();
      _phoneSensorService = PhoneSensorService();
      _bleService = BLEService();

      _debugLog('🔥 Firebase initialized in background');
      _debugLog('📱 Initializing PhoneSensorService...');
      await _phoneSensorService!.initialize();
      _debugLog('✅ PhoneSensorService initialized successfully');

      _debugLog('✅ All Services instantiated');

      _debugLog('🔵 Creating BLEService instance...');
      _bleService = BLEService();
      _debugLog('✅ BLEService instance created');

      _debugLog('💾 Initializing Hive storage...');
      await Hive.initFlutter();

      if (!Hive.isBoxOpen('hr_box')) {
        await Hive.openBox('hr_box');
        _debugLog('✅ Hive hr_box opened');
      }
      if (!Hive.isBoxOpen('sync_queue')) {
        await Hive.openBox('sync_queue');
        _debugLog('✅ Hive sync_queue opened');
      }
      if (!Hive.isBoxOpen('panic_events')) {
        await Hive.openBox('panic_events');
        _debugLog('✅ Hive panic_events opened');
      }

      _debugLog('🎯 Starting BLE listening and maintenance timers...');
      _startListeningToBLE();
      _startMaintenanceTimers();

      _debugLog('🎉 Health monitoring task STARTED SUCCESSFULLY');
    } catch (e, stackTrace) {
      _debugLog('💥 CRITICAL ERROR during task startup: $e', type: 'ERROR');
      _debugLog('Stack trace: $stackTrace', type: 'ERROR');
      rethrow;
    }
  }

  void _startMaintenanceTimers() {
    _debugLog('⏰ Starting maintenance timers...');

    // Watchdog timer - ensure BLE connection
    _watchdogTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      _debugLog(
        '🔍 Watchdog check - BLE connected: ${_bleService!.isConnected}',
      );

      if (!_bleService!.isConnected) {
        _debugLog('⚠️ BLE disconnected, attempting restart...');
        try {
          await _bleService!.startScan();
          _debugLog('✅ BLE scan restarted by watchdog');
        } catch (e) {
          _debugLog('❌ Watchdog failed to restart BLE: $e', type: 'ERROR');
        }
      }
    });

    // Data sync timer - sync cached data to Firestore
    _dataSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      _debugLog('🔄 Starting scheduled data sync...');
      await _syncCachedData();
    });

    // Panic check timer - additional safety check
    _panicCheckTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      _debugLog('🧠 Starting periodic panic check...');
      await _performPeriodicPanicCheck();
    });

    _debugLog('✅ Maintenance timers started successfully');
  }

  Future<void> _cacheDataForSync(HeartRateData hrData) async {
    try {
      final box = await Hive.openBox('sync_queue');
      final key = 'hr_${hrData.timestamp.millisecondsSinceEpoch}';

      final data = {
        'bpm': hrData.bpm,
        'timestamp': hrData.timestamp.millisecondsSinceEpoch,
        'rrIntervals': hrData.rrIntervals,
        'hrv10s': hrData.HRV10s?.toJson(),
        'hrv30s': hrData.HRV30s?.toJson(),
        'hrv60s': hrData.HRV60s?.toJson(),
        'rhr': hrData.rhr,
        'phoneSensor': hrData.phoneSensor.toJson(),
        'type': 'heart_rate',
      };

      await box.put(key, data);
      _debugLog('💾 Data cached for sync: ${hrData.bpm} BPM');
    } catch (e) {
      _debugLog('❌ Error caching data: $e', type: 'ERROR');
    }
  }

  Future<void> _syncCachedData() async {
    try {
      final box = await Hive.openBox('sync_queue');
      final keys = box.keys.toList();

      _debugLog('📤 Found ${keys.length} cached items to sync');

      if (keys.isEmpty) {
        _debugLog('ℹ️ No cached data to sync');
        return;
      }

      int successCount = 0;
      int errorCount = 0;

      for (final key in keys) {
        try {
          final data = box.get(key);
          if (data != null && data['type'] == 'heart_rate') {
            final hrData = _convertToHeartRateData(data);
            if (hrData != null) {
              await _firestoreService!.syncHeartRateData(hrData);
              await box.delete(key);
              successCount++;
              _debugLog('✅ Synced item: ${hrData.bpm} BPM');
            }
          }
        } catch (e) {
          errorCount++;
          _debugLog('❌ Error syncing item $key: $e', type: 'ERROR');
        }
      }

      _debugLog(
        '📊 Sync completed: $successCount success, $errorCount errors, ${keys.length - successCount - errorCount} remaining',
      );
    } catch (e) {
      _debugLog('❌ Error in sync process: $e', type: 'ERROR');
    }
  }

  HeartRateData? _convertToHeartRateData(Map<dynamic, dynamic> data) {
    try {
      return HeartRateData(
        data['bpm'] as int,
        DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
        (data['rrIntervals'] as List?)?.cast<double>(),
        data['hrv10s'] != null
            ? HRVMetrics.fromJson(Map<String, dynamic>.from(data['hrv10s']))
            : null,
        data['hrv30s'] != null
            ? HRVMetrics.fromJson(Map<String, dynamic>.from(data['hrv30s']))
            : null,
        data['hrv60s'] != null
            ? HRVMetrics.fromJson(Map<String, dynamic>.from(data['hrv60s']))
            : null,
        (data['rhr'] as num).toDouble(),
        SpatioTemporal.fromJson(Map<String, dynamic>.from(data['phoneSensor'])),
      );
    } catch (e) {
      _debugLog('❌ Error converting cached data: $e', type: 'ERROR');
      return null;
    }
  }

  Future<void> _performPeriodicPanicCheck() async {
    try {
      final box = await Hive.openBox('hr_box');
      final recentKeys = box.keys
          .where((key) => key.toString().startsWith('hr_'))
          .toList()
          .reversed
          .take(10)
          .toList();

      _debugLog(
        '🔍 Periodic panic check - found ${recentKeys.length} recent data points',
      );

      if (recentKeys.length < 5) {
        _debugLog(
          'ℹ️ Insufficient data for panic check (need 5, got ${recentKeys.length})',
        );
        return;
      }

      final recentData = <HeartRateData>[];
      for (final key in recentKeys) {
        final data = box.get(key);
        if (data != null) {
          final hrData = _convertToHeartRateData(data);
          if (hrData != null) {
            recentData.add(hrData);
          }
        }
      }

      _debugLog(
        '🧠 Running panic pattern analysis on ${recentData.length} data points',
      );
      await _checkForPanicPatterns(recentData);
    } catch (e) {
      _debugLog('❌ Error in periodic panic check: $e', type: 'ERROR');
    }
  }

  Future<void> _checkForPanicPatterns(List<HeartRateData> recentData) async {
    if (recentData.length < 5) return;

    final recentBPM = recentData.map((d) => d.bpm).toList();
    final avgBPM = recentBPM.reduce((a, b) => a + b) / recentBPM.length;

    _debugLog(
      '📊 Recent BPM analysis: avg=${avgBPM.toStringAsFixed(1)}, values=$recentBPM',
    );

    if (avgBPM > 100) {
      _debugLog(
        '⚠️ Elevated heart rate detected (avg: ${avgBPM.toStringAsFixed(1)} BPM) - running ML prediction',
      );

      final prediction = await _mlService!.predictPanicAttack(recentData.last);
      _debugLog(
        '🧠 ML Prediction: panic=${prediction.isPanic}, confidence=${(prediction.confidence * 100).toStringAsFixed(1)}%',
      );

      if (prediction.isPanic) {
        _panicDetections++;
        _handlePanicDetection(prediction, recentData.last);
      }
    } else {
      _debugLog(
        '✅ Heart rate within normal range (avg: ${avgBPM.toStringAsFixed(1)} BPM)',
      );
    }
  }

  void _handlePanicDetection(
    PanicPrediction prediction,
    HeartRateData? hrData,
  ) {
    _debugLog(
      '🚨🚨🚨 PANIC DETECTED! Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}% (Total detections: $_panicDetections)',
      type: 'ALERT',
    );

    // Update notification for panic alert
    FlutterForegroundTask.updateService(
      notificationTitle: '🚨 Panic Alert!',
      notificationText: 'High probability of panic attack detected',
    );

    // Log panic event
    _logPanicEvent(prediction, hrData);
  }

  Future<void> _logPanicEvent(
    PanicPrediction prediction,
    HeartRateData? hrData,
  ) async {
    try {
      final box = await Hive.openBox('panic_events');
      final key = 'panic_${DateTime.now().millisecondsSinceEpoch}';

      final eventData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'confidence': prediction.confidence,
        'features': prediction.features,
        'heart_rate': hrData?.bpm,
        'hrv': hrData?.HRV60s?.rmssd,
        'activity': hrData?.phoneSensor.rawActivityStatus,
      };

      FlutterForegroundTask.sendDataToMain(prediction.toJson());

      await box.put(key, eventData);
      _debugLog('📝 Panic event logged to storage');
    } catch (e) {
      _debugLog('❌ Error logging panic event: $e', type: 'ERROR');
    }
  }

  void _updateNotification() {
    final minutesActive = _monitoringCount ~/ 2;
    FlutterForegroundTask.updateService(
      notificationTitle: 'AURA Health Monitor',
      notificationText:
          'Active for $minutesActive minutes | Data: $_totalDataPoints',
    );

    _debugLog(
      '📱 Notification updated: $minutesActive minutes active, $_totalDataPoints data points',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _monitoringCount++;
    _debugLog('🔄 Repeat event #$_monitoringCount at $timestamp');

    if (_monitoringCount % 2 == 0) {
      _debugLog('⏰ Triggering aggregation via onRepeatEvent');
      _processAndAggregateData();
    }

    _updateNotification();

    // Send monitoring stats to UI
    FlutterForegroundTask.sendDataToMain({
      'type': 'monitoring_stats',
      'count': _monitoringCount,
      'dataPoints': _totalDataPoints,
      'successfulAggregations': _successfulAggregations,
      'panicDetections': _panicDetections,
    });
  }

  @override
  void onReceiveData(Object data) {
    _debugLog('📨 Received data from main isolate: $data');
  }

  @override
  void onNotificationButtonPressed(String id) {
    _debugLog('🔘 Notification button pressed: $id');

    switch (id) {
      case 'panic_help':
        _debugLog('🆘 Panic help requested - launching breathing guide');
        FlutterForegroundTask.launchApp('/breathing');
        break;
      case 'stop_service':
        _debugLog('⏹️ Stop service requested by user');
        FlutterForegroundTask.stopService();
        break;
    }
  }

  void _startListeningToBLE() {
    _debugLog('🎧 Starting BLE data aggregation system...');

    _aggregationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _debugLog('⏰ Aggregation timer triggered');
      _processAndAggregateData();
    });

    _bleSub = _bleService!.rawHrStream.listen(
      (rawData) {
        _totalDataPoints++;
        print('[TaskHandler] ⭐️ RECEIVED RAW DATA! BPM: ${rawData.bpm}');
        _debugLog(
          '📥 Raw BLE data #$_totalDataPoints: ${rawData.bpm} BPM, ${rawData.rrIntervals?.length ?? 0} RR intervals',
        );

        if (rawData.rrIntervals != null) {
          _accumulateRR!.addAll(rawData.rrIntervals!.cast<double>());
          _debugLog(
            '📊 Accumulated RR intervals: ${_accumulateRR.length} total',
          );
        }
      },
      onError: (error) {
        _debugLog('❌ BLE stream error: $error', type: 'ERROR');
      },
      onDone: () {
        _debugLog('ℹ️ BLE stream closed');
      },
    );

    _debugLog('✅ BLE listening started successfully');
  }

  Future<void> _processAndAggregateData() async {
    _debugLog('🔄 Starting data aggregation process...');

    final List<double> rrSnapshot = List.from(_accumulateRR!);
    _accumulateRR.clear();

    _debugLog('📊 Processing ${rrSnapshot.length} RR intervals');

    if (rrSnapshot.isEmpty) {
      _debugLog(
        '⚠️ No RR data received in the last minute. Skipping aggregation.',
      );
      _failedAggregations++;
      return;
    }

    try {
      final int currentTimeMs = DateTime.now().millisecondsSinceEpoch;

      // Calculate aggregated BPM
      final double averageRR =
          rrSnapshot.reduce((a, b) => a + b) / rrSnapshot.length;
      final int aggregatedBPM = (60000 / averageRR).round();

      _debugLog(
        '🧮 Calculated aggregated BPM: $aggregatedBPM (avg RR: ${averageRR.toStringAsFixed(2)}ms)',
      );

      // Calculate HRV metrics
      rrSnapshot.forEach((r) {
        _hrvService!.addRR(r, currentTimeMs);
      });
      final hrvMetrics = _hrvService!.computeForStandardWindows(
        nowMs: currentTimeMs,
      );

      _debugLog(
        '📈 HRV calculated - RMSSD: ${hrvMetrics[60]?.rmssd?.toStringAsFixed(2)}',
      );

      // Get phone sensor context
      final SpatioTemporal spatio =
          _phoneSensorService!.latestContext ?? SpatioTemporal.empty();
      _debugLog(
        '📱 Phone sensor context: ${spatio.rawActivityStatus}, Noise: ${spatio.noiseLeveldB}dB',
      );

      // Calculate RHR
      final double rhr = _rhrService!.computeRHR(_history!) ?? 0.0;
      _debugLog('❤️ Resting Heart Rate: ${rhr.toStringAsFixed(1)}');

      // Create final HeartRateData
      final hrFinal = HeartRateData(
        aggregatedBPM,
        DateTime.now(),
        rrSnapshot,
        hrvMetrics[10],
        hrvMetrics[30],
        hrvMetrics[60],
        rhr,
        spatio,
      );

      _debugLog('✅ HeartRateData created successfully');

      // Send to main isolate
      FlutterForegroundTask.sendDataToMain(hrFinal.toJson());
      _debugLog('📤 Data sent to main isolate');

      // Save to history and storage
      _history.add(hrFinal);
      _pruneHistory();
      await _saveToHive(hrFinal);
      _debugLog('💾 Data saved to Hive');

      // Sync to Firestore
      await _firestoreService!.syncHeartRateData(hrFinal);
      _debugLog('☁️ Data synced to Firestore');

      // Run ML prediction
      final prediction = await _mlService!.predictPanicAttack(hrFinal);
      _debugLog(
        '🧠 ML Prediction: panic=${prediction.isPanic}, confidence=${(prediction.confidence * 100).toStringAsFixed(1)}%',
      );

      if (prediction.isPanic && prediction.confidence > 0.7) {
        _panicDetections++;
        _handlePanicDetection(prediction, hrFinal);
      }

      // Emit to local stream
      _finalHrCtrl.add(hrFinal);

      _successfulAggregations++;
      _debugLog(
        '🎉 Data aggregation completed successfully (#$_successfulAggregations)',
      );
    } catch (e, stackTrace) {
      _failedAggregations++;
      _debugLog('❌ Data aggregation FAILED: $e', type: 'ERROR');
      _debugLog('Stack trace: $stackTrace', type: 'ERROR');
    }
  }

  void _pruneHistory() {
    final initialCount = _history!.length;
    final cutoff = DateTime.now().millisecondsSinceEpoch - (60 * 60 * 1000);
    _history.removeWhere((h) => h.timestamp.millisecondsSinceEpoch < cutoff);
    final removed = initialCount - _history.length;

    if (removed > 0) {
      _debugLog('🧹 Pruned $removed old data points from history');
    }
  }

  Future<void> _saveToHive(HeartRateData hr) async {
    try {
      final box = Hive.box('hr_box');
      final key = hr.timestamp.millisecondsSinceEpoch.toString();
      final jsonMap = hr.toJson();
      await box.put(key, jsonMap);
      _debugLog('💾 Saved to Hive: key=$key, BPM=${hr.bpm}');
    } catch (e) {
      _debugLog('❌ Error saving to Hive: $e', type: 'ERROR');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _debugLog('🛑 Health monitoring task DESTROYING at $timestamp');

    try {
      // 1. Cancel semua timers
      _debugLog('⏹️ Cancelling timers...');
      _monitoringTimer?.cancel();
      _aggregationTimer?.cancel();
      _watchdogTimer?.cancel();
      _dataSyncTimer?.cancel();
      _panicCheckTimer?.cancel();

      // 2. Cancel subscriptions
      _debugLog('⏹️ Cancelling subscriptions...');
      _bleSub?.cancel();

      // 3. Stop Core Services
      _debugLog('⏹️ Stopping core services...');
      await _bleService!.disconnect();
      _phoneSensorService!.stop();

      // 4. Close Hive
      _debugLog('💾 Closing Hive boxes...');
      await Hive.close();

      // 5. Close stream controller
      _debugLog('📡 Closing stream controllers...');
      await _finalHrCtrl.close();

      _debugLog('✅ Task destruction completed successfully');

      // Final stats
      _debugLog('''
      📊 FINAL TASK STATISTICS:
      ┌─────────────────────────────────────
      │ Total Runtime: ${_monitoringCount ~/ 2} minutes
      │ Data Points Processed: $_totalDataPoints
      │ Successful Aggregations: $_successfulAggregations
      │ Failed Aggregations: $_failedAggregations
      │ Panic Detections: $_panicDetections
      │ Final History Size: ${_history!.length}
      └─────────────────────────────────────
      ''', type: 'REPORT');
    } catch (e, stackTrace) {
      _debugLog('❌ Error during task destruction: $e', type: 'ERROR');
      _debugLog('Stack trace: $stackTrace', type: 'ERROR');
    }
  }

  @override
  void onNotificationPressed() {
    _debugLog('🔘 Notification pressed - launching app');
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {
    _debugLog('❌ Notification dismissed by user');
  }
}

// class HealthMonitoringTaskHandler extends TaskHandler {
//   int _monitoringCount = 0;
//   Timer? _monitoringTimer;

//   // STATE DAN INSTANCE YANG DIPERLUKAN UNTUK AGREGASI
//   final HRVService _hrvService = HRVService(); // Instance baru di isolate ini
//   final RHRService _rhrService = RHRService(); // Instance baru
//   final FirestoreService _firestoreService =
//       FirestoreService(); // Instance baru
//   final MLPanicService _mlService = MLPanicService(); // Instance baru
//   final PhoneSensorService _phoneSensorService =
//       PhoneSensorService(); // Singleton (aman)
//   final BLEService _bleService = BLEService();

//   final List<double> _accumulateRR = [];
//   final List<HeartRateData> _history = [];

//   StreamSubscription? _bleSub;
//   Timer? _aggregationTimer; // Timer 1 menit

//   // Timers untuk maintenance/watchdog
//   Timer? _watchdogTimer;
//   Timer? _dataSyncTimer;
//   Timer? _panicCheckTimer;

//   // Output Stream (hanya jika Anda ingin mengirim data ke Main Isolate/UI)
//   // Jika tidak, Anda bisa hapus
//   final StreamController<HeartRateData> _finalHrCtrl =
//       StreamController<HeartRateData>.broadcast();

//   // Debug counters
//   int _totalDataPoints = 0;
//   int _successfulAggregations = 0;
//   int _failedAggregations = 0;
//   int _panicDetections = 0;

//   void _debugLog(String message, {String type = "INFO"}) {
//     final timestamp = DateTime.now().toIso8601String();
//     final logMessage = '[$timestamp] [BackgroundTask-$type] $message';

//     print('🔵 $logMessage');

//     // Send to main isolate for UI debugging if needed
//     try {
//       FlutterForegroundTask.sendDataToMain({
//         'type': 'debug_log',
//         'message': message,
//         'timestamp': timestamp,
//       });
//     } catch (e) {
//       print('❌ Failed to send debug log to main isolate: $e');
//     }
//   }

//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
//     try {
//       print('[TaskHandler] Health monitoring started at $timestamp');

//       await PhoneSensorService().initialize();
//       await BLEService().startScan();

//       // Initialize minimal services in background
//       _debugLog('💾 Initializing Hive storage...');
//       await Hive.initFlutter();
//       if (!Hive.isBoxOpen('hr_box')) {
//         await Hive.openBox('hr_box');
//         _debugLog('✅ Hive hr_box opened');
//       }
//       if (!Hive.isBoxOpen('sync_queue')) await Hive.openBox('sync_queue');
//       _debugLog('✅ Hive sync_queue opened');
//       if (!Hive.isBoxOpen('panic_events')) await Hive.openBox('panic_events');

//       _debugLog('🎯 Starting BLE listening and maintenance timers...');
//       _startListeningToBLE();
//       _startMaintenanceTimers();

//       _debugLog('🎉 Health monitoring task STARTED SUCCESSFULLY');
//     } catch (e, stackTrace) {
//       _debugLog('💥 CRITICAL ERROR during task startup: $e', type: 'ERROR');
//       _debugLog('Stack trace: $stackTrace', type: 'ERROR');
//       rethrow;
//     }
//   }

//   void _startMaintenanceTimers() {
//     // Watchdog timer - ensure BLE connection
//     _watchdogTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
//       if (!_bleService.isConnected) {
//         print('[TaskHandler] Watchdog: BLE disconnected, restarting scan...');
//         await _bleService.startScan();
//       }
//     });

//     // Data sync timer - sync cached data to Firestore
//     _dataSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
//       await _syncCachedData();
//     });

//     // Panic check timer - additional safety check
//     _panicCheckTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
//       await _performPeriodicPanicCheck();
//     });
//   }

//   Future<void> _cacheDataForSync(HeartRateData hrData) async {
//     try {
//       final box = await Hive.openBox('sync_queue');
//       final key = 'hr_${hrData.timestamp.millisecondsSinceEpoch}';

//       final data = {
//         'bpm': hrData.bpm,
//         'timestamp': hrData.timestamp.millisecondsSinceEpoch,
//         'rrIntervals': hrData.rrIntervals,
//         'hrv10s': hrData.HRV10s?.toJson(),
//         'hrv30s': hrData.HRV30s?.toJson(),
//         'hrv60s': hrData.HRV60s?.toJson(),
//         'rhr': hrData.rhr,
//         'phoneSensor': hrData.phoneSensor.toJson(),
//         'type': 'heart_rate',
//       };

//       await box.put(key, data);
//     } catch (e) {
//       print('[ForegroundService] Error caching data: $e');
//     }
//   }

//   Future<void> _syncCachedData() async {
//     try {
//       final box = await Hive.openBox('sync_queue');
//       final keys = box.keys.toList();

//       if (keys.isEmpty) return;

//       print('[ForegroundService] Syncing ${keys.length} cached data points...');

//       int successCount = 0;
//       for (final key in keys) {
//         try {
//           final data = box.get(key);
//           if (data != null && data['type'] == 'heart_rate') {
//             final hrData = _convertToHeartRateData(data);
//             if (hrData != null) {
//               await _firestoreService.syncHeartRateData(hrData);
//               await box.delete(key);
//               successCount++;
//             }
//           }
//         } catch (e) {
//           print('[ForegroundService] Error syncing item $key: $e');
//         }
//       }

//       print(
//         '[ForegroundService] Sync completed: $successCount/${keys.length} items synced',
//       );
//     } catch (e) {
//       print('[ForegroundService] Error syncing data: $e');
//     }
//   }

//   HeartRateData? _convertToHeartRateData(Map<dynamic, dynamic> data) {
//     try {
//       return HeartRateData(
//         data['bpm'] as int,
//         DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
//         (data['rrIntervals'] as List?)?.cast<double>(),
//         data['hrv10s'] != null
//             ? HRVMetrics.fromJson(Map<String, dynamic>.from(data['hrv10s']))
//             : null,
//         data['hrv30s'] != null
//             ? HRVMetrics.fromJson(Map<String, dynamic>.from(data['hrv30s']))
//             : null,
//         data['hrv60s'] != null
//             ? HRVMetrics.fromJson(Map<String, dynamic>.from(data['hrv60s']))
//             : null,
//         (data['rhr'] as num).toDouble(),
//         SpatioTemporal.fromJson(Map<String, dynamic>.from(data['phoneSensor'])),
//       );
//     } catch (e) {
//       print('[ForegroundService] Error converting data: $e');
//       return null;
//     }
//   }

//   Future<void> _performPeriodicPanicCheck() async {
//     try {
//       final box = await Hive.openBox('hr_box');
//       final recentKeys = box.keys
//           .where((key) => key.toString().startsWith('hr_'))
//           .toList()
//           .reversed
//           .take(10)
//           .toList();

//       if (recentKeys.length < 5) return;

//       final recentData = <HeartRateData>[];
//       for (final key in recentKeys) {
//         final data = box.get(key);
//         if (data != null) {
//           final hrData = _convertToHeartRateData(data);
//           if (hrData != null) {
//             recentData.add(hrData);
//           }
//         }
//       }

//       await _checkForPanicPatterns(recentData);
//     } catch (e) {
//       print('[ForegroundService] Error in periodic panic check: $e');
//     }
//   }

//   Future<void> _checkForPanicPatterns(List<HeartRateData> recentData) async {
//     if (recentData.length < 5) return;

//     // Check for rapid heart rate increase
//     final recentBPM = recentData.map((d) => d.bpm).toList();
//     final avgBPM = recentBPM.reduce((a, b) => a + b) / recentBPM.length;

//     if (avgBPM > 100) {
//       // High heart rate detected - run ML prediction
//       final prediction = await _mlService.predictPanicAttack(recentData.last);
//       if (prediction.isPanic) {
//         _handlePanicDetection(prediction, recentData.last);
//       }
//     }
//   }

//   void _handlePanicDetection(
//     PanicPrediction prediction,
//     HeartRateData? hrData,
//   ) {
//     print(
//       '[ForegroundService] 🚨 Panic detected: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
//     );

//     // Update notification for panic alert
//     FlutterForegroundTask.updateService(
//       notificationTitle: '🚨 Panic Alert!',
//       notificationText: 'High probability of panic attack detected',
//     );

//     // Log panic event
//     _logPanicEvent(prediction, hrData);
//   }

//   Future<void> _logPanicEvent(
//     PanicPrediction prediction,
//     HeartRateData? hrData,
//   ) async {
//     try {
//       final box = await Hive.openBox('panic_events');
//       final key = 'panic_${DateTime.now().millisecondsSinceEpoch}';

//       final eventData = {
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//         'confidence': prediction.confidence,
//         'features': prediction.features,
//         'heart_rate': hrData?.bpm,
//         'hrv': hrData?.HRV60s?.rmssd,
//         'activity': hrData?.phoneSensor.rawActivityStatus,
//       };

//       FlutterForegroundTask.sendDataToMain(prediction.toJson());

//       await box.put(key, eventData);
//     } catch (e) {
//       print('[ForegroundService] Error logging panic event: $e');
//     }
//   }

//   void _updateNotification() {
//     FlutterForegroundTask.updateService(
//       notificationTitle: 'AURA Health Monitor',
//       notificationText: 'Active for ${_monitoringCount ~/ 2} minutes',
//     );
//   }

//   @override
//   void onRepeatEvent(DateTime timestamp) {
//     // This runs every 30 seconds based on our ForegroundTaskEventAction.repeat(30000)
//     _monitoringCount++;
//     _updateNotification();

//     // Send data to UI if needed
//     FlutterForegroundTask.sendDataToMain(_monitoringCount);
//   }

//   @override
//   void onReceiveData(Object data) {
//     print('[TaskHandler] Received data: $data');
//     // Handle data sent from main isolate
//   }

//   @override
//   void onNotificationButtonPressed(String id) {
//     print('[TaskHandler] Notification button pressed: $id');

//     switch (id) {
//       case 'panic_help':
//         // Open breathing guide or emergency contact
//         FlutterForegroundTask.launchApp('/breathing');
//         break;
//       case 'stop_service':
//         // Stop the service when user requests
//         FlutterForegroundTask.stopService();
//         break;
//     }
//   }

//   void _startListeningToBLE() {
//     _aggregationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
//       _processAndAggregateData();
//     });

//     _bleSub = _bleService.rawHrStream.listen((rawData) {
//       // Cukup akumulasi RR interval
//       if (rawData.rrIntervals != null) {
//         _accumulateRR.addAll(rawData.rrIntervals!.cast<double>());
//       }
//     });
//   }

//   Future<void> _processAndAggregateData() async {
//     final List<double> rrSnapshot = List.from(_accumulateRR);
//     _accumulateRR.clear();

//     if (rrSnapshot.isEmpty) {
//       print(
//         '[Aggregator] No RR data received in the last minute. Skipping sync.',
//       );
//       return;
//     }

//     final int currentTimeMs =
//         DateTime.now().millisecondsSinceEpoch; // ⭐️ Tentukan waktu sekali
//     // 2. Hitung BPM rata-rata
//     // Untuk data 1 menit, BPM terbaik dihitung dari RR snapshot.
//     final double averageRR =
//         rrSnapshot.reduce((a, b) => a + b) / rrSnapshot.length;
//     // BPM = 60000 / Rata-rata RR (dalam ms)
//     final int aggregatedBPM = (60000 / averageRR).round();

//     rrSnapshot.forEach((r) {
//       _hrvService.addRR(r, currentTimeMs);
//     });
//     final hrvMetrics = _hrvService.computeForStandardWindows(
//       nowMs: currentTimeMs,
//     );

//     // Ambil Data Sensor Ponsel
//     // **ASUMSI:** PhoneSensorService mengelola statusnya sendiri dan `latestContext` aman diakses.
//     final SpatioTemporal spatio =
//         _phoneSensorService.latestContext ?? SpatioTemporal.empty();

//     // 3. Hitung RHR (dari history di kelas ini)
//     final double rhr = _rhrService.computeRHR(_history) ?? 0.0;

//     // 4. Gabungkan menjadi model HeartRateData FINAL
//     final hrFinal = HeartRateData(
//       aggregatedBPM,
//       DateTime.now(),
//       rrSnapshot,
//       hrvMetrics[10],
//       hrvMetrics[30],
//       hrvMetrics[60],
//       rhr,
//       spatio,
//     );

//     // Kirim sebagai JSON Map agar aman menyeberang Isolate
//     FlutterForegroundTask.sendDataToMain(hrFinal.toJson());

//     // 5. Simpan ke History dan Hive
//     _history.add(hrFinal);
//     _pruneHistory();
//     await _saveToHive(hrFinal);

//     // 6. Sinkronisasi ke Firestore
//     await _firestoreService.syncHeartRateData(hrFinal);

//     // 7. Deteksi ML
//     final prediction = await _mlService.predictPanicAttack(hrFinal);
//     if (prediction.isPanic && prediction.confidence > 0.7) {
//       // Trigger notifikasi, alert, dll.
//       _handlePanicDetection(prediction, hrFinal);
//     }

//     // 8. Emit data final ke UI
//     _finalHrCtrl.add(hrFinal);
//   }

//   // Pindahkan fungsi pruning history ke sini
//   void _pruneHistory() {
//     final cutoff = DateTime.now().millisecondsSinceEpoch - (60 * 60 * 1000);
//     _history.removeWhere((h) => h.timestamp.millisecondsSinceEpoch < cutoff);
//   }

//   // Pindahkan fungsi Hive ke sini
//   Future<void> _saveToHive(HeartRateData hr) async {
//     try {
//       final box = Hive.box('hr_box');
//       final key = hr.timestamp.millisecondsSinceEpoch.toString();
//       final jsonMap = hr
//           .toJson(); // Pastikan HeartRateData memiliki method toJson()
//       await box.put(key, jsonMap);
//     } catch (e) {
//       print('Error saving to Hive: $e');
//     }
//   }

//   @override
//   Future<void> onDestroy(DateTime timestamp) async {
//     print('[TaskHandler] Health monitoring destroyed...');

//     // 1. Cancel semua timers
//     _monitoringTimer?.cancel();
//     _aggregationTimer?.cancel(); // Wajib
//     _watchdogTimer?.cancel(); // Wajib
//     _dataSyncTimer?.cancel(); // Wajib
//     _panicCheckTimer?.cancel(); // Wajib

//     // 2. Cancel subscriptions
//     _bleSub?.cancel(); // Wajib

//     // 3. Stop Core Services
//     await _bleService.disconnect();
//     _phoneSensorService.stop();

//     // 4. Close Hive
//     await Hive.close();
//   }

//   // @override
//   // void dispose() {
//   //   _bleSub?.cancel();
//   //   _aggregationTimer?.cancel();
//   //   _finalHrCtrl.close();
//   //   super.dispose();
//   // }

//   @override
//   void onNotificationPressed() {
//     print('[TaskHandler] Notification pressed');
//     // Bring app to foreground when notification is tapped
//     FlutterForegroundTask.launchApp();
//   }

//   @override
//   void onNotificationDismissed() {
//     print('[TaskHandler] Notification dismissed');
//   }
// }
