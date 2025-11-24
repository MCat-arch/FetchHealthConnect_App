// services/phone_sensor_service.dart
import 'dart:async';
import 'package:aura_bluetooth/models/spatio.model.dart';
import 'package:aura_bluetooth/services/phone_permission_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:flutter/material.dart';

class PhoneSensorService {
  static final PhoneSensorService _instance = PhoneSensorService._internal();
  factory PhoneSensorService() => _instance;

  PhoneSensorService._internal(); // Private constructor

  SpatioTemporal latestContext = SpatioTemporal.empty();

  // Notifier juga langsung diisi nilai awal
  final ValueNotifier<SpatioTemporal> currentContextNotifier =
      ValueNotifier<SpatioTemporal>(SpatioTemporal.empty());

  NoiseMeter? noiseMeter;
  bool _isRecording = false;
  // double? noiseDB;

  String? _currentActivityStatus;
  double? _currentNoiseDB;
  VoidCallback? _listenerCallback;

  StreamSubscription<Activity>? _activitySubscription;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  StreamController<SpatioTemporal> _contextCtrl =
      StreamController<SpatioTemporal>.broadcast();

  Stream<SpatioTemporal> get contextStream => _contextCtrl.stream;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('[PhoneSensorService] Already initialized');
      return;
    }

    print('[PhoneSensorService] Initializing...');
    try {
      // Check permissions first
      final permissionsGranted =
          await PhonePermissionService.arePermissionGranted();
      if (!permissionsGranted) {
        print(
          '[PhoneSensorService] Permissions not granted, cannot initialize sensors',
        );
        return;
      }

      // Initialize activity recognition
      await _initializeActivityRecognition();

      // Initialize noise meter
      await _initializeNoiseMeter();

      _isInitialized = true;

      print("[PhoneSensorService] ✅ All sensors initialized successfully");
    } catch (e) {
      print("[PhoneSensorService] ❌ Error initializing sensors: $e");
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> _initializeActivityRecognition() async {
    try {
      print('[PhoneSensorService] Initializing activity recognition...');

      final activityRecognition = FlutterActivityRecognition.instance;

      // Check if activity recognition is available
      // final isAvailable = await activityRecognition
      //     .isActivityRecognitionAvailable();
      // if (!isAvailable) {
      //   print(
      //     '[PhoneSensorService] Activity recognition not available on this device',
      //   );
      //   return;
      // }

      final activityStream = activityRecognition.activityStream.handleError(
        _onError,
      );

      _activitySubscription = activityStream.listen((activity) {
        _updateActivity(activity);
      }, onError: _onError);

      print('[PhoneSensorService] ✅ Activity recognition initialized');
    } catch (e) {
      print('[PhoneSensorService] Error initializing activity recognition: $e');
      rethrow;
    }
  }

  Future<void> _initializeNoiseMeter() async {
    try {
      print('[PhoneSensorService] Initializing noise meter...');

      noiseMeter = NoiseMeter();

      _noiseSubscription = noiseMeter!.noise.listen(
        (reading) {
          _currentNoiseDB = reading.meanDecibel;
          _updateNoiseLevel(_currentNoiseDB);
        },
        onError: _onError,
        cancelOnError: false,
      );

      _isRecording = true;
      print('[PhoneSensorService] ✅ Noise meter initialized');
    } catch (e) {
      print('[PhoneSensorService] Error initializing noise meter: $e');
      // Don't rethrow - noise meter is optional
    }
  }

  void _updateActivity(Activity activity) {
    try {
      final _currentActivityStatus = activity.type
          .toString()
          .split('.')
          .last
          .toUpperCase();
      // final now = DateTime.now();

      // latestContext = SpatioTemporal.fromRawData(
      //   activityStatus: status,
      //   timestamp: now,
      //   noiseDB: noiseDB,
      //   // noiseDB: noiseDB ?? 0,
      // );
      // currentContextNotifier.value = latestContext;
      _emitCombinedContext();

      print('[PhoneSensorService] Activity updated: ');
    } catch (e) {
      print("[PhoneSensorService] Error updating activity: $e");
    }
  }

  void _updateNoiseLevel(double? dbLevel) {
    try {
      // if (latestContext != null && dbLevel != null) {
      //   latestContext = SpatioTemporal.fromRawData(
      //     activityStatus: latestContext!.rawActivityStatus,
      //     timestamp: DateTime.now(),
      //     noiseDB: dbLevel,
      //   );
      //   currentContextNotifier.value = latestContext;
      // }
      _currentNoiseDB = dbLevel;
      _emitCombinedContext();
    } catch (e) {
      print("[PhoneSensorService] Error updating noise level: $e");
    }
  }

  void _emitCombinedContext() {
    // Pastikan kedua data ada sebelum emit (atau gunakan nilai default)
    final newContext = SpatioTemporal.fromRawData(
      activityStatus: _currentActivityStatus ?? "UNKNOWN",
      timestamp: DateTime.now(),
      noiseDB: _currentNoiseDB ?? 0.0,
    );
    latestContext =
        newContext; // Tetap perbarui latestContext untuk akses sinkron
    currentContextNotifier.value = newContext;
    _contextCtrl.add(newContext); // Emit ke DataAggregationService
  }

  void _onError(dynamic error) {
    String errorMessage;
    if (error is PlatformException) {
      errorMessage = error.message ?? error.code;
    } else {
      errorMessage = error.toString();
    }
    debugPrint("PhoneSensorService error: $errorMessage");
  }

  void dispose() {
    print('[PhoneSensorService] Disposing...');
    _activitySubscription?.cancel();
    _noiseSubscription?.cancel();
    // _contextCtrl?.cancel();
    _isRecording = false;
    _isInitialized = false;
    print("PhoneSensorService: all streams disposed");
  }

  void stop() {
    _noiseSubscription?.cancel();
    _activitySubscription?.cancel();
    // _contextCtrl.close();
    _isRecording = false;
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  double? get currentNoiseLevel => _currentNoiseDB;
  SpatioTemporal get currentContext => latestContext;
}
