import 'package:aura_bluetooth/routes/routes.dart' as route;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

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
        route.router.go('/breathing');
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
    String body = 'Hei its okay, tell yourself what emotion you going through now. Its okay to calm down',}
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
      'Calm budy',
      'Lets breath',
      notificationDetails,
    );
  }
}
