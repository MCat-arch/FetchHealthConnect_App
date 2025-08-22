import 'package:aura/model/health_data.dart';
import 'package:aura/model/health_day_data.dart';
import 'package:aura/services/health_service.dart';
import 'package:aura/services/notification_service.dart';
import 'package:aura/utils/storage_helper.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point') // Penting untuk background
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('[Workmanager DEBUG] Task started: $task at ${DateTime.now()}');
    print(
      '[Workmanager DEBUG] InputData received: $inputData',
    ); // Debug: Cek apakah inputData kosong atau tidak

    try {
      switch (task) {
        case 'health_data_sync':
          return await _handleHealthDataSync();
        default:
          print("[Workmanager DEBUG] Unknown task type: $task");
          return false;
      }
    } catch (e, st) {
      print("[Workmanager DEBUG] Global Error: $e");
      print("[Workmanager DEBUG] Stack Trace: $st");
      return false;
    }
  });
}

Future<bool> _handleHealthDataSync() async {
  final startTime = DateTime.now();
  print('[Workmanager DEBUG] _handleHealthDataSync started at $startTime');

  try {
    // Step 1: Init notifikasi
    print('[Workmanager DEBUG] Initializing NotificationService...');
    await NotificationService().initNotification();
    print('[Workmanager DEBUG] NotificationService initialized successfully.');

    // Step 2: Load data lama dari local storage
    print('[Workmanager DEBUG] Loading data from local storage...');
    final List<HealthData>? lastData = await StorageHelper.loadFromLocal();
    print(
      '[Workmanager DEBUG] Loaded lastData count: ${lastData?.length ?? 0}',
    );
    if (lastData == null || lastData.isEmpty) {
      print('[Workmanager DEBUG] Warning: No previous data loaded from local.');
    }

    // Step 3: Ambil data terbaru langsung dari HealthService
    print('[Workmanager DEBUG] Fetching new data from HealthService...');
    final newestData = await HealthService.fetchData(true);
    print('[Workmanager DEBUG] Fetched new data count: ${newestData.length}');
    if (newestData.isEmpty) {
      print(
        '[Workmanager DEBUG] Warning: No new data fetched. Check HealthService permissions or data availability.',
      );
    }

    // Step 4: Deteksi panic baru
    print('[Workmanager DEBUG] Detecting new panic events...');
    final oldPanicKeys = (lastData ?? [])
        .expand(
          (d) => d.details
              .where((detail) => detail.kategori == 'panic')
              .map((detail) => '${d.date}-${detail.time}'),
        )
        .toSet();
    print('[Workmanager DEBUG] Old panic keys count: ${oldPanicKeys.length}');

    final List<String> newPanicTimes = [];
    for (var dayData in newestData) {
      for (var detail in dayData.details) {
        final key = '${dayData.date}-${detail.time}';
        if (detail.kategori == 'panic' && !oldPanicKeys.contains(key)) {
          newPanicTimes.add(detail.time);
        }
      }
    }
    print(
      '[Workmanager DEBUG] New panic times found: ${newPanicTimes.length} (${newPanicTimes.join(', ')})',
    );

    // Step 5: Kirim notifikasi jika ada panic baru
    if (newPanicTimes.isNotEmpty) {
      final timesFormatted = newPanicTimes.join(', ');
      final notificationTitle = 'Indikasi Panic Attack';
      final notificationBody =
          'Terdeteksi ${newPanicTimes.length} panic baru pada jam: $timesFormatted';
      print(
        '[Workmanager DEBUG] Sending notification: $notificationTitle - $notificationBody',
      );
      await NotificationService().showNotification(
        title: notificationTitle,
        body: notificationBody,
      );
      print('[Workmanager DEBUG] Notification sent successfully.');
    } else {
      print(
        '[Workmanager DEBUG] No new panic detected, skipping notification.',
      );
    }

    // Step 6: Simpan data terbaru ke local
    print('[Workmanager DEBUG] Saving new data to local storage...');
    await StorageHelper.saveData(newestData);
    print('[Workmanager DEBUG] Data saved successfully.');

    final endTime = DateTime.now();
    print(
      '[Workmanager DEBUG] _handleHealthDataSync completed in ${endTime.difference(startTime).inSeconds} seconds.',
    );
    return true;
  } catch (e, st) {
    print('[Workmanager DEBUG] _handleHealthDataSync error: $e');
    print('[Workmanager DEBUG] Stack Trace: $st');
    return false;
  }
}


// import 'package:aura/model/health_data.dart';
// import 'package:aura/model/health_day_data.dart';
// import 'package:aura/services/health_service.dart';
// import 'package:aura/services/notification_service.dart';
// import 'package:aura/utils/storage_helper.dart';
// import 'package:workmanager/workmanager.dart';

// @pragma('vm:entry-point') // Penting untuk background
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     print('[Workmanager] Task started: $task at ${DateTime.now()}');
//     try {
//       switch (task) {
//         case 'health_data_sync':
//           return await _handleHealthDataSync();
//         default:
//           print("[Workmanager] Unknown task type: $task");
//           return false;
//       }
//     } catch (e, st) {
//       print("[Workmanager] Error: $e");
//       print(st);
//       return false;
//     }
//   });
// }



// Future<bool> _handleHealthDataSync() async {
//   print('[Workmanager] _handleHealthDataSync called at ${DateTime.now()}');

//   try {
//     // Init notifikasi
//     await NotificationService().initNotification();

//     // Load data lama dari local storage
//     final List<HealthData>? lastData = await StorageHelper.loadFromLocal();
//     print('[Workmanager] Loaded lastData count: ${lastData?.length ?? 0}');

//     // Ambil data terbaru langsung dari HealthService
//     final newestData = await HealthService.fetchData(true);
//     print('[Workmanager] Fetched new data count: ${newestData.length}');

//     // Deteksi panic baru
//     final oldPanicKeys = (lastData ?? [])
//         .expand(
//           (d) => d.details
//               .where((detail) => detail.kategori == 'panic')
//               .map((detail) => '${d.date}-${detail.time}'),
//         )
//         .toSet();

//     final List<String> newPanicTimes = [];

//     for (var dayData in newestData) {
//       for (var detail in dayData.details) {
//         final key = '${dayData.date}-${detail.time}';
//         if (detail.kategori == 'panic' && !oldPanicKeys.contains(key)) {
//           newPanicTimes.add(detail.time);
//         }
//       }
//     }

//     // Kirim notifikasi jika ada panic baru
//     if (newPanicTimes.isNotEmpty) {
//       final timesFormatted = newPanicTimes.join(', ');
//       final notificationTitle = 'Indikasi Panic Attack';
//       final notificationBody =
//           'Terdeteksi ${newPanicTimes.length} panic baru pada jam: $timesFormatted';
//       await NotificationService().showNotification(
//         title: notificationTitle,
//         body: notificationBody,
//       );
//       print('[Workmanager] Notification sent for $timesFormatted');
//     }

//     // Simpan data terbaru ke local
//     await StorageHelper.saveData(newestData);
//     print('[Workmanager] Data saved to local');
//     return true;
//   } catch (e, st) {
//     print('[Workmanager] _handleHealthDataSync error: $e');
//     print(st);
//     return false;
//   }
// }

