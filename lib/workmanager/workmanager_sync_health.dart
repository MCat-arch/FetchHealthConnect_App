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
    final oldGrouped = await StorageHelper.loadGroupedData() ?? {};
    final oldPanicKeys = oldGrouped.entries
        .expand(
          (e) => e.value
              .where((d) => d.kategori == 'panic')
              .map((d) => '${e.key}-${d.time}'),
        )
        .toSet();

    //fetch data baru dari health service
    final now = DateTime.now();
    final start = now.subtract(const Duration(minutes: 30));
    final raw = await HealthService.fetchHealthDataRaw(start, now);
    final newGrouped = HealthService.groupedHealthData(raw);

    final newPanicKeys = newGrouped.entries
        .expand(
          (e) => e.value
              .where((d) => d.kategori == 'panic')
              .map((d) => '${e.key}-${d.time}'),
        )
        .toSet();

    final diffPanic = newPanicKeys.difference(oldPanicKeys);
    print('[Workmanager DEBUG] New panic keys found: ${diffPanic.length}');

    if (diffPanic.isNotEmpty) {
      final timesFormatted = diffPanic.map((k) => k.split('-').last).join(', ');
      await NotificationService().showNotification();
      print('[Workmanager DEBUG] Notification sent for $timesFormatted');
    }

    //save to local
    await StorageHelper.saveGroupedData(newGrouped);
    print('[Workmanager DEBUG] Data saved successfully.');

    print('[Workmanager DEBUG] _handleHealthDataSync completed.');
    return true;
  } catch (e, st) {
    print('[Workmanager DEBUG] _handleHealthDataSync error: $e');
    print('[Workmanager DEBUG] Stack Trace: $st');
    return false;
  }
}
