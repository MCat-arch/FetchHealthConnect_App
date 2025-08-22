import 'package:aura/pages/home.dart';
import 'package:aura/pages/manual_label.dart';
import 'package:aura/providers/health_provider.dart';
import 'package:aura/services/notification_service.dart';
import 'package:aura/workmanager/workmanager_sync_health.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:aura/routes/route.dart' as route;
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Setup Workmanager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // Register background task every 15 minutes (minimum for Android)
  await Workmanager().registerPeriodicTask(
    'health_data_syncs',
    'health_data_sync',
    // 'fetchHealthDataTask',
    frequency: const Duration(minutes: 15), // minimal Android limit
    existingWorkPolicy: ExistingWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.not_required),
  );
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => HealthProvider())],
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(primarySwatch: Colors.teal),
      routerConfig: route.router,
      debugShowCheckedModeBanner: false,
    );
  }
}

//connect to ui (done)
//threshold using armd
// background and foreground service
// manual validation data panic (notif and single page with button 'i feel panic')
// connect to database
