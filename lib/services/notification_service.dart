import 'dart:async';

import 'package:aura_bluetooth/routes/routes.dart' as route;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin notification =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> _onNotificationClick =
      StreamController<String?>.broadcast();

  Stream<String?> get onNotificationClick => _onNotificationClick.stream;

  static bool _initialized = false;

  Future<void> initNotification() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSetting = InitializationSettings(android: androidSettings);

    await notification.initialize(
      initSetting,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        //payload di ui
        _onNotificationClick.add(response.payload);
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

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'aura_alert',
      'AURA Alerts',
      channelDescription: 'important alerts for connection and health',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await notification.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
