// services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Setting keys
  static const String _bleEnabledKey = 'ble_enabled';
  static const String _sensorsEnabledKey = 'sensors_enabled';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _panicAlertsEnabledKey = 'panic_alerts_enabled';
  static const String _autoSyncEnabledKey = 'auto_sync_enabled';
  static const String _foregroundServiceEnabledKey =
      'foreground_service_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _themeModeKey = 'theme_mode';
  static const String _servicesInitializedKey = 'services_initialized';
  static const String _hrUpdateIntervalKey = 'hr_update_interval';
  static const String _firstLaunchKey = 'first_launch';
  static const String _lastInitializationTimeKey = 'last_initialization_time';
  static const String _appVersionKey = 'app_version';

  SettingsService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  // Getters with defaults
  bool get isBLEEnabled => _prefs.getBool(_bleEnabledKey) ?? true;
  bool get areSensorsEnabled => _prefs.getBool(_sensorsEnabledKey) ?? true;
  bool get areNotificationsEnabled =>
      _prefs.getBool(_notificationsEnabledKey) ?? true;
  bool get arePanicAlertsEnabled =>
      _prefs.getBool(_panicAlertsEnabledKey) ?? true;
  bool get isAutoSyncEnabled => _prefs.getBool(_autoSyncEnabledKey) ?? true;
  bool get isForegroundServiceEnabled =>
      _prefs.getBool(_foregroundServiceEnabledKey) ?? true;
  bool get isVibrationEnabled => _prefs.getBool(_vibrationEnabledKey) ?? true;
  bool get isSoundEnabled => _prefs.getBool(_soundEnabledKey) ?? true;
  String get themeMode => _prefs.getString(_themeModeKey) ?? 'system';
  int get hrUpdateInterval =>
      _prefs.getInt(_hrUpdateIntervalKey) ?? 5; // seconds

  // Setters
  Future<void> setBLEEnabled(bool value) async {
    await _prefs.setBool(_bleEnabledKey, value);
  }

  Future<void> setSensorsEnabled(bool value) async {
    await _prefs.setBool(_sensorsEnabledKey, value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(_notificationsEnabledKey, value);
  }

  Future<void> setPanicAlertsEnabled(bool value) async {
    await _prefs.setBool(_panicAlertsEnabledKey, value);
  }

  Future<void> setAutoSyncEnabled(bool value) async {
    await _prefs.setBool(_autoSyncEnabledKey, value);
  }

  Future<void> setForegroundServiceEnabled(bool value) async {
    await _prefs.setBool(_foregroundServiceEnabledKey, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _prefs.setBool(_vibrationEnabledKey, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool(_soundEnabledKey, value);
  }

  Future<void> setThemeMode(String value) async {
    await _prefs.setString(_themeModeKey, value);
  }

  Future<void> setHRUpdateInterval(int seconds) async {
    await _prefs.setInt(_hrUpdateIntervalKey, seconds);
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs.remove(_bleEnabledKey);
    await _prefs.remove(_sensorsEnabledKey);
    await _prefs.remove(_notificationsEnabledKey);
    await _prefs.remove(_panicAlertsEnabledKey);
    await _prefs.remove(_autoSyncEnabledKey);
    await _prefs.remove(_foregroundServiceEnabledKey);
    await _prefs.remove(_vibrationEnabledKey);
    await _prefs.remove(_soundEnabledKey);
    await _prefs.remove(_themeModeKey);
    await _prefs.remove(_hrUpdateIntervalKey);
  }

  // Get all settings as map (for debugging)
  Map<String, dynamic> getAllSettings() {
    return {
      'ble_enabled': isBLEEnabled,
      'sensors_enabled': areSensorsEnabled,
      'notifications_enabled': areNotificationsEnabled,
      'panic_alerts_enabled': arePanicAlertsEnabled,
      'auto_sync_enabled': isAutoSyncEnabled,
      'foreground_service_enabled': isForegroundServiceEnabled,
      'vibration_enabled': isVibrationEnabled,
      'sound_enabled': isSoundEnabled,
      'theme_mode': themeMode,
      'hr_update_interval': hrUpdateInterval,
    };
  }
}
