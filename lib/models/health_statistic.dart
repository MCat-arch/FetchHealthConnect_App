class HealthStatistics {
  final String period;
  final int averageHR;
  final double averageHRV;
  final int maxHR;
  final int minHR;
  final double hrvSDNN;
  final double hrvRMSSD;
  final int panicEvents;
  final int dataPoints;
  final String stressLevel;
  final double recoveryScore;
  final Map<String, double> activityDistribution;
  final double restingHR;
  final double hrvConsistency;

  HealthStatistics({
    required this.period,
    required this.averageHR,
    required this.averageHRV,
    required this.maxHR,
    required this.minHR,
    required this.hrvSDNN,
    required this.hrvRMSSD,
    required this.panicEvents,
    required this.dataPoints,
    required this.stressLevel,
    required this.recoveryScore,
    required this.activityDistribution,
    required this.restingHR,
    required this.hrvConsistency,
  });

  factory HealthStatistics.empty(String period) {
    return HealthStatistics(
      period: period,
      averageHR: 0,
      averageHRV: 0,
      maxHR: 0,
      minHR: 0,
      hrvSDNN: 0,
      hrvRMSSD: 0,
      panicEvents: 0,
      dataPoints: 0,
      stressLevel: 'Unknown',
      recoveryScore: 0,
      activityDistribution: {},
      restingHR: 0,
      hrvConsistency: 0,
    );
  }
}

class DailySummary {
  final DateTime date;
  final int averageHR;
  final double averageHRV;
  final int maxHR;
  final int minHR;
  final int panicEvents;
  final int dataPoints;

  DailySummary({
    required this.date,
    required this.averageHR,
    required this.averageHRV,
    required this.maxHR,
    required this.minHR,
    required this.panicEvents,
    required this.dataPoints,
  });
}