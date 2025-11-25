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

  PhoneSensorService._internal();

  // Default value agar tidak null
  SpatioTemporal latestContext = SpatioTemporal.empty();

  final ValueNotifier<SpatioTemporal> currentContextNotifier =
      ValueNotifier<SpatioTemporal>(SpatioTemporal.empty());

  NoiseMeter? noiseMeter;
  bool _isRecording = false;
  String _debugLabel = "UNKNOWN";

  String? _currentActivityStatus;
  double? _currentNoiseDB;

  StreamSubscription<Activity>? _activitySubscription;
  StreamSubscription<NoiseReading>? _noiseSubscription;

  final StreamController<SpatioTemporal> _contextCtrl =
      StreamController<SpatioTemporal>.broadcast();

  Stream<SpatioTemporal> get contextStream => _contextCtrl.stream;

  bool _isInitialized = false;

  Future<void> initialize({String label = 'SERVICE'}) async {
    _debugLabel = label;

    // Force re-init jika dipanggil lagi dengan label berbeda (misal retry di BG)
    if (_isInitialized) {
      print('[$_debugLabel] ⚠️ Already initialized. Skipping.');
      return;
    }
    // 1. Cek Permission (Hanya untuk Log, JANGAN RETURN)
    final permissionsGranted =
        await PhonePermissionService.arePermissionGranted();
    if (!permissionsGranted) {
      // Ubah jadi Warning, tapi JANGAN return! Biarkan dia mencoba.
      print(
        '[$_debugLabel] ⚠️ Permission check failed via handler, but attempting init anyway...',
      );
    }

    print('[$_debugLabel] 🚀 Initializing sensors sequence...');

    // 2. Init Activity (Prioritas Tinggi - Jarang Gagal)
    try {
      await _initializeActivityRecognition();
    } catch (e) {
      print('[$_debugLabel] ❌ Activity Init Failed: $e');
    }

    // 3. Init Noise (Prioritas Rendah - Sering Gagal di BG karena Privasi)
    try {
      await _initializeNoiseMeter();
    } catch (e) {
      print('[$_debugLabel] ⚠️ Noise Init Failed (Privacy restriction?): $e');
      // JANGAN rethrow, agar activity tetap jalan meski mic gagal
    }

    _isInitialized = true;
    print("[$_debugLabel] ✅ Sensor init sequence finished.");
  }

  Future<void> _initializeActivityRecognition() async {
    print('[$_debugLabel] Starting Activity Stream...');
    final activityRecognition = FlutterActivityRecognition.instance;

    // Cancel subscription lama jika ada
    await _activitySubscription?.cancel();

    _activitySubscription = activityRecognition.activityStream
        .handleError(_onError)
        .listen((activity) {
          // LOG INI HARUS MUNCUL SAAT HP DIGERAKKAN
          print('[$_debugLabel] 🏃 EVENT: ${activity.type}');
          _updateActivity(activity);
        });
  }

  Future<void> _initializeNoiseMeter() async {
    print('[$_debugLabel] Starting Noise Stream...');
    noiseMeter = NoiseMeter();

    await _noiseSubscription?.cancel();

    _noiseSubscription = noiseMeter!.noise.listen(
      (reading) {
        // Log sample pertama saja untuk memastikan hidup
        if (_currentNoiseDB == null || _currentNoiseDB == 0.0) {
          print('[$_debugLabel] 🎤 Sound Detected: ${reading.meanDecibel} dB');
        }
        _updateNoiseLevel(reading.meanDecibel);
      },
      onError: (e) {
        print('[$_debugLabel] 🎤 Mic Stream Error: $e');
      },
      cancelOnError: false,
    );
    _isRecording = true;
  }

  void _updateActivity(Activity activity) {
    try {
      _currentActivityStatus = activity.type
          .toString()
          .split('.')
          .last
          .toUpperCase();
      _emitCombinedContext();
    } catch (e) {
      print("[$_debugLabel] Update Activity Error: $e");
    }
  }

  void _updateNoiseLevel(double? dbLevel) {
    _currentNoiseDB = dbLevel;
    // Emit setiap update mic mungkin terlalu sering, tapi untuk debug biarkan dulu
    // _emitCombinedContext();
  }

  void _emitCombinedContext() {
    final newContext = SpatioTemporal.fromRawData(
      activityStatus: _currentActivityStatus ?? "UNKNOWN",
      timestamp: DateTime.now(),
      noiseDB: _currentNoiseDB ?? 0.0,
    );

    latestContext = newContext;
    currentContextNotifier.value = newContext;
    _contextCtrl.add(newContext);
  }

  void _onError(dynamic error) {
    print("[$_debugLabel] STREAM ERROR: $error");
  }

  void stop() {
    _noiseSubscription?.cancel();
    _activitySubscription?.cancel();
    _isRecording = false;
    _isInitialized = false; // Reset flag agar bisa di-init ulang
    print("[$_debugLabel] Sensors Stopped");
  }
}

