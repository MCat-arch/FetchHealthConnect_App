// providers/health_provider.dart
import 'dart:convert';
import 'package:app_aura/services/health_service.dart';
import 'package:app_aura/utils/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/health_data.dart';

class HealthProvider extends ChangeNotifier {
  List<HealthData> _dailyData = [];

  List<HealthData> get dailyData => _dailyData;

  // void setDailyData(List<HealthData> data) {
  //   _dailyData = data;
  //   saveToLocal();
  //   notifyListeners();
  // }

  // void addDailyData(HealthData data) {
  //   _dailyData.add(data);
  //   saveToLocal();
  //   notifyListeners();
  // }

  Future<void> loadFromLocal() async {
    await HealthService.ensurePermissions();
    final cached = await StorageHelper.loadFromLocal();
    if (cached != null) {
      _dailyData = cached;
    }
    final fetched = await HealthService.fetchData();
    for (var data in fetched) {
      final isExisting = _dailyData.indexWhere((d) => d.id == data.id);
      if (isExisting >= 0) {
        _dailyData[isExisting] = data;
      } else {
        _dailyData.add(data);
      }
    }
    await StorageHelper.saveData(_dailyData);
    notifyListeners();
  }

  // Future<void> saveToLocal() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final jsonString = jsonEncode(_dailyData.map((e) => e.toJson()).toList());
  //   await prefs.setString('daily_health_data', jsonString);
  // }
}
