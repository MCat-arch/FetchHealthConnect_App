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

  SpatioTemporal? latestContext;
  final ValueNotifier<SpatioTemporal?> currentContextNotifier =
      ValueNotifier<SpatioTemporal?>(null);

  NoiseMeter? noiseMeter;
  bool _isRecording = false;
  double? noiseDB;

  StreamSubscription<Activity>? _activitySubscription;
  StreamSubscription<NoiseReading>? _noiseSubscription;

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

      if (latestContext == null) {
        latestContext = SpatioTemporal.fromRawData(
          activityStatus: "UNKNOWN",
          timestamp: DateTime.now(),
          noiseDB: 0,
        );
        currentContextNotifier.value = latestContext;
      }
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
          noiseDB = reading.meanDecibel;
          _updateNoiseLevel(noiseDB);
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
      final status = activity.type.toString().split('.').last.toUpperCase();
      final now = DateTime.now();

      latestContext = SpatioTemporal.fromRawData(
        activityStatus: status,
        timestamp: now,
        noiseDB: noiseDB,
        // noiseDB: noiseDB ?? 0,
      );
      currentContextNotifier.value = latestContext;

      print('[PhoneSensorService] Activity updated: $status');
    } catch (e) {
      print("[PhoneSensorService] Error updating activity: $e");
    }
  }

  void _updateNoiseLevel(double? dbLevel) {
    try {
      if (latestContext != null && dbLevel != null) {
        latestContext = SpatioTemporal.fromRawData(
          activityStatus: latestContext!.rawActivityStatus,
          timestamp: DateTime.now(),
          noiseDB: dbLevel,
        );
        currentContextNotifier.value = latestContext;
      }
    } catch (e) {
      print("[PhoneSensorService] Error updating noise level: $e");
    }
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
    _isRecording = false;
    _isInitialized = false;
    print("PhoneSensorService: all streams disposed");
  }

  void stop() {
    _noiseSubscription?.cancel();
    _activitySubscription?.cancel();
    _isRecording = false;
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  double? get currentNoiseLevel => noiseDB;
  SpatioTemporal? get currentContext => latestContext;
}

// // services/phone_sensor_service.dart
// import 'dart:async';
// import 'package:aura_bluetooth/models/spatio.model.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
// import 'package:noise_meter/noise_meter.dart';
// import 'package:flutter/material.dart';

// class PhoneSensorService {
//   // FIX: Gunakan static final untuk instance, bukan final di class level
//   static final PhoneSensorService _instance = PhoneSensorService._internal();
//   factory PhoneSensorService() => _instance;

//   PhoneSensorService._internal(); // Private constructor

//   SpatioTemporal? latestContext;
//   final ValueNotifier<SpatioTemporal?> currentContextNotifier =
//       ValueNotifier<SpatioTemporal?>(null);

//   NoiseMeter? noiseMeter;
//   bool _isRecording = false;
//   double? noiseDB;

//   StreamSubscription<Activity>? _activitySubscription;
//   StreamSubscription<NoiseReading>? _noiseSubscription;

//   Future<void> initialize() async {
//     print('[PhoneSensorService] Initializing...');
//     try {
//       await startActivityStream();
//       await startNoiseStream();
//       print("[PhoneSensorService] All contextual streams initialized");
//     } catch (e) {
//       print("[PhoneSensorService] Error initializing: $e");
//     }
//   }

//   void dispose() {
//     _activitySubscription?.cancel();
//     _noiseSubscription?.cancel();
//     print("Phone Sensor service: all stream disposed");
//   }

//   //----------------ACTIVITY STREAM--------------
//   Future<void> startActivityStream() async {
//     try {
//       final activityStream = FlutterActivityRecognition.instance.activityStream
//           .handleError(_onError);
//       _activitySubscription = activityStream.listen((activity) {
//         _updateActivity(activity);
//       });
//     } catch (e) {
//       print("[PhoneSensorService] Error starting activity stream: $e");
//     }
//   }

//   void _updateActivity(Activity activity) {
//     try {
//       final status = activity.type.toString().split('.').last.toUpperCase();
//       final now = DateTime.now();

//       latestContext = SpatioTemporal.fromRawData(
//         activityStatus: status,
//         timestamp: now,
//         noiseDB: noiseDB,
//       );
//       currentContextNotifier.value = latestContext;

//       print('[PhoneSensorService] Activity updated: $status');
//     } catch (e) {
//       print("[PhoneSensorService] Error updating activity: $e");
//     }
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

//   //-------NOISE STREAM-------
//   Future<void> startNoiseStream() async {
//     try {
//       noiseMeter ??= NoiseMeter();
//       _noiseSubscription = noiseMeter!.noise.listen((reading) {
//         noiseDB = reading.meanDecibel;
//         if (latestContext != null) {
//           latestContext = SpatioTemporal.fromRawData(
//             activityStatus: latestContext!.rawActivityStatus,
//             timestamp: DateTime.now(),
//             noiseDB: noiseDB,
//           );
//           currentContextNotifier.value = latestContext;
//         }
//       }, onError: _onError);
//       _isRecording = true;
//     } catch (e) {
//       debugPrint("Error starting noise Stream : $e");
//     }
//   }

