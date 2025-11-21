import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PhonePermissionService {
  static Future<bool> requestAllPermission() async {
    try {
      final permissions = [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetooth,
        // Permission.locationWhenInUse,
        Permission.activityRecognition,
        Permission.microphone,
        Permission.notification, // For Android 13+
        Permission.ignoreBatteryOptimizations,

      ];

      final Map<Permission, PermissionStatus> status = {};

      for (final permission in permissions) {
        try {
          final permissionStatus = await permission.request();
          status[permission] = permissionStatus;
          print(
            '[PermissionService] ${permission.toString().split('.').last}: $permissionStatus',
          );
        } catch (e) {
          print('[PermissionService] Error requesting $permission: $e');
          status[permission] = PermissionStatus.denied;
        }

        // Tunggu sebentar antara request permission
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Check if all requested permissions are granted
      final allGranted = status.values.every((s) => s.isGranted);

      if (allGranted) {
        debugPrint("[PermissionService] ✅ All permissions granted");
      } else {
        debugPrint(
          "[PermissionService] ❌ Some essential permissions were denied: $status",
        );
      }

      for (final entry in status.entries) {
        if (!entry.value.isGranted) {
          debugPrint(
            "  - ${entry.key.toString().split('.').last}: ${entry.value}",
          );
        }
      }
      return allGranted;
    } catch (e) {
      debugPrint("[PermissionService] Error requesting permissions: $e");
      return false;
    }
  }

  static Future<bool> arePermissionGranted() async {
    try {
      bool bluetoothGranted =
          await Permission.bluetoothScan.isGranted &&
          await Permission.bluetoothConnect.isGranted;
      // bool locationGranted = await Permission.locationWhenInUse.isGranted;
      bool sensorGranted = await Permission.sensors.isGranted;
      bool activity = await Permission.activityRecognition.isGranted;
      final microphoneGranted = await Permission.microphone.isGranted;
      return bluetoothGranted && microphoneGranted && sensorGranted && activity;
    } catch (e) {
      print('[PermissionService] Error checking permissions: $e');
      return false;
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint("[PermissionService] Error opening app settings: $e");
    }
  }
}
