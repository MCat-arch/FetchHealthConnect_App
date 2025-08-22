import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aura/routes/route.dart' as route;
import 'package:go_router/go_router.dart';

// class NotificationService {
//   final notificationPlugins = FlutterLocalNotificationsPlugin();
//   final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//   bool _isInitialized = false;
//   bool get isInitialized => _isInitialized;

//   //initialized
//   // Future<void> initNotification() async {
//   //   if (_isInitialized) return;

//   //   const initSettingAndroid = AndroidInitializationSettings(
//   //     '@mipmap/ic_launcher',
//   //   );

//   //   const initSetting = InitializationSettings(android: initSettingAndroid);

//   //   await notificationPlugins.initialize(
//   //     initSetting,
//   //     onDidReceiveNotificationResponse: (NotificationResponse response) {
//   //       route.router.go('/manual-label');
//   //     },
//   //   );
//   // }

//   //notification detail
//   NotificationDetails notificationDetails() {
//     return const NotificationDetails(
//       android: AndroidNotificationDetails(
//         'alert_panic_id',
//         'Alert Panic Notification',
//         channelDescription: 'Channel for full screen panic alerts',
//         importance: Importance.max,
//         priority: Priority.high,
//         fullScreenIntent: true,
//         ticker: 'ticker',
//       ),
//     );
//   }

//   Future<void> showNotification({
//     int id = 1,
//     String? title,
//     String? body,
//   }) async {
//     return notificationPlugins.show(
//       1,
//       'Panic Alert Detected!',
//       'Heart rate tinggi. Apakah kamu sedang mengalami panic attack?',
//       payload: 'panic_payload',
//       const NotificationDetails(),
//     );
//   }
// }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notification =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  Future<void> initNotification() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSetting = InitializationSettings(android: androidSettings);

    await _notification.initialize(
      initSetting,
      onDidReceiveNotificationResponse: (response) {
        route.router.go('/manual-label');
      },
    );

    _initialized = true;
  }

  Future<void> requestPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> showNotification(
    { int id = 1,
    String title = 'Panic Alert',
    String body = 'Panic alert detected!',}
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'panic_channel_id',
      'panic_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notification.show(
      1,
      'Simulasi panik notif',
      'Panic alert Detected !',
      notificationDetails,
    );
  }
}
