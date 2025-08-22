import 'package:shared_preferences/shared_preferences.dart';

class InitializationManager {
  static const String _initKey = 'is_init';

  static Future<bool> isInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_initKey) ?? false;
  }

  static Future<void> setInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_initKey, true);
  }
}
