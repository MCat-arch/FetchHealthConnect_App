// services/ml_panic_service.dart
import 'package:aura_bluetooth/models/heart_rate_model.dart';

// services/ml_panic_service.dart

import 'dart:math';

class MLPanicService {
  static final MLPanicService _instance = MLPanicService._internal();
  factory MLPanicService() => _instance;
  MLPanicService._internal();

  // --- STATISTIK ---
  double? _movingMean;
  double? _movingVariance;
  double _movingStdDev = 0.0;

  // BUFFER KALIBRASI
  // Karena data masuk per 1 menit, kita cukup butuh 3-5 data (3-5 menit) untuk baseline awal.
  final int _minSamplesForCalibration = 10;
  final List<double> _calibrationBuffer = [];

  // Alpha lebih besar karena 1 menit itu perubahan yang signifikan
  final double _alpha = 0.2;

  HeartRateData? _previousData;

  void reset() {
    _movingMean = null;
    _movingVariance = null;
    _movingStdDev = 0.0;
    _calibrationBuffer.clear();
    _previousData = null;
  }

  Future<PanicPrediction> predictPanicAttack(HeartRateData data) async {
    // 1. FILTER: Hanya proses statistik jika diam
    if (!data.phoneSensor.isStill) {
      return _createResult(data, false, 0.0, "Skipped: Moving", 0.0);
    }

    // 2. COLD START 
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

    // 3. SAFETY NET RHR
    // Jika RHR dari history (5 min window) tersedia, gunakan sebagai batas bawah
    if (data.rhr > 0 && _movingMean != null) {
      // Logika: Rata-rata berjalan tidak boleh jauh di bawah RHR historis
      if (_movingMean! < data.rhr - 5) {
        _movingMean = data.rhr; // Reset ke RHR
      }
    }

    // 4. DETEKSI
    final result = _detectAnomaly(data);

    // 5. UPDATE STATS (Hanya jika tidak panic)
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
  }

  // ... (Fungsi _calculateInitialStats sama, tapi pakai data buffer di atas) ...

  void _calculateInitialStats() {
    if (_calibrationBuffer.isEmpty) return;
    double sum = _calibrationBuffer.reduce((a, b) => a + b);
    _movingMean = sum / _calibrationBuffer.length;

    double sumSquaredDiff = 0.0;
    for (var x in _calibrationBuffer) {
      sumSquaredDiff += pow(x - _movingMean!, 2);
    }
    _movingVariance = sumSquaredDiff / _calibrationBuffer.length;
    _movingStdDev = sqrt(_movingVariance!);

    // Safety agar tidak bagi dengan nol
    if (_movingStdDev < 1.0) _movingStdDev = 5.0;
  }

  void _updateStats(double newBpm) {
    if (_movingMean == null) return;
    double diff = newBpm - _movingMean!;
    double increment = _alpha * diff;
    _movingMean = _movingMean! + increment;
    _movingVariance = (1 - _alpha) * (_movingVariance! + _alpha * pow(diff, 2));
    _movingStdDev = sqrt(_movingVariance!);
  }

  Map<String, dynamic> _detectAnomaly(HeartRateData current) {
    if (_movingMean == null) {
      return {
        'isPanic': false,
        'confidence': 0.0,
        'reason': 'No Stats',
        'zScore': 0.0,
      };
    }

    double zScore = (current.bpm - _movingMean!) / _movingStdDev;

    // Hitung Delta dari menit ke menit
    double delta = 0.0;
    if (_previousData != null) {
      delta = (current.bpm - _previousData!.bpm).toDouble();
    }

    bool isPanic = false;
    double confidence = 0.0;
    String reason = "Normal";

    // --- RULES (Disesuaikan untuk data per Menit) ---

    // RMSSD 60s dari HRV Service Anda
    double rmssd = current.HRV60s?.rmssd ?? 100.0;

    // Rule 1: Z-Score Ekstrem
    if (zScore > 3.5) {
      isPanic = true;
      confidence = 0.8;
      reason = "Extreme HR Surge (Z: ${zScore.toStringAsFixed(1)})";
    }
    // Rule 2: Kombinasi HR Tinggi + HRV Rendah (Validasi Kuat)
    else if (zScore > 2.5 && rmssd < 25.0) {
      isPanic = true;
      confidence = 0.9;
      reason = "High HR + Low HRV";
    }
    // Rule 3: Lonjakan Drastis dalam 1 Menit (Sudden Onset)
    // Naik 20 bpm dalam 1 menit saat diam itu mencurigakan
    else if (delta > 20.0 && current.bpm > 90) {
      isPanic = true;
      confidence = 0.7;
      reason = "Sudden Spike (+${delta.toInt()} bpm)";
    }

    return {
      'isPanic': isPanic,
      'confidence': confidence,
      'zScore': zScore,
      'reason': reason,
    };
  }

  PanicPrediction _createResult(
    HeartRateData data,
    bool isPanic,
    double confidence,
    String reason,
    double zScore,
  ) {
    return PanicPrediction(
      isPanic: isPanic,
      confidence: confidence,
      features: {'z_score': zScore, 'baseline': _movingMean, 'reason': reason},
      timestamp: DateTime.now(),
      userFeedback: ''
    );
  }
}

class PanicPrediction {
  final bool isPanic;
  final double confidence;
  final Map<String, dynamic> features;
  final DateTime timestamp;
  final String? userFeedback;

  PanicPrediction({
    required this.isPanic,
    required this.confidence,
    required this.features,
    required this.timestamp,
    this.userFeedback,
  });

  factory PanicPrediction.fromJson(Map<String, dynamic> json) {
    return PanicPrediction(
      isPanic: json['isPanic'] as bool? ?? false,
      confidence: (json['confidence'] as num)?.toDouble() ?? 0.0,
      features: Map<String, dynamic>.from(json['features'] ?? {}),
      timestamp: DateTime.fromMicrosecondsSinceEpoch(
        json['timestamp'] as int ?? DateTime.now().millisecondsSinceEpoch,
      ),
      userFeedback: json['userFeedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPanic': isPanic,
      'confidence': confidence,
      'features': features,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'userFeedback': userFeedback,
    };
  }
}
