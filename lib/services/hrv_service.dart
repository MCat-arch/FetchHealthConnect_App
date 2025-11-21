// lib/services/hrv_service.dart
import 'dart:math';

import 'package:aura_bluetooth/models/hrv_metric.dart';


class HRVService {
  /// internal store of RR intervals as pairs (timestampMillis, rrMs)
  final List<Map<String, dynamic>> _rrList = [];

  /// Add RR interval (ms). timestampMillis = epoch ms when RR interval occurred (end time of interval).
  void addRR(double rrMs, int timestampMillis) {
    // keep sorted by timestamp (append if increasing)
    _rrList.add({'t': timestampMillis, 'rr': rrMs});
    // Optional: prune old data > longest window (e.g. keep last 5 minutes)
    final int keepWindowMs = 5 * 60 * 1000; // 5 minutes
    final int cutoff = timestampMillis - keepWindowMs;
    _rrList.removeWhere((e) => e['t'] < cutoff);
  }

  /// Helper: get filtered RR list (ms) for last [windowSeconds] seconds relative to now (or use provided nowMs)
  List<double> _getRRsInWindow(int windowSeconds, {int? nowMs}) {
    final int now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final int cutoff = now - windowSeconds * 1000;
    // keep chronological order
    final rrs = _rrList.where((e) => (e['t'] as int) >= cutoff).map<double>((e) => e['rr'] as double).toList();
    return rrs;
  }

  /// Compute metrics for given windowSeconds. Returns HRVMetrics (fields null if not enough data)
  HRVMetrics computeMetrics(int windowSeconds, {int? nowMs}) {
    final rrs = _getRRsInWindow(windowSeconds, nowMs: nowMs);
    final int n = rrs.length;

    if (n == 0) {
      return HRVMetrics(count: 0, meanRR: null, sdnn: null, rmssd: null, nn50: null, pnn50: null);
    }

    // mean RR
    double meanRR = 0.0;
    for (var v in rrs) {
      meanRR += v;
    }
    meanRR = meanRR / n;

    // SDNN (sample std: divide by n-1). If n == 1 => sdnn = null
    double? sdnn;
    if (n > 1) {
      double ssum = 0.0;
      for (var v in rrs) {
        final diff = v - meanRR;
        ssum += diff * diff;
      }
      sdnn = sqrt(ssum / (n - 1));
    } else {
      sdnn = null;
    }

    // RMSSD: successive differences. need at least 2 RR (n >= 2) to have one diff.
    double? rmssd;
    int? nn50;
    double? pnn50;
    if (n > 1) {
      final List<double> diffs = [];
      for (int i = 0; i < n - 1; i++) {
        final d = rrs[i + 1] - rrs[i];
        diffs.add(d);
      }

      // RMSSD
      double sumSq = 0.0;
      for (var d in diffs) {
        sumSq += d * d;
      }
      rmssd = sqrt(sumSq / diffs.length); // denominator = N-1

      // NN50 and pNN50
      int countNN50 = 0;
      for (var d in diffs) {
        if (d.abs() > 50.0) countNN50++;
      }
      nn50 = countNN50;
      pnn50 = (nn50 / diffs.length) * 100.0;
    } else {
      rmssd = null;
      nn50 = null;
      pnn50 = null;
    }

    return HRVMetrics(
      count: n,
      meanRR: meanRR,
      sdnn: sdnn,
      rmssd: rmssd,
      nn50: nn50,
      pnn50: pnn50,
    );
  }

  /// Compute for windows 10s, 30s, 60s. Returns map windowSeconds -> HRVMetrics.
  Map<int, HRVMetrics> computeForStandardWindows({int? nowMs}) {
    return {
      10: computeMetrics(10, nowMs: nowMs),
      30: computeMetrics(30, nowMs: nowMs),
      60: computeMetrics(60, nowMs: nowMs),
    };
  }

  /// Optional: clear stored RR
  void clear() => _rrList.clear();

  /// Expose internal list (read-only copy) for debugging
  List<Map<String, dynamic>> get rrStorage => List.unmodifiable(_rrList);
}
