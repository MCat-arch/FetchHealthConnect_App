import 'dart:math';

import 'package:aura_bluetooth/models/heart_rate_model.dart';

import '../models/spatio.model.dart';

class RHRService {
  /// Compute resting HR from last N heart rate samples
  /// Only considers samples where phoneSensor.isStill == true
  double? computeRHR(List<HeartRateData> data, {int windowMinutes = 10}) {
    if (data.isEmpty) return null;

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(minutes: windowMinutes));

    final restingSamples = data
        .where(
          (d) =>
              d.timestamp.isAfter(cutoff) &&
              d.phoneSensor.isStill &&
              d.bpm > 30 &&
              d.bpm <= 120,
        )
        .map((d) => d.bpm)
        .toList();

    if (restingSamples.length < 7) return null; // not enough data
    restingSamples.sort();

    double rhr;
    final int middle = restingSamples.length ~/ 2;

    if (restingSamples.length % 2 == 1) {
      // Ganjil: Ambil nilai tengah
      rhr = restingSamples[middle].toDouble();
    } else {
      // Genap: Rata-rata dua nilai tengah
      rhr = (restingSamples[middle - 1] + restingSamples[middle]) / 2.0;
    }

    return rhr;
  }

  /// Optionally: lowest 1-minute rolling mean of still data (more stable RHR)
  static double? computeStableRHR(List<HeartRateData> data) {
    final still = data.where((d) => d.phoneSensor.isStill).toList();
    if (still.length < 10) return null;

    still.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    double? lowestMean;
    const window = Duration(minutes: 1);

    for (int i = 0; i < still.length; i++) {
      final start = still[i].timestamp;
      final segment = still
          .where(
            (s) =>
                s.timestamp.isAfter(start) &&
                s.timestamp.isBefore(start.add(window)),
          )
          .toList();
      if (segment.length < 3) continue;
      final mean =
          segment.map((s) => s.bpm).reduce((a, b) => a + b) / segment.length;
      lowestMean = (lowestMean == null) ? mean : min(lowestMean!, mean);
    }

    return lowestMean;
  }
}
