import 'package:app_aura/model/health_day_data.dart';
import 'package:flutter/material.dart';

class HealthData extends ChangeNotifier {
  String id;
  String date;
  int panicCount;
  List<HealthDayData> dateData;

  HealthData(this.id, this.date,this.panicCount, this.dateData);
}
