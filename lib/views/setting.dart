// views/setting.dart
import 'package:aura_bluetooth/services/setting_service.dart';
import 'package:flutter/material.dart';
import '../services/foreground_service_hr.dart';
import '../services/ble_service.dart';
import '../services/phone_sensor_service.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final SettingsService _settingsService = SettingsService();
  final ForegroundMonitorService _foregroundService = ForegroundMonitorService();
  final BLEService _bleService = BLEService();
  final PhoneSensorService _phoneSensorService = PhoneSensorService();

  late bool _bleEnabled;
  late bool _sensorsEnabled;
  late bool _notificationsEnabled;
  late bool _panicAlertsEnabled;
  late bool _autoSyncEnabled;
  late bool _foregroundServiceEnabled;
  late bool _vibrationEnabled;
  late bool _soundEnabled;
  late String _themeMode;
  late int _hrUpdateInterval;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsService.initialize();
    
    setState(() {
      _bleEnabled = _settingsService.isBLEEnabled;
      _sensorsEnabled = _settingsService.areSensorsEnabled;
      _notificationsEnabled = _settingsService.areNotificationsEnabled;
      _panicAlertsEnabled = _settingsService.arePanicAlertsEnabled;
      _autoSyncEnabled = _settingsService.isAutoSyncEnabled;
      _foregroundServiceEnabled = _settingsService.isForegroundServiceEnabled;
      _vibrationEnabled = _settingsService.isVibrationEnabled;
      _soundEnabled = _settingsService.isSoundEnabled;
      _themeMode = _settingsService.themeMode;
      _hrUpdateInterval = _settingsService.hrUpdateInterval;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting<T>(String settingName, T value, Function(T) setter) async {
    await setter(value);
    // Apply changes immediately
    await _applySettingsChanges();
  }

  Future<void> _applySettingsChanges() async {
    // Apply BLE setting
    if (!_bleEnabled && _bleService.isConnected) {
      await _bleService.disconnect();
    } else if (_bleEnabled && !_bleService.isConnected) {
      await _bleService.startScan();
    }

    // Apply sensor setting
    if (!_sensorsEnabled) {
      _phoneSensorService.stop();
    } else {
      await _phoneSensorService.initialize();
    }

    // Apply foreground service setting
    if (!_foregroundServiceEnabled && _foregroundService.isRunning) {
      await _foregroundService.stop();
    } else if (_foregroundServiceEnabled && !_foregroundService.isRunning) {
      await _foregroundService.start();
    }

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings updated')),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    // Stop all services
    await _foregroundService.stop();
    await _bleService.disconnect();
    _phoneSensorService.stop();

    // Navigate to login screen (you'll need to implement this)
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );
  }

  Future<void> _resetSettings() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Reset all settings to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performReset();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _performReset() async {
    await _settingsService.resetToDefaults();
    await _loadSettings(); // Reload with default values
    await _applySettingsChanges();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings reset to defaults')),
    );
  }

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      value: value,
      onChanged: (newValue) {
        setState(() {
          onChanged(newValue);
        });
      },
      secondary: _getSettingIcon(title),
    );
  }

  Widget _buildListTileSetting(String title, String subtitle, VoidCallback onTap, {Widget? trailing}) {
    return ListTile(
      leading: _getSettingIcon(title),
      title: Text(title),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Icon _getSettingIcon(String title) {
    switch (title) {
      case 'Bluetooth Monitoring':
        return const Icon(Icons.bluetooth);
      case 'Phone Sensors':
        return const Icon(Icons.phone_android);
      case 'Notifications':
        return const Icon(Icons.notifications);
      case 'Panic Alerts':
        return const Icon(Icons.warning);
      case 'Auto Sync':
        return const Icon(Icons.cloud_sync);
      case 'Background Service':
        return const Icon(Icons.design_services_rounded);
      case 'Vibration':
        return const Icon(Icons.vibration);
      case 'Sounds':
        return const Icon(Icons.volume_up);
      case 'Theme':
        return const Icon(Icons.palette);
      case 'HR Update Interval':
        return const Icon(Icons.timer);
      case 'Account':
        return const Icon(Icons.person);
      case 'Privacy & Security':
        return const Icon(Icons.security);
      case 'Help & Support':
        return const Icon(Icons.help);
      case 'About':
        return const Icon(Icons.info);
      default:
        return const Icon(Icons.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Monitoring Settings
          _buildSettingSection('Monitoring', [
            _buildSwitchSetting(
              'Bluetooth Monitoring',
              'Monitor heart rate from armband',
              _bleEnabled,
              (value) => _updateSetting('BLE', value, _settingsService.setBLEEnabled),
            ),
            _buildSwitchSetting(
              'Phone Sensors',
              'Use phone sensors for activity and noise detection',
              _sensorsEnabled,
              (value) => _updateSetting('Sensors', value, _settingsService.setSensorsEnabled),
            ),
            _buildSwitchSetting(
              'Background Service',
              'Continue monitoring when app is closed',
              _foregroundServiceEnabled,
              (value) => _updateSetting('ForegroundService', value, _settingsService.setForegroundServiceEnabled),
            ),
          ]),

          // Alert Settings
          _buildSettingSection('Alerts & Notifications', [
            _buildSwitchSetting(
              'Notifications',
              'Show app notifications',
              _notificationsEnabled,
              (value) => _updateSetting('Notifications', value, _settingsService.setNotificationsEnabled),
            ),
            _buildSwitchSetting(
              'Panic Alerts',
              'Alert when panic attack is detected',
              _panicAlertsEnabled,
              (value) => _updateSetting('PanicAlerts', value, _settingsService.setPanicAlertsEnabled),
            ),
            _buildSwitchSetting(
              'Vibration',
              'Vibrate on alerts',
              _vibrationEnabled,
              (value) => _updateSetting('Vibration', value, _settingsService.setVibrationEnabled),
            ),
            _buildSwitchSetting(
              'Sounds',
              'Play sounds on alerts',
              _soundEnabled,
              (value) => _updateSetting('Sound', value, _settingsService.setSoundEnabled),
            ),
          ]),

          // Data Settings
          _buildSettingSection('Data & Sync', [
            _buildSwitchSetting(
              'Auto Sync',
              'Automatically sync data to cloud',
              _autoSyncEnabled,
              (value) => _updateSetting('AutoSync', value, _settingsService.setAutoSyncEnabled),
            ),
            _buildListTileSetting(
              'HR Update Interval',
              'Current: $_hrUpdateInterval seconds',
              () => _showIntervalDialog(),
              trailing: Text('${_hrUpdateInterval}s'),
            ),
          ]),

          // Appearance Settings
          _buildSettingSection('Appearance', [
            _buildListTileSetting(
              'Theme',
              'Current: ${_themeMode.replaceAll('_', ' ').toTitleCase()}',
              () => _showThemeDialog(),
              trailing: Text(_themeMode.replaceAll('_', ' ').toTitleCase()),
            ),
          ]),

          // Account Settings
          _buildSettingSection('Account', [
            _buildListTileSetting(
              'Account',
              'Manage your account settings',
              () => _showAccountDialog(),
            ),
            _buildListTileSetting(
              'Privacy & Security',
              'Data privacy and security settings',
              () => _showPrivacyDialog(),
            ),
          ]),

          // Support Settings
          _buildSettingSection('Support', [
            _buildListTileSetting(
              'Help & Support',
              'Get help and support',
              () => _showHelpDialog(),
            ),
            _buildListTileSetting(
              'About',
              'App version and information',
              () => _showAboutDialog(),
            ),
          ]),

          // Action Buttons
          _buildSettingSection('Actions', [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetSettings,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset to Defaults'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ]),

          const SizedBox(height: 20),

          // Debug info (only in debug mode)
          if (!const bool.fromEnvironment('dart.vm.product'))
            _buildSettingSection('Debug Info', [
              Text(
                'Settings: ${_settingsService.getAllSettings()}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ]),
        ],
      ),
    );
  }

  Future<void> _showIntervalDialog() async {
    final intervals = [1, 2, 5, 10, 15, 30];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HR Update Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            return RadioListTile<int>(
              title: Text('$interval seconds'),
              value: interval,
              groupValue: _hrUpdateInterval,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  setState(() {
                    _hrUpdateInterval = value;
                  });
                  _updateSetting('HRInterval', value, _settingsService.setHRUpdateInterval);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _showThemeDialog() async {
    final themes = ['system', 'light', 'dark'];
    final themeNames = {'system': 'System Default', 'light': 'Light', 'dark': 'Dark'};
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.map((theme) {
            return RadioListTile<String>(
              title: Text(themeNames[theme] ?? theme),
              value: theme,
              groupValue: _themeMode,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  setState(() {
                    _themeMode = value;
                  });
                  _updateSetting('Theme', value, _settingsService.setThemeMode);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account'),
        content: const Text('Account management features will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Text('Privacy and security settings will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text('Help and support features will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About AURA'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AURA Health Monitor', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            Text('Build: 2024.01.01'),
            SizedBox(height: 12),
            Text('Panic attack detection and health monitoring app.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Extension untuk string capitalization
extension StringExtension on String {
  String toTitleCase() {
    if (length <= 1) return toUpperCase();
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}