import 'package:aura/model/health_day_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:aura/model/health_data.dart';

class StorageHelper {
  static const String _key = 'healthData';
  static const String _permissionKey = 'healthPermissionsKey';
  static const String _groupedKey = 'health_grouped_data';
  static const String _lastUpdatedKey = 'health_data_last_update';

  static Future<List<HealthData>?> loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) {
      return null;
    }
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => HealthData.fromJson(e)).toList();
  }

  static Future<void> saveData(List<HealthData> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(data.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonData);
  }

  static Future<void> permissionGranted(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionKey, granted);
  }

  static Future<bool> isPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionKey) ?? false;
  }

  static Future<void> saveGroupedData(
    Map<String, List<HealthDayData>> grouped,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = grouped.map(
      (k, v) => MapEntry(k, v.map((d) => d.toJson()).toList()),
    );
    await prefs.setString(_groupedKey, jsonEncode(jsonData));
    await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
  }

  static Future<Map<String, List<HealthDayData>>?> loadGroupedData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_groupedKey);
    if (jsonString == null) return null;
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final Map<String, List<HealthDayData>> result = {};
    jsonMap.forEach((k, v) {
      result[k] = (v as List).map((e) => HealthDayData.fromJson(e)).toList();
    });
    return result;
  }

  static Future<DateTime?> getLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdateStr = prefs.getString(_lastUpdatedKey);
    if (lastUpdateStr == null) return null;
    return DateTime.tryParse(lastUpdateStr);
  }
}
