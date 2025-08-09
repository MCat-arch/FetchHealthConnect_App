import 'package:app_aura/services/health_service.dart';
import 'package:app_aura/services/notification_service.dart';
import 'package:app_aura/utils/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';


@pragma('vm:entry-point') // Required for background
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case 'health_data_sync':
          return await _handleHealthDataSync(inputData);
        default:
          print("Unknown task type: $task");
          return Future.value(false);
      }
    } catch (e, st) {
      print("Task error: $e");
      print(st);
      return Future.value(false); // retry if allowed
    }
    //   // Fetch data
    //   final healthService = HealthService();
    //   final storage = StorageHelper();
    //   bool isPanic = false;

    //   final healthDataList = await HealthService.fetchData();
    //   await StorageHelper.saveData(healthDataList);

    //   //check every new data avail
    //   if (healthDataList.where((d) => d.details.last.kategori == 'panic')) {
    //     NotificationService().showNotification();
    //   }

    //   return Future.value(true);
  });
}

Future<bool> _handleHealthDataSync(Map<String, dynamic>? inputData) async {

  final lastData = await StorageHelper.loadFromLocal();

  final fetched = await HealthService.fetchData();

  bool hasNewPanic = false;
  if (lastData != null && lastData.isNotEmpty) {
    final oldTimes =
        lastData
            .expand(
              (d) => d.details
                  .where((details) => details.kategori == 'panic')
                  .map((details) => "${details.kategori}-${details.time}"),
            )
            .toSet();
    for (var newData in fetched) {
      for (var detail in newData.details) {
        final key = "${detail.kategori}-${detail.time}";
        if (detail.kategori == 'panic' && !oldTimes.contains(key)) {
          hasNewPanic = true;
        }
      }
    }
  } else {
    // First run — if any panic exists, notify
    hasNewPanic = fetched.any(
      (hd) => hd.details.any((d) => d.kategori == 'panic'),
    );
  }

  await StorageHelper.saveData(fetched);

  if (hasNewPanic) {
    await NotificationService().showNotification();
  }
  return true;
}