// // services/phone_sensor_service.dart
// import 'dart:async';
// import 'package:aura_bluetooth/models/spatio.model.dart';
// import 'package:aura_bluetooth/services/phone_permission_service.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
// import 'package:noise_meter/noise_meter.dart';
// import 'package:flutter/material.dart';

// class PhoneSensorService {
//   static final PhoneSensorService _instance = PhoneSensorService._internal();
//   factory PhoneSensorService() => _instance;

//   PhoneSensorService._internal(); // Private constructor

//   SpatioTemporal latestContext = SpatioTemporal.empty();

//   // Notifier juga langsung diisi nilai awal
//   final ValueNotifier<SpatioTemporal> currentContextNotifier =
//       ValueNotifier<SpatioTemporal>(SpatioTemporal.empty());

//   NoiseMeter? noiseMeter;
//   bool _isRecording = false;
//   String _debugLabel = "UNKNOWN_ISOLATE";
//   // double? noiseDB;

//   String? _currentActivityStatus;
//   double? _currentNoiseDB;

//   StreamSubscription<Activity>? _activitySubscription;
//   StreamSubscription<NoiseReading>? _noiseSubscription;
//   final StreamController<SpatioTemporal> _contextCtrl =
//       StreamController.broadcast();

//   Stream<SpatioTemporal> get contextStream => _contextCtrl.stream;

//   bool _isInitialized = false;

//   Future<void> initialize({String label = 'SERVICE'}) async {
//     _debugLabel = label; // Set label saat init
//     if (_isInitialized) {
//       print('[PhoneSensorService] Already initialized');
//       return;
//     }

//     print('[PhoneSensorService] Initializing...');
//     try {

//       // Initialize activity recognition
//       await _initializeActivityRecognition();

//       // Initialize noise meter
//       await _initializeNoiseMeter();

//       _isInitialized = true;

//       print("[PhoneSensorService] ✅ All sensors initialized successfully");
//     } catch (e) {
//       print("[PhoneSensorService] ❌ Error initializing sensors: $e");
//       _isInitialized = false;
//       rethrow;
//     }
//   }

//   Future<void> _initializeActivityRecognition() async {
//     try {
//       print('[PhoneSensorService] Initializing activity recognition...');

//       final activityRecognition = FlutterActivityRecognition.instance;

//       // Check if activity recognition is available

//       final activityStream = activityRecognition.activityStream.handleError(
//         _onError,
//       );

//       _activitySubscription = activityStream.listen((activity) {
//         print('[$_debugLabel] 🏃 EVENT: ${activity.type}'); // <--- CEK INI
//         _updateActivity(activity);
//       }, onError: _onError);

//       print('[PhoneSensorService] ✅ Activity recognition initialized');
//     } catch (e) {
//       print('[PhoneSensorService] Error initializing activity recognition: $e');
//       rethrow;
//     }
//   }

//   Future<void> _initializeNoiseMeter() async {
//     try {
//       print('[PhoneSensorService] Initializing noise meter...');

//       noiseMeter = NoiseMeter();

