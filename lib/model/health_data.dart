import 'package:aura/model/health_day_data.dart';

class HealthData {
  String id;
  String date;
  int panicCount;
  List<HealthDayData> details;

  HealthData({
    required this.id,
    required this.date,
    this.panicCount = 0,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'panicCount': panicCount,
  };

  factory HealthData.fromJson(
    Map<String, dynamic> json, {
    List<HealthDayData>? details,
  }) {
    return HealthData(
      id: json['id'],
      date: json['date'],
      panicCount: json['panicCount'] ?? 0,
      details: details ?? [],
    );
  }
}
