import 'dart:async';
import 'package:aura_bluetooth/services/workmanager_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

// Imports services & views
import 'package:aura_bluetooth/services/foreground_service_hr.dart';
import 'package:aura_bluetooth/services/notification_service.dart';
import 'package:aura_bluetooth/services/phone_permission_service.dart';
import 'package:aura_bluetooth/services/setting_service.dart';
import 'package:aura_bluetooth/utils/init.dart' show InitializationManager;
import 'package:aura_bluetooth/views/breathing_page.dart';
import 'package:aura_bluetooth/views/home_page.dart';
import 'package:aura_bluetooth/views/setting.dart';
import 'package:aura_bluetooth/widgets/navbar.dart';
import 'package:aura_bluetooth/widgets/validation_page.dart';

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

  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    print('[HomeWrapper] initState called');
    WidgetsBinding.instance.addObserver(this);

    // Gunakan postFrameCallback agar context siap digunakan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapApp();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('[HomeWrapper] App resumed');
      // Optional: Refresh data jika perlu
    }
  }

  // --- LOGIC UTAMA: BOOTSTRAP (Gabungan Init) ---
  Future<void> _bootstrapApp() async {
    try {
      print('[HomeWrapper] 🚀 Starting Bootstrap...');

      // 1. Request Permissions
      await PhonePermissionService.requestAllPermission();
      await WorkmanagerService().initialize();
      await WorkmanagerService().registerPeriodicTask();

      final notificationService = context.read<NotificationService>();
      await notificationService.requestPermission();
      await notificationService.initNotification();

      if (!mounted) return;

      // 2. Init Services lain (Settings, dll)
      final settingsService = context.read<SettingsService>();
      final foregroundService = context.read<ForegroundMonitorService>();

      await settingsService.initialize();

      // 3. Cek Status Foreground Service
      if (settingsService.isForegroundServiceEnabled) {
        print('[HomeWrapper] Starting Foreground Service...');
        await foregroundService.init();
        await foregroundService.start();
      }

      // 4. Update status Initialization Manager (jika perlu untuk onboarding)
      await InitializationManager.setInitialized();

      // 5. Setup Notification Listeners
      _setupNotificationListeners(notificationService);

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

  // --- LOGIC NOTIFIKASI ---

  void _setupNotificationListeners(NotificationService notificationService) {
    // A. Cek jika aplikasi dibuka dari notifikasi (Terminated State)
    _checkTerminatedNotification();

    // B. Listen jika notifikasi diklik saat aplikasi jalan (Stream)
    _notificationSubscription = notificationService.onNotificationClick.listen((
      payload,
    ) {
      if (mounted) {
        _handleNotificationPayload(payload);
      }
    });
  }

  void _checkTerminatedNotification() async {
    final details = await NotificationService.notification
        .getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      final payload = details.notificationResponse?.payload;
      print(
        "[HomeWrapper] 🚀 App launched from notification payload: $payload",
      );
      _handleNotificationPayload(payload);
    }
  }

  void _handleNotificationPayload(String? payload) {
    print("[HomeWrapper] 🔔 Notification clicked with payload: $payload");
    if (payload != null) {
      _navigateToValidation(payload);
    } else {
      print("[HomeWrapper] ⚠️ Invalid Payload Format");
    }
  }

  // Fungsi dipindah ke sini (Level Class), bukan di dalam build
  void _navigateToValidation(String payload) {
    Navigator.push(
      context, // Context aman karena kita di dalam State class
      MaterialPageRoute(
        builder: (context) => ValidationPage(eventTimestamp: payload),
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _setupForegroundTaskListener() {
    FlutterForegroundTask.receivePort?.listen((msg) {
      if (msg is Map && msg['event'] == 'PANIC_DETECTED') {
        print("[HomeWrapper] 🚨 Realtime Panic Event Received!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Panic Detected"),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'VALIDATE',
              textColor: Colors.white,
              onPressed: () => _navigateToValidation(msg['timestamp']),
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    });
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    // 1. Tampilkan Error
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
                  _bootstrapApp(); // Coba lagi
                },
                child: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Loading Screen
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

    // 3. UI Utama
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Navbar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
