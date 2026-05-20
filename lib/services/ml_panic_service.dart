// services/ml_panic_service.dart
import 'package:aura_bluetooth/models/heart_rate_model.dart';
import 'package:aura_bluetooth/services/backend_service.dart';

class MLPanicService {
  static final MLPanicService _instance = MLPanicService._internal();
  factory MLPanicService() => _instance;
  MLPanicService._internal();

  // Kita biarkan deviceId statis untuk sementara, atau bisa diambil dari setting
  final String _deviceId = 'default_device';

  void reset() {
    // Reset session di backend
    BackendService().resetSession(_deviceId);
  }

  Future<PanicPrediction> predictPanicAttack(HeartRateData data) async {
    // 1. FILTER: Hanya proses jika diam (di backend juga dicek, tapi kita bisa return awal)
    if (!data.phoneSensor.isStill) {
      return PanicPrediction(
        trigger: false,
        pPanic: null,
        status: "Skipped: Moving",
        bpm: data.bpm,
        sdnn: data.HRV60s?.sdnn,
        timestamp: DateTime.now(),
      );
    }

    // 2. Kirim ke Backend API
    return await BackendService().sendPredictionRequest(data, _deviceId);
    
    // --- LOGIKA LAMA (DI-COMMENT) ---
    /*
    if (_calibrationBuffer.length < _minSamplesForCalibration) {
      _calibrationBuffer.add(data.bpm.toDouble());

      if (_calibrationBuffer.length == _minSamplesForCalibration) {
        _calculateInitialStats();
      }
      return _createResult(
        data,
        false,
        0.0,
        "Calibrating (${_calibrationBuffer.length}/$_minSamplesForCalibration min)",
        0.0,
      );
    }

    if (data.rhr > 0 && _movingMean != null) {
      if (_movingMean! < data.rhr - 5) {
        _movingMean = data.rhr;
      }
    }

    final result = _detectAnomaly(data);

    if (!result['isPanic']) {
      _updateStats(data.bpm.toDouble());
    }

    _previousData = data;

    return _createResult(
      data,
      result['isPanic'],
      result['confidence'],
      result['reason'],
      result['zScore'],
    );
    */
  }
}

class PanicPrediction {
  final bool trigger;       // Menggantikan isPanic
  final double? pPanic;     // Menggantikan confidence
  final String status;      // Label human-readable
  final int bpm;
  final double? sdnn;
  final DateTime timestamp; // Frontend-added
  final String? userFeedback;

  PanicPrediction({
    required this.trigger,
    this.pPanic,
    required this.status,
    required this.bpm,
    this.sdnn,
    required this.timestamp,
    this.userFeedback,
  });

  factory PanicPrediction.fromJson(Map<String, dynamic> json) {
    return PanicPrediction(
      trigger: json['trigger'] as bool? ?? false,
      pPanic: json['p_panic'] != null ? (json['p_panic'] as num).toDouble() : null,
      status: json['status'] as String? ?? "Unknown",
      bpm: json['bpm'] as int? ?? 0,
      sdnn: json['sdnn'] != null ? (json['sdnn'] as num).toDouble() : null,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      userFeedback: json['userFeedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trigger': trigger,
      'p_panic': pPanic,
      'status': status,
      'bpm': bpm,
      'sdnn': sdnn,
      'timestamp': timestamp.toIso8601String(),
      'userFeedback': userFeedback,
    };
  }
}
