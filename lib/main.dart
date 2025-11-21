import 'package:aura_bluetooth/firebase_options.dart';
import 'package:aura_bluetooth/providers/ble_provider.dart';
import 'package:aura_bluetooth/routes/routes.dart';
import 'package:aura_bluetooth/routes/routes.dart' as route;
import 'package:aura_bluetooth/services/notification_service.dart';
import 'package:aura_bluetooth/services/phone_permission_service.dart';
import 'package:aura_bluetooth/services/phone_sensor_service.dart';
import 'package:aura_bluetooth/services/setting_service.dart';
import 'package:aura_bluetooth/services/workmanager_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

//home page not work yet

// Workmanager callback
import 'package:aura_bluetooth/services/workmanager_service.dart'
    show callbackDispatcher;

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  try {
    print('[Main] Initializing services...');

    final permissionGranted =
        await PhonePermissionService.requestAllPermission();

    if (!permissionGranted) {
      print('[Main] Some permissions were denied, but continuing...');
    } else {
      print('All permission granted');
    }

    print('MAIN : initializing firebase');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize core services
    await _initializeCoreServices();

    // Initialize background services
    await _initializeBackgroundServices();

    print('[Main] All services initialized successfully');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => BLEProvider(), // <-- hanya dibuat SEKALI
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

Future<void> _initializeCoreServices() async {
  try {
    // Initialize settings service first
    print('[Main] Initializing settings service...');
    await SettingsService().initialize();

    // Initialize phone sensor service
    print('[Main] Initializing phone sensor service...');
    await PhoneSensorService().initialize();

    // Initialize notification service
    print('[Main] Initializing notification service...');
    await NotificationService().initNotification();

    print('[Main] Core services initialized successfully');
  } catch (e) {
    print('[Main] Error in core services: $e');
    rethrow;
  }
}

Future<void> _initializeBackgroundServices() async {
  // Initialize Workmanager for background tasks
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Initialize foreground task
  FlutterForegroundTask.initCommunicationPort();

  // Register periodic tasks
  await _registerWorkmanagerTasks();
}

Future<void> _registerWorkmanagerTasks() async {
  try {
    // Health data sync task
    await Workmanager().registerPeriodicTask(
      'health_data_sync',
      WorkmanagerService.healthDataSyncTask,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 30),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    // Panic data sync task
    await Workmanager().registerPeriodicTask(
      'panic_data_sync',
      WorkmanagerService.panicDataSyncTask,
      frequency: const Duration(minutes: 30),
      initialDelay: const Duration(minutes: 2),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    // Cleanup task (daily)
    await Workmanager().registerPeriodicTask(
      'cleanup_task',
      WorkmanagerService.cleanupTask,
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(hours: 1),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );

    print('[Main] Workmanager tasks registered successfully');
  } catch (e) {
    print('[Main] Error registering Workmanager tasks: $e');
  }
}

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
        // builder: (context, child) {
        //   return MediaQuery(
        //     data: MediaQuery.of(context).copyWith(
        //       textScaleFactor: 1.0, // Prevent system font scaling
        //     ),
        //     child: child!,
        //   );
        // },
      ),
    );
  }
}
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
//   await FlutterForegroundTask.init();
//   // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   PhoneSensorService().initialize();

//   await Workmanager().registerPeriodicTask(
//     'health_data_syncs',
//     'health_data_sync',
//     // 'fetchHealthDataTask',
//     frequency: const Duration(minutes: 15), // minimal Android limit
//     existingWorkPolicy: ExistingWorkPolicy.keep,
//     constraints: Constraints(networkType: NetworkType.not_required),
//   );
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp.router(
//       //define route
//       // title: 'BLE Heart Rate',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       routerConfig: route.router,

//       // home: const HeartRatePage(),
//     );
//   }
// }


//TODO:
      //perlu refresh app di awal setelah ask permission
      //calculate hrv, rhr
      //activity recognition
      //workmanager, or background running

      //login logout dengan kode sebelumnya
      //workmanager untuk sync data ke cloud

      //simpan data di cloud
      //gabung data dan ml model
      //notifikasi
      //feedback seperti untuk nafas 
      

      //integrasi stats nya
      //integrasi foreground workmanager service
      //


      //NEXT
      // - menampilkan nama device bluetooth yang akan connect
      // - logic untuk connect masih error sepertinya (belum bisa connect)
      // - tambahkan provider untuk simpan state
      // - masalahnya langsung deteksi panic (tidak menampilkan data)
      