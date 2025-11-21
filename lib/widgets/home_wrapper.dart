import 'package:aura_bluetooth/services/foreground_service_hr.dart';
import 'package:aura_bluetooth/services/notification_service.dart';
import 'package:aura_bluetooth/services/phone_permission_service.dart';
import 'package:aura_bluetooth/services/setting_service.dart';
import 'package:aura_bluetooth/services/workmanager_service.dart';
import 'package:aura_bluetooth/utils/init.dart' show InitializationManager;
import 'package:aura_bluetooth/views/breathing_page.dart';
import 'package:aura_bluetooth/views/home.dart';
import 'package:aura_bluetooth/views/home_page.dart';
import 'package:aura_bluetooth/views/setting.dart';
import 'package:aura_bluetooth/widgets/navbar.dart';
import 'package:flutter/material.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> with WidgetsBindingObserver {
  bool _initialized = false;
  String? _error;

  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const BreathingGuidePage(),
    const SettingPage(),
  ];

  //initialize
  final ForegroundMonitorService _foregroundMonitorService =
      ForegroundMonitorService();
  final WorkmanagerService _workmanagerService = WorkmanagerService();
  final SettingsService _settingsService = SettingsService();

  bool _isForegroundRunning = false;

  Future<void> _initializeServices() async {
    try {
      // Initialize settings first
      await _settingsService.initialize();

      // Initialize other services based on settings
      await _workmanagerService.initialize();

      // Only start foreground service if enabled in settings
      if (_settingsService.isForegroundServiceEnabled) {
        await _foregroundMonitorService.start();
        setState(() {
          _isForegroundRunning = true;
        });
      }

      print('[HomeWrapper] All services initialized successfully');
    } catch (e) {
      print('[HomeWrapper] Error initializing services: $e');
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    print('HomeWrapper initState called');
    WidgetsBinding.instance.addObserver(this);
    _checkInitialization();
    _initializeServices();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('HomeWrapper: App resumed');
      // Optional: Periksa apakah perlu refresh data
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkInitialization() async {
    if (await InitializationManager.isInitialized()) {
      setState(() => _initialized = true);
    }

    try {
      await NotificationService().requestPermission();
      await NotificationService().initNotification();
      // await HealthDataFetcher().requestRuntimePermissions();
      await PhonePermissionService.requestAllPermission();
      await InitializationManager.setInitialized(); // Tandai inisialisasi selesai
      setState(() => _initialized = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Navbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    ); // langsung masuk ke Home
  }
}
