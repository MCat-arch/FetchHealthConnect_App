import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:aura/model/health_data.dart';

class StorageHelper {
  static const String _key = 'healthData';
  static const String _permissionKey = 'healthPermissionsKey';

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
}
