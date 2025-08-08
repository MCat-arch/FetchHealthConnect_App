import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:app_aura/model/health_data.dart';

class StorageHelper {
  static const String _key = 'healthData';

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
}