//   void stop() {
//     _noiseSubscription?.cancel();
//     _activitySubscription?.cancel();
//     _isRecording = false;
//   }
// }

// // import 'dart:async';

// // import 'package:aura_bluetooth/models/spatio.model.dart';
// // import 'package:flutter/services.dart';
// // import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
// // import 'package:noise_meter/noise_meter.dart';
// // // import 'package:sensors_plus/sensors_plus.dart';
// // import 'package:flutter/material.dart';

// // class PhoneSensorService {
// //   PhoneSensorService._(); // private constructor

// //   static final PhoneSensorService _instance = PhoneSensorService._();

// //   factory PhoneSensorService() => _instance;

// //   // static final PhoneSensorService _instance = PhoneSensorService();
// //   // factory PhoneSensorService() => _instance;
// //   // PhoneSensorService();

// //   SpatioTemporal? latestContext;

// //   // final ValueNotifier<String> _activityResult = ValueNotifier('');
// //   // final ValueNotifier<double> _noiseLevelDB = ValueNotifier(0);
// //   final ValueNotifier<SpatioTemporal?> currentContextNotifier =
// //       ValueNotifier<SpatioTemporal?>(null);

// //   // NoiseReading? _latestReading;
// //   NoiseMeter? noiseMeter;
// //   bool _isRecording = false;
// //   double? noiseDB;

// //   StreamSubscription<Activity>? _activitySubscription;
// //   // StreamSubscription<int>? _lightSubscription;
// //   StreamSubscription<NoiseReading>? _noiseSubscription;

// //   Future<void> initialize() async {
// //     await startActivityStream();
// //     // _startLightStream();
// //     await startNoiseStream();
// //     print("Phoe sensor service: All contextual streams initialized");
// //   }

// //   void dispose() {
// //     _activitySubscription?.cancel();
// //     // _lightSubscription?.cancel();
// //     _noiseSubscription?.cancel();
// //     print("Phone Sensor service: all stream disposed");
// //   }

// //   //----------------ACTIVITY STREAM--------------
// //   Future<void> startActivityStream() async {
// //     final activityStream = FlutterActivityRecognition.instance.activityStream
// //         .handleError(_onError);
// //     _activitySubscription = activityStream.listen((activity) {
// //       _updateActivity(activity);
// //     });
// //     // _activitySubscription = FlutterActivityRecognition.instance.activityStream
// //     //     .handleError(_onError)
// //     //     .listen(_onActivity);
// //   }

// //   void _updateActivity(Activity activity) {
// //     final status = activity.type.toString().split('.').last.toUpperCase();
// //     final now = DateTime.now();

// //     latestContext = SpatioTemporal.fromRawData(
// //       activityStatus: status,
// //       timestamp: now,
// //       noiseDB: noiseDB,
// //     );
// //     currentContextNotifier.value = latestContext;
// //   }

// //   // void _onActivity(Activity activity) {
// //   //   latestContext.rawActivityStatus = _activityResult.value;
// //   // }

// //   void _onError(dynamic error) {
// //     String errorMessage;
// //     if (error is PlatformException) {
// //       errorMessage = error.message ?? error.code;
// //     } else {
// //       errorMessage = error.toString();
// //     }
// //     // return errorMessage;
// //     debugPrint("PhoneSensorService error: $errorMessage");
// //   }

// //   //-------NOISE STREAM-------

// //   // void onData(NoiseReading noiseReading) {
// //   //   _latestReading = noiseReading;
// //   //   double noiseParse = _latestReading.meanDecibel.toDouble(2);
// //   //   latestContext.noiseLeveldB = noiseParse;
// //   // }
// //   // setState(() => {_latestReading = noiseReading});

// //   Future<void> startNoiseStream() async {
// //     noiseMeter ??= NoiseMeter();
// //     try {
// //       _noiseSubscription = noiseMeter!.noise.listen((reading) {
// //         noiseDB = reading.meanDecibel;
// //         // final now = DateTime.now();
// //         if (latestContext != null) {
// //           latestContext = SpatioTemporal.fromRawData(
// //             activityStatus: latestContext!.rawActivityStatus,
// //             timestamp: DateTime.now(),
// //             noiseDB: noiseDB,
// //           );
// //           currentContextNotifier.value = latestContext;
// //         }
// //       }, onError: _onError);
// //       _isRecording = true;
// //     } catch (e) {
// //       debugPrint("Error starting noise Stream : $e");
// //     }
// //     // if (!(await )) {
// //     //   _noiseSubscription? = noiseMeter?.noise.listen(onData, _onError);
// //     //   setState(()=> _isRecording = true);

// //     // }
// //   }

// //   void stop() {
// //     _noiseSubscription?.cancel();
// //     _activitySubscription?.cancel();
// //     _isRecording = false;
// //   }
// // }
