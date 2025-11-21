// services/foreground_service_hr.dart
import 'dart:async';
import 'dart:io';
import 'package:aura_bluetooth/models/heart_rate_model.dart';
import 'package:aura_bluetooth/models/hrv_metric.dart';
import 'package:aura_bluetooth/models/spatio.model.dart';
import 'package:aura_bluetooth/services/firestore_service.dart';
import 'package:aura_bluetooth/services/ml_panic_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/ble_service.dart';
import '../services/phone_sensor_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ForegroundMonitorService {
  static final ForegroundMonitorService _instance = ForegroundMonitorService._internal();
  factory ForegroundMonitorService() => _instance;

  final BLEService _bleService = BLEService();
  final PhoneSensorService _phoneSensorService = PhoneSensorService();
  final FirestoreService _firestoreService = FirestoreService();
  final MLPanicService _mlService = MLPanicService();
  
  Timer? _watchdogTimer;
  Timer? _dataSyncTimer;
  Timer? _panicCheckTimer;
  StreamSubscription<HeartRateData>? _hrSubscription;
  StreamSubscription<PanicPrediction>? _panicSubscription;

  bool _isRunning = false;
  int _dataPointsCollected = 0;

  ForegroundMonitorService._internal();

  // Initialize foreground task configuration
  void _initForegroundTask() {
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
  Future<void> _requestPermissions() async {
    // Notification permission for Android 13+
    final NotificationPermission notificationPermission = 
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // Battery optimization permission
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      // Exact alarm permission (optional, for precise timing)
      if (!await FlutterForegroundTask.canScheduleExactAlarms) {
        // Note: This will open settings page
        // await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      }
    }
  }

  Future<void> start() async {
    if (_isRunning) return;

    print('[ForegroundService] Starting foreground monitoring...');

    try {
      // Initialize Hive
      await _initializeHive();

      // Request permissions
      await _requestPermissions();

      // Initialize foreground task
      _initForegroundTask();

      // Start the foreground service
      final result = await FlutterForegroundTask.startService(
        notificationTitle: 'AURA Health Monitor',
        notificationText: 'Monitoring heart rate and sensors...',
        notificationButtons: [
          const NotificationButton(id: 'panic_help', text: 'Get Help'),
          const NotificationButton(id: 'stop_service', text: 'Stop'),
        ],
        callback: startCallback,
      );

      if (result == ServiceRequestSuccess) {
        // Start monitoring services
        await _phoneSensorService.initialize();
        await _bleService.startScan();
        _setupDataListeners();
        _startTimers();

        _isRunning = true;
        print('[ForegroundService] Started successfully');
      } else {
        print('[ForegroundService] Failed to start service: $result');
      }
    } catch (e) {
      print('[ForegroundService] Error starting service: $e');
    }
  }

  Future<void> _initializeHive() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('hr_box')) {
      await Hive.openBox('hr_box');
    }
    if (!Hive.isBoxOpen('sync_queue')) {
      await Hive.openBox('sync_queue');
    }
    if (!Hive.isBoxOpen('panic_events')) {
      await Hive.openBox('panic_events');
    }
  }

  void _setupDataListeners() {
    _hrSubscription = _bleService.hrStream.listen((hrData) async {
      _dataPointsCollected++;

      // Update notification with latest data
      await _updateNotification(hrData);

      // Cache data for sync
      await _cacheDataForSync(hrData);

      // Check for panic attacks
      final prediction = await _mlService.predictPanicAttack(hrData);
      if (prediction.isPanic && prediction.confidence > 0.7) {
        _handlePanicDetection(prediction, hrData);
      }
    });

    _panicSubscription = _bleService.panicAlertStream.listen((prediction) {
      _handlePanicDetection(prediction, null);
    });
  }

  void _startTimers() {
    // Watchdog timer - ensure BLE connection
    _watchdogTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!_bleService.isConnected) {
        print('[ForegroundService] Watchdog: BLE disconnected, restarting scan...');
        await _bleService.startScan();
      }
    });

    // Data sync timer - sync cached data to Firestore
    _dataSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _syncCachedData();
    });

    // Panic check timer - additional safety check
    _panicCheckTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _performPeriodicPanicCheck();
    });
  }

  Future<void> _updateNotification(HeartRateData hrData) async {
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'AURA: ${hrData.bpm} BPM',
        notificationText: 'HRV: ${hrData.HRV60s?.rmssd?.toStringAsFixed(1) ?? "N/A"} | '
                         'Activity: ${hrData.phoneSensor.rawActivityStatus}',
      );
    } catch (e) {
      print('[ForegroundService] Error updating notification: $e');
    }
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
    } catch (e) {
      print('[ForegroundService] Error caching data: $e');
    }
  }

  Future<void> _syncCachedData() async {
    try {
      final box = await Hive.openBox('sync_queue');
      final keys = box.keys.toList();
      
      if (keys.isEmpty) return;
      
      print('[ForegroundService] Syncing ${keys.length} cached data points...');
      
      int successCount = 0;
      for (final key in keys) {
        try {
          final data = box.get(key);
          if (data != null && data['type'] == 'heart_rate') {
            final hrData = _convertToHeartRateData(data);
            if (hrData != null) {
              await _firestoreService.syncHeartRateData(hrData);
              await box.delete(key);
              successCount++;
            }
          }
        } catch (e) {
          print('[ForegroundService] Error syncing item $key: $e');
        }
      }
      
      print('[ForegroundService] Sync completed: $successCount/${keys.length} items synced');
    } catch (e) {
      print('[ForegroundService] Error syncing data: $e');
    }
  }

  HeartRateData? _convertToHeartRateData(Map<dynamic, dynamic> data) {
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
      print('[ForegroundService] Error converting data: $e');
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
      
      if (recentKeys.length < 5) return;
      
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
      
      await _checkForPanicPatterns(recentData);
    } catch (e) {
      print('[ForegroundService] Error in periodic panic check: $e');
    }
  }

  Future<void> _checkForPanicPatterns(List<HeartRateData> recentData) async {
    if (recentData.length < 5) return;
    
    // Check for rapid heart rate increase
    final recentBPM = recentData.map((d) => d.bpm).toList();
    final avgBPM = recentBPM.reduce((a, b) => a + b) / recentBPM.length;
    
    if (avgBPM > 100) {
      // High heart rate detected - run ML prediction
      final prediction = await _mlService.predictPanicAttack(recentData.last);
      if (prediction.isPanic) {
        _handlePanicDetection(prediction, recentData.last);
      }
    }
  }

  void _handlePanicDetection(PanicPrediction prediction, HeartRateData? hrData) {
    print('[ForegroundService] 🚨 Panic detected: ${(prediction.confidence * 100).toStringAsFixed(1)}%');
    
    // Update notification for panic alert
    FlutterForegroundTask.updateService(
      notificationTitle: '🚨 Panic Alert!',
      notificationText: 'High probability of panic attack detected',
    );
    
    // Log panic event
    _logPanicEvent(prediction, hrData);
  }

  Future<void> _logPanicEvent(PanicPrediction prediction, HeartRateData? hrData) async {
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
      
      await box.put(key, eventData);
    } catch (e) {
      print('[ForegroundService] Error logging panic event: $e');
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    
    print('[ForegroundService] Stopping...');
    
    try {
      // Cancel subscriptions
      await _hrSubscription?.cancel();
      await _panicSubscription?.cancel();
      
      // Cancel timers
      _watchdogTimer?.cancel();
      _dataSyncTimer?.cancel();
      _panicCheckTimer?.cancel();
      
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

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('[TaskHandler] Health monitoring started at $timestamp');
    
    // Initialize minimal services in background
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('hr_box')) {
      await Hive.openBox('hr_box');
    }
    
    // Start periodic monitoring in background
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _monitoringCount++;
      _updateNotification();
    });
  }

  void _updateNotification() {
    FlutterForegroundTask.updateService(
      notificationTitle: 'AURA Health Monitor',
      notificationText: 'Active for ${_monitoringCount ~/ 2} minutes',
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // This runs every 30 seconds based on our ForegroundTaskEventAction.repeat(30000)
    _monitoringCount++;
    _updateNotification();
    
    // Send data to UI if needed
    FlutterForegroundTask.sendDataToMain(_monitoringCount);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print('[TaskHandler] Health monitoring destroyed at $timestamp, timeout: $isTimeout');
    _monitoringTimer?.cancel();
    await Hive.close();
  }

  @override
  void onReceiveData(Object data) {
    print('[TaskHandler] Received data: $data');
    // Handle data sent from main isolate
  }

  @override
  void onNotificationButtonPressed(String id) {
    print('[TaskHandler] Notification button pressed: $id');
    
    switch (id) {
      case 'panic_help':
        // Open breathing guide or emergency contact
        FlutterForegroundTask.launchApp('/breathing');
        break;
      case 'stop_service':
        // Stop the service when user requests
        FlutterForegroundTask.stopService();
        break;
    }
  }

  @override
  void onNotificationPressed() {
    print('[TaskHandler] Notification pressed');
    // Bring app to foreground when notification is tapped
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {
    print('[TaskHandler] Notification dismissed');
  }
}