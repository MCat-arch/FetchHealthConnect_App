// services/statistics_service.dart
import 'package:aura_bluetooth/models/health_statistic.dart';
import 'package:aura_bluetooth/models/spatio.model.dart';
import 'package:hive/hive.dart';
import 'package:aura_bluetooth/models/heart_rate_model.dart';
import 'package:aura_bluetooth/models/hrv_metric.dart';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;

  StatisticsService._internal();

  Future<HealthStatistics> getTodayStatistics() async {
    final box = await Hive.openBox('hr_box');
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final todayData = <HeartRateData>[];

    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data != null && data['timestamp'] != null) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
            data['timestamp'] as int,
          );
          if (timestamp.isAfter(todayStart) && timestamp.isBefore(todayEnd)) {
            final hrData = _convertToHeartRateData(data);
            if (hrData != null) {
              todayData.add(hrData);
            }
          }
        }
      } catch (e) {
        print('[Statistics] Error processing data point: $e');
      }
    }

    return _calculateStatistics(todayData, 'Today');
  }

  Future<HealthStatistics> getWeeklyStatistics() async {
    final box = await Hive.openBox('hr_box');
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));

    final weeklyData = <HeartRateData>[];

    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data != null && data['timestamp'] != null) {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
            data['timestamp'] as int,
          );
          if (timestamp.isAfter(weekStart)) {
            final hrData = _convertToHeartRateData(data);
            if (hrData != null) {
              weeklyData.add(hrData);
            }
          }
        }
      } catch (e) {
        print('[Statistics] Error processing data point: $e');
      }
    }

    return _calculateStatistics(weeklyData, 'Last 7 Days');
  }

  Future<List<DailySummary>> getDailySummaries({int days = 7}) async {
    final box = await Hive.openBox('hr_box');
    final now = DateTime.now();
    final summaries = <DailySummary>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final dayData = <HeartRateData>[];

      for (final key in box.keys) {
        try {
          final data = box.get(key);
          if (data != null && data['timestamp'] != null) {
            final timestamp = DateTime.fromMillisecondsSinceEpoch(
              data['timestamp'] as int,
            );
            if (timestamp.isAfter(dayStart) && timestamp.isBefore(dayEnd)) {
              final hrData = _convertToHeartRateData(data);
              if (hrData != null) {
                dayData.add(hrData);
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      if (dayData.isNotEmpty) {
        final stats = _calculateStatistics(dayData, _formatDate(date));
        summaries.add(
          DailySummary(
            date: date,
            averageHR: stats.averageHR,
            averageHRV: stats.averageHRV,
            maxHR: stats.maxHR,
            minHR: stats.minHR,
            panicEvents: stats.panicEvents,
            dataPoints: dayData.length,
          ),
        );
      }
    }

    return summaries;
  }

  HealthStatistics _calculateStatistics(
    List<HeartRateData> data,
    String period,
  ) {
    if (data.isEmpty) {
      return HealthStatistics.empty(period);
    }

    final heartRates = data.map((d) => d.bpm).toList();
    final hrvValues = data
        .where((d) => d.HRV60s?.rmssd != null)
        .map((d) => d.HRV60s!.rmssd!)
        .toList();

    final avgHR = heartRates.reduce((a, b) => a + b) / heartRates.length;
    final double avgHRV = hrvValues.isNotEmpty
        ? hrvValues.reduce((a, b) => a + b) / hrvValues.length
        : 0;

    // Calculate panic events (simplified - you can enhance this)
    final panicEvents = data
        .where((d) => d.bpm > 100 && (d.HRV60s?.rmssd ?? 50) < 30)
        .length;

    // Calculate stress level based on HRV
    final stressLevel = _calculateStressLevel(avgHRV);

    // Calculate recovery score
    final recoveryScore = _calculateRecoveryScore(avgHR, avgHRV, data.length);

    // Get activity distribution
    final activityDistribution = _calculateActivityDistribution(data);

    return HealthStatistics(
      period: period,
      averageHR: avgHR.round(),
      averageHRV: avgHRV,
      maxHR: heartRates.reduce((a, b) => a > b ? a : b),
      minHR: heartRates.reduce((a, b) => a < b ? a : b),
      hrvSDNN: _calculateAverageSDNN(data),
      hrvRMSSD: avgHRV,
      panicEvents: panicEvents,
      dataPoints: data.length,
      stressLevel: stressLevel,
      recoveryScore: recoveryScore,
      activityDistribution: activityDistribution,
      restingHR: _calculateRestingHR(data),
      hrvConsistency: _calculateHRVConsistency(data),
    );
  }

  String _calculateStressLevel(double hrv) {
    if (hrv > 60) return 'Low';
    if (hrv > 40) return 'Moderate';
    if (hrv > 20) return 'High';
    return 'Very High';
  }

  double _calculateRecoveryScore(double avgHR, double avgHRV, int dataPoints) {
    // Simplified recovery score calculation
    final hrScore = (180 - avgHR) / 180 * 50; // Max 50 points
    final hrvScore = (avgHRV / 100) * 30; // Max 30 points
    final dataScore = (dataPoints / 100) * 20; // Max 20 points

    return (hrScore + hrvScore + dataScore).clamp(0, 100);
  }

  double _calculateAverageSDNN(List<HeartRateData> data) {
    final sdnnValues = data
        .where((d) => d.HRV60s?.sdnn != null)
        .map((d) => d.HRV60s!.sdnn!)
        .toList();

    return sdnnValues.isNotEmpty
        ? sdnnValues.reduce((a, b) => a + b) / sdnnValues.length
        : 0;
  }

  double _calculateRestingHR(List<HeartRateData> data) {
    final restingData = data.where((d) => d.phoneSensor.isStill).toList();
    if (restingData.isEmpty) return 0;

    final restingHR = restingData.map((d) => d.bpm).toList();
    return restingHR.reduce((a, b) => a + b) / restingHR.length;
  }

  double _calculateHRVConsistency(List<HeartRateData> data) {
    final hrvValues = data
        .where((d) => d.HRV60s?.rmssd != null)
        .map((d) => d.HRV60s!.rmssd!)
        .toList();

    if (hrvValues.length < 2) return 0;

    final mean = hrvValues.reduce((a, b) => a + b) / hrvValues.length;
    final variance =
        hrvValues.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
        hrvValues.length;
    final stdDev = sqrT(variance.toInt());

    // Consistency score: higher when stdDev is lower relative to mean
    return (1 - (stdDev / mean)).clamp(0, 1) * 100;
  }

  int sqrT(int num) {
    return num * num;
  }

  Map<String, double> _calculateActivityDistribution(List<HeartRateData> data) {
    final activities = {
      'Still': 0.0,
      'Walking': 0.0,
      'Running': 0.0,
      'Other': 0.0,
    };

    for (final d in data) {
      if (d.phoneSensor.isStill) {
        activities['Still'] = activities['Still']! + 1;
      } else if (d.phoneSensor.isWalking) {
        activities['Walking'] = activities['Walking']! + 1;
      } else if (d.phoneSensor.isRunning) {
        activities['Running'] = activities['Running']! + 1;
      } else {
        activities['Other'] = activities['Other']! + 1;
      }
    }

    // Convert to percentages
    final total = data.length.toDouble();
    if (total > 0) {
      for (final key in activities.keys) {
        activities[key] = (activities[key]! / total) * 100;
      }
    }

    return activities;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
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
      return null;
    }
  }
}
