import 'dart:ui';

import 'package:aura/model/health_data.dart';
import 'package:aura/model/health_day_data.dart';
import 'package:aura/services/health_service.dart';
import 'package:aura/services/notification_service.dart';
import 'package:aura/utils/storage_helper.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:isolate';
import 'dart:async';

@pragma('vm:entry-point')
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
  try {
    print('[Workmanager] Fetching health data...');
    await HealthService.backgroundFetch();

    // // 🔔 Trigger UI refresh di main isolate
    // final sendPort = IsolateNameServer.lookupPortByName(healthPortName);
    // sendPort?.send('health_updated');

    return true;
  } catch (e) {
    print('[Workmanager ERROR] $e\n');
    return false;
  }
}
