// views/setting.dart
import 'package:aura_bluetooth/services/setting_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final ForegroundMonitorService _foregroundService =
      ForegroundMonitorService();
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

  Future<void> _updateSetting<T>(
    String settingName,
    T value,
    Function(T) setter,
  ) async {
    await setter(value);
    await _loadSettings();
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings updated')));
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

    // Navigate to login screen automatically handled by GoRouter
    // when auth state changes (if configured in routes.dart)
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings reset to defaults')));
  }

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.blueAccent.shade700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            )
          : null,
      value: value,
      activeColor: Colors.blueAccent,
      onChanged: (newValue) {
        setState(() {
          onChanged(newValue);
        });
      },
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _getSettingIcon(title),
      ),
    );
  }

  Widget _buildListTileSetting(
    String title,
    String subtitle,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _getSettingIcon(title),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            )
          : null,
      trailing:
          trailing ??
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: _loadSettings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          // Profile Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueAccent.withOpacity(0.2),
                  child: const Icon(
                    Icons.person,
                    size: 35,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage your account',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Monitoring Settings
          _buildSettingSection('Monitoring', [
            _buildSwitchSetting(
              'Bluetooth Monitoring',
              'Monitor heart rate from armband',
              _bleEnabled,
              (value) =>
                  _updateSetting('BLE', value, _settingsService.setBLEEnabled),
            ),
            _buildSwitchSetting(
              'Phone Sensors',
              'Use phone sensors for activity and noise detection',
              _sensorsEnabled,
              (value) => _updateSetting(
                'Sensors',
                value,
                _settingsService.setSensorsEnabled,
              ),
            ),
            _buildSwitchSetting(
              'Background Service',
              'Continue monitoring when app is closed',
              _foregroundServiceEnabled,
              (value) => _updateSetting(
                'ForegroundService',
                value,
                _settingsService.setForegroundServiceEnabled,
              ),
            ),
          ]),

          // Alert Settings
          _buildSettingSection('Alerts & Notifications', [
            _buildSwitchSetting(
              'Notifications',
              'Show app notifications',
              _notificationsEnabled,
              (value) => _updateSetting(
                'Notifications',
                value,
                _settingsService.setNotificationsEnabled,
              ),
            ),
            _buildSwitchSetting(
              'Panic Alerts',
              'Alert when panic attack is detected',
              _panicAlertsEnabled,
              (value) => _updateSetting(
                'PanicAlerts',
                value,
                _settingsService.setPanicAlertsEnabled,
              ),
            ),
            _buildSwitchSetting(
              'Vibration',
              'Vibrate on alerts',
              _vibrationEnabled,
              (value) => _updateSetting(
                'Vibration',
                value,
                _settingsService.setVibrationEnabled,
              ),
            ),
            _buildSwitchSetting(
              'Sounds',
              'Play sounds on alerts',
              _soundEnabled,
              (value) => _updateSetting(
                'Sound',
                value,
                _settingsService.setSoundEnabled,
              ),
            ),
          ]),

          // Data Settings
          _buildSettingSection('Data & Sync', [
            _buildSwitchSetting(
              'Auto Sync',
              'Automatically sync data to cloud',
              _autoSyncEnabled,
              (value) => _updateSetting(
                'AutoSync',
                value,
                _settingsService.setAutoSyncEnabled,
              ),
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
          // _buildSettingSection('Account', [
          //   _buildListTileSetting(
          //     'Account',
          //     'Manage your account settings',
          //     () => _showAccountDialog(),
          //   ),
          //   _buildListTileSetting(
          //     'Privacy & Security',
          //     'Data privacy and security settings',
          //     () => _showPrivacyDialog(),
          //   ),
          // ]),

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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _resetSettings,
                    icon: const Icon(Icons.restore),
                    label: const Text(
                      'Reset to Defaults',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      side: const BorderSide(color: Colors.blueAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  _updateSetting(
                    'HRInterval',
                    value,
                    _settingsService.setHRUpdateInterval,
                  );
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
    final themeNames = {
      'system': 'System Default',
      'light': 'Light',
      'dark': 'Dark',
    };

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
        content: const Text(
          'Account management features will be implemented soon.',
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

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Security'),
        content: const Text(
          'Privacy and security settings will be implemented soon.',
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'If you have any problem please contact us at 085806621514 ( WhatsApp )',
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About AURA'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AURA Health Monitor',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version: 1.2.0'),
            Text('Build: 2026.05.01'),
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
