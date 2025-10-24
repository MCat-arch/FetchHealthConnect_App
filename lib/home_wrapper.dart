import 'package:aura/services/health_data_fetcher.dart';
import 'package:aura/utils/init.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aura/pages/home.dart';
import 'package:aura/providers/health_provider.dart';
import 'package:aura/services/health_service.dart';
import 'package:aura/services/notification_service.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> with WidgetsBindingObserver {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('HomeWrapper initState called');
    WidgetsBinding.instance.addObserver(this);
    _checkInitialization();
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
      await HealthDataFetcher().requestRuntimePermissions();
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
    return const Home(); // langsung masuk ke Home
  }
}
