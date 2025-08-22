import 'package:aura/model/health_day_data.dart';

class HealthData {
  String id;
  String date;
  int panicCount;
  List<HealthDayData> details;

  HealthData(this.id, this.date, this.panicCount, this.details);

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'panicCount': panicCount,
        'details': details.map((e) => e.toJson()).toList(),
      };

  factory HealthData.fromJson(Map<String, dynamic> json) => HealthData(
        json['id'],
        json['date'],
        json['panicCount'],
        (json['details'] as List<dynamic>)
            .map((e) => HealthDayData.fromJson(e))
            .toList(),
      );
}