//       _noiseSubscription = noiseMeter!.noise.listen(
//         (reading) {
//           if (_currentNoiseDB == null) print('[$_debugLabel]');
//           // _currentNoiseDB = reading.meanDecibel;
//           _updateNoiseLevel(reading.meanDecibel);
//         },
//         onError: _onError,
//         cancelOnError: false,
//       );

//       _isRecording = true;
//       print('[PhoneSensorService] ✅ Noise meter initialized');
//     } catch (e) {
//       print('[PhoneSensorService] Error initializing noise meter: $e');
//       // Don't rethrow - noise meter is optional
//     }
//   }

//   void _updateActivity(Activity activity) {
//     try {
//       _currentActivityStatus = activity.type
//           .toString()
//           .split('.')
//           .last
//           .toUpperCase();

//       print('[$_debugLabel] ✅ Activity Updated to: $_currentActivityStatus');
//       _emitCombinedContext();
//       // final now = DateTime.now();

//       // latestContext = SpatioTemporal.fromRawData(
//       //   activityStatus: status,
//       //   timestamp: now,
//       //   noiseDB: noiseDB,
//       //   // noiseDB: noiseDB ?? 0,
//       // );
//       // currentContextNotifier.value = latestContext;

//       print('[PhoneSensorService] Activity updated: ');
//     } catch (e) {
//       print("[PhoneSensorService] Error updating activity: $e");
//     }
//   }

//   void _updateNoiseLevel(double? dbLevel) {
//     try {
//       // if (latestContext != null && dbLevel != null) {
//       //   latestContext = SpatioTemporal.fromRawData(
//       //     activityStatus: latestContext!.rawActivityStatus,
//       //     timestamp: DateTime.now(),
//       //     noiseDB: dbLevel,
//       //   );
//       //   currentContextNotifier.value = latestContext;
//       // }
//       _currentNoiseDB = dbLevel;
//       _emitCombinedContext();
//     } catch (e) {
//       print("[PhoneSensorService] Error updating noise level: $e");
//     }
//   }

//   void _emitCombinedContext() {
//     // Pastikan kedua data ada sebelum emit (atau gunakan nilai default)
//     print(
//       '[$_debugLabel] 📦 Context Updated: Act=$_currentActivityStatus, Noise=$_currentNoiseDB',
//     );
//     final newContext = SpatioTemporal.fromRawData(
//       activityStatus: _currentActivityStatus ?? "default emit",
//       timestamp: DateTime.now(),
//       noiseDB: _currentNoiseDB ?? 0.0,
//     );
//     latestContext =
//         newContext; // Tetap perbarui latestContext untuk akses sinkron
//     currentContextNotifier.value = newContext;
//     _contextCtrl.add(newContext); // Emit ke DataAggregationService
//     print(
//       '[$_debugLabel] 📦 Context Emitted: ${newContext.rawActivityStatus} | ${newContext.noiseLeveldB}dB',
//     );
//   }

//   void _onError(dynamic error) {
//     String errorMessage;
//     if (error is PlatformException) {
//       errorMessage = error.message ?? error.code;
//     } else {
//       errorMessage = error.toString();
//     }
//     debugPrint("PhoneSensorService error: $errorMessage");
//   }

//   // void dispose() {
//   //   print('[PhoneSensorService] Disposing...');
//   //   _activitySubscription?.cancel();
//   //   _noiseSubscription?.cancel();
//   //   // _contextCtrl?.cancel();
//   //   _isRecording = false;
//   //   _isInitialized = false;
//   //   print("PhoneSensorService: all streams disposed");
//   // }

//   void stop() {
//     _noiseSubscription?.cancel();
//     _activitySubscription?.cancel();
//     // _contextCtrl.close();
//     _isRecording = false;
//   }

//   // Getters
//   bool get isInitialized => _isInitialized;
//   bool get isRecording => _isRecording;
//   double? get currentNoiseLevel => _currentNoiseDB;
//   SpatioTemporal get currentContext => latestContext;
// }
