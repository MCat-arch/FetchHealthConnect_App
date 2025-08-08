// // home_wrapper.dart
// import 'package:flutter/material.dart';
// import 'package:health/health.dart';
// import 'package:provider/provider.dart';
// import 'package:app_aura/pages/home.dart';
// import 'package:app_aura/providers/health_provider.dart';
// import 'package:app_aura/services/health_service.dart';
// import 'package:app_aura/services/notification_service.dart';

// class HomeWrapper extends StatefulWidget {
//   const HomeWrapper({super.key});

//   @override
//   State<HomeWrapper> createState() => _HomeWrapperState();
// }

// class _HomeWrapperState extends State<HomeWrapper> {
//   final _healthService = HealthService();

//   Future<void> _initialize() async {
//     // 1. Inisialisasi notifikasi
//     await NotificationService().requestPermission();
//     await NotificationService().initNotification();

//     final health = Health();
//     bool available = await health.isHealthConnectAvailable();
//     if (!available) throw Exception('Health Connect not available');

//     bool granted = await health.requestAuthorization(
//       [HealthDataType.HEART_RATE, HealthDataType.STEPS],
//       permissions: [HealthDataAccess.READ, HealthDataAccess.READ],
//     );
//     if (!granted) throw Exception('Permission not granted');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: _initialize(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.done) {
//           return const Home();
//         } else {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
// import 'package:health/health.dart';
import 'package:provider/provider.dart';
import 'package:app_aura/pages/home.dart';
import 'package:app_aura/providers/health_provider.dart';
import 'package:app_aura/services/health_service.dart';
import 'package:app_aura/services/notification_service.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await NotificationService().requestPermission();
        await NotificationService().initNotification();
        // await HealthService.ensurePermission();

        setState(() => _initialized = true);
      } catch (e) {
        setState(() => _error = e.toString());
      }
    });
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
