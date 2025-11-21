// services/ml_panic_service.dart
import 'package:aura_bluetooth/models/heart_rate_model.dart';

class MLPanicService {
  static final MLPanicService _instance = MLPanicService._internal();
  factory MLPanicService() => _instance;

  // TODO: Integrasi dengan model SVM yang sudah trained
  // Untuk sekarang kita buat rule-based sebagai placeholder

  MLPanicService._internal();

  /// Feature extraction untuk SVM model
  Map<String, dynamic> _extractFeatures(HeartRateData data) {
    return {
      'bpm': data.bpm,
      'hrv_rmssd': data.HRV60s?.rmssd ?? 0.0,
      'hrv_sdnn': data.HRV60s?.sdnn ?? 0.0,
      'rhr': data.rhr,
      'is_moving': !data.phoneSensor.isStill,
      'noise_level': data.phoneSensor.noiseLeveldB ?? 0.0,
      'time_of_day': data.phoneSensor.timeOfDayCategory,
      'heart_rate_variability': _calculateHRVScore(data),
    };
  }

  double _calculateHRVScore(HeartRateData data) {
    final hrv = data.HRV60s;
    if (hrv == null || hrv.rmssd == null) return 0.0;

    // Simple HRV score calculation (bisa disesuaikan)
    return hrv.rmssd! * (hrv.pnn50 ?? 0.0) / 100.0;
  }

  /// Panic attack prediction (placeholder - ganti dengan model SVM actual)
  Future<PanicPrediction> predictPanicAttack(HeartRateData data) async {
    final features = _extractFeatures(data);

    // TODO: Replace dengan actual SVM model inference
    // Untuk sekarang menggunakan rule-based detection

    final bool isPanic = _ruleBasedPanicDetection(features);
    final double confidence = _calculateConfidence(features);

    return PanicPrediction(
      isPanic: isPanic,
      confidence: confidence,
      features: features,
      timestamp: DateTime.now(),
    );
  }

  bool _ruleBasedPanicDetection(Map<String, dynamic> features) {
    // Rule-based detection (placeholder untuk SVM)
    final highHR = features['bpm'] > 100;
    final lowHRV = features['hrv_rmssd'] < 20.0;
    final highNoise = features['noise_level'] > 80.0;
    final isStill = features['is_moving'] == 'STILL';

    return highHR && lowHRV && highNoise && isStill;
  }

  double _calculateConfidence(Map<String, dynamic> features) {
    // Simple confidence calculation
    double score = 0.0;
    if (features['bpm'] > 100) score += 0.4;
    if (features['hrv_rmssd'] < 20.0) score += 0.4;
    if (features['noise_level'] > 80.0) score += 0.2;

    return score.clamp(0.0, 1.0);
  }
}

class PanicPrediction {
  final bool isPanic;
  final double confidence;
  final Map<String, dynamic> features;
  final DateTime timestamp;

  PanicPrediction({
    required this.isPanic,
    required this.confidence,
    required this.features,
    required this.timestamp,
  });
}
