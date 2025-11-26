import 'package:aura_bluetooth/services/foreground_service_hr.dart';
import 'package:aura_bluetooth/services/notification_service.dart';
import 'package:aura_bluetooth/services/phone_permission_service.dart';
import 'package:aura_bluetooth/services/setting_service.dart';
import 'package:aura_bluetooth/services/workmanager_service.dart';
import 'package:aura_bluetooth/utils/init.dart' show InitializationManager;
import 'package:aura_bluetooth/views/breathing_page.dart';
import 'package:aura_bluetooth/views/home_page.dart';
import 'package:aura_bluetooth/views/setting.dart';
import 'package:aura_bluetooth/widgets/navbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  bool _isForegroundRunning = false;

  @override
  void initState() {
    super.initState();
    print('HomeWrapper initState called');
    WidgetsBinding.instance.addObserver(this);
    _checkInitialization();
    // Tunggu sampai build selesai baru inisialisasi services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    try {
      print('[HOMEWRAPPER] Starting app');
      print('[HomeWrapper] Requesting permissions...');
      await PhonePermissionService.requestAllPermission();
      await context.read<NotificationService>().requestPermission();
      await context.read<NotificationService>().initNotification();

      if (!mounted) return; // Cek mounted setelah await
      final settingsService = context.read<SettingsService>();
      // final workmanagerService = context.read<WorkmanagerService>();
      final foregroundService = context.read<ForegroundMonitorService>();
      // 3. Initialize Logic Services
      print('[HomeWrapper] Initializing Logic Services...');
      // await workmanagerService.initialize();
      print('[HomeWrapper] Initializing Workamanger Services success');
      await settingsService.initialize();

      if (settingsService.isForegroundServiceEnabled) {
        print('[HomeWrapper] Starting Foreground Service...');
        // Pastikan init konfigurasi dipanggil dulu (aman dipanggil ulang)
        await foregroundService.init();
        await foregroundService.start();
      }

      // 5. Selesai! Tampilkan UI Utama
      print('[HomeWrapper] ✅ Bootstrap Complete. App is Ready.');
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e, stack) {
      print('[HomeWrapper] ❌ Bootstrap Error: $e');
      print(stack);
      if (mounted) {
        setState(() {
          _error = "Gagal memuat aplikasi: $e";
        });
      }
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('HomeWrapper: App resumed');
      // Optional: Periksa apakah perlu refresh data
    }
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
    // 1. Tampilkan Error jika ada
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _initializeServices(); // Coba lagi
                },
                child: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Tampilkan Loading Screen selama Bootstrap berjalan
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                "Menyiapkan Monitor Kesehatan...",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Tampilkan UI Utama setelah siap
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Navbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
