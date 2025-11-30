import 'package:aura_bluetooth/firebase_options.dart';
import 'package:aura_bluetooth/providers/ble_provider.dart';
import 'package:aura_bluetooth/routes/routes.dart' as route;
import 'package:aura_bluetooth/services/foreground_service_hr.dart';
import 'package:aura_bluetooth/services/hrv_service.dart';
import 'package:aura_bluetooth/services/ml_panic_service.dart';
import 'package:aura_bluetooth/services/notification_service.dart';
import 'package:aura_bluetooth/services/phone_permission_service.dart';
import 'package:aura_bluetooth/services/phone_sensor_service.dart';
import 'package:aura_bluetooth/services/rhr_service.dart';
import 'package:aura_bluetooth/services/setting_service.dart';
import 'package:aura_bluetooth/services/workmanager_service.dart';
import 'package:aura_bluetooth/utils/storage_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';


void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final storageService = StorageService();
  await storageService.init();

  try {
    final permissionGranted =
        await PhonePermissionService.requestAllPermission();

    if (!permissionGranted) {
      print('[Main] Some permissions were denied, but continuing...');
    } else {
      print('All permission granted');
    }

    // Deklarasikan semua service yang perlu diakses Provider di luar main()
    // final bleService = BLEService();
    final settingsService = SettingsService();
    final notificationService = NotificationService();
    // Tambahkan services lain yang dibutuhkan oleh provider
    // Asumsi services ini juga Singleton:
    // final firestoreService = FirestoreService();
    // final hrvService = HRVService();
    // final RHRService rhrService = RHRService();
    // final workmanager = WorkmanagerService();
    // final MLPanicService mlService = MLPanicService();
    final ForegroundMonitorService foregroundMonitorService =
        ForegroundMonitorService();
    // final phonesensor = PhoneSensorService();

    // 5. Init Core Services
    await settingsService.initialize();

    await notificationService.initNotification();

    // await _registerWorkmanagerTasks();

    await ForegroundMonitorService().init();

    print('[Main] All services initialized successfully');

    runApp(
      MultiProvider(
        providers: [
          // 1. Providers yang menggunakan Singleton top-level (SUDAH BENAR)
          // Provider<BLEService>.value(value: bleService),
          Provider<StorageService>.value(value: storageService),
          Provider<SettingsService>.value(value: settingsService),
          Provider<NotificationService>.value(value: notificationService),

          // ... services lainnya
          // Provider<HRVService>.value(value: hrvService),
          // ... dan seterusnya untuk semua service yang Anda definisikan di atas.
          Provider<ForegroundMonitorService>.value(
            value: foregroundMonitorService,
          ),
          // Provider<WorkmanagerService>.value(value: workmanager),
          // ChangeNotifierProvider(create: (_) => PhoneSensorProvider()),
          ChangeNotifierProvider(
            create: (_) => BLEProvider(),
            // <-- hanya dibuat SEKALI
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('[Main] Error during initialization: $e');
    print('[Main] Stack trace: $stackTrace');

    // Fallback - run app even if some services fail
    runApp(const MyApp());
  }
}

// Future<void> _registerWorkmanagerTasks() async {
//   try {
//     // Health data sync task
//     await Workmanager().registerPeriodicTask(
//       'health_data_sync',
//       WorkmanagerService.healthDataSyncTask,
//       frequency: const Duration(minutes: 15),
//       initialDelay: const Duration(seconds: 30),
//       constraints: Constraints(networkType: NetworkType.connected),
//       existingWorkPolicy: ExistingWorkPolicy.replace,
//     );

//     // Panic data sync task
//     await Workmanager().registerPeriodicTask(
//       'panic_data_sync',
//       WorkmanagerService.panicDataSyncTask,
//       frequency: const Duration(minutes: 30),
//       initialDelay: const Duration(minutes: 2),
//       constraints: Constraints(networkType: NetworkType.connected),
//       existingWorkPolicy: ExistingWorkPolicy.replace,
//     );

//     // Cleanup task (daily)
//     await Workmanager().registerPeriodicTask(
//       'cleanup_task',
//       WorkmanagerService.cleanupTask,
//       frequency: const Duration(hours: 24),
//       initialDelay: const Duration(hours: 1),
//       existingWorkPolicy: ExistingWorkPolicy.replace,
//     );

//     print('[Main] Workmanager tasks registered successfully');
//   } catch (e) {
//     print('[Main] Error registering Workmanager tasks: $e');
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: MaterialApp.router(
        title: 'AURA Health Monitor',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        themeMode: ThemeMode.system,
        routerConfig: route.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// got storage, workmanager, and firestore service new
// i think it is not yet connected with task handler
// added new field prediction on heartRateModel

// memperbaiki statistikanya, bpm di hitung bukan dari rrInterval (fungsi nya kurang)
// menambahkan feedback jika disconnect dengan bluetooth
// masalah pada time of the day dan time di phone sersor service



