import 'dart:io';
import 'package:aura_bluetooth/utils/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Tambahkan paket ini untuk cek versi Android

class PhonePermissionService {
  /// Meminta semua izin yang diperlukan sekaligus
  static Future<bool> requestAllPermission() async {
    try {
      List<Permission> permissions = [
        Permission.activityRecognition,
        Permission.microphone,
        Permission.notification, // Android 13+
      ];

      // Logika Khusus Versi Android untuk Bluetooth
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 31) {
          // Android 12+ (S)
          permissions.addAll([
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
          ]);
        } else {
          // Android 11 ke bawah butuh Lokasi untuk BLE Scan
          permissions.add(Permission.locationWhenInUse);
        }
      } else if (Platform.isIOS) {
        permissions.add(Permission.bluetooth);
      }

      // 1. Request Permissions SEKALIGUS (Batch Request)
      // Ini lebih baik secara UX daripada loop satu per satu
      Map<Permission, PermissionStatus> statuses = await permissions.request();

      // Debug Print Status
      statuses.forEach((permission, status) {
        print('[PermissionService] $permission: $status');
      });

      // 2. Cek apakah izin KRUSIAL diberikan
      // Kita filter ignoreBatteryOptimizations dari cek ini karena dia spesial
      bool allEssentialGranted = statuses.values.every(
        (status) => status.isGranted,
      );

      if (allEssentialGranted) {
        debugPrint("[PermissionService] ✅ All core permissions granted");


        // 3. Request Battery Optimization Terpisah (Opsional & Hati-hati)
        // Lakukan ini hanya jika benar-benar perlu agar tidak mengganggu flow user
        await _requestBatteryOptimization();
        await StorageService().savePermissionStatus(true);

        return true;
      } else {
        debugPrint("[PermissionService] ❌ Some permissions denied: $statuses");
        await StorageService().savePermissionStatus(false);
        return false;
      }
    } catch (e) {
      debugPrint("[PermissionService] Error requesting permissions: $e");
      return false;
    }
  }

  static Future<void> _requestBatteryOptimization() async {
    // Battery optimization behaves differently. It opens a system dialog directly.
    // Only request if strictly necessary.
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  static Future<bool> arePermissionGranted() async {
    final bool isStoredGranted = StorageService().getStoredPermissionStatus();

    if (isStoredGranted) {
      // Jika di storage sudah true, kita asumsikan granted.
      // Ini mencegah sensor service return false di background.
      return true;
    }
    try {
      bool activity = await Permission.activityRecognition.isGranted;
      bool mic = await Permission.microphone.isGranted;
      bool notif = await Permission.notification.isGranted;

      bool ble = false;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 31) {
          ble =
              await Permission.bluetoothScan.isGranted &&
              await Permission.bluetoothConnect.isGranted;
        } else {
          // Untuk Android lama, Location = BLE Permission
          ble = await Permission.locationWhenInUse.isGranted;
        }
      } else {
        ble = await Permission.bluetooth.isGranted;
      }

      // Catatan: Permission.sensors biasanya TIDAK PERLU untuk activity recognition standar
      // kecuali Anda mengakses sensor raw (gyroscope/accelerometer) secara manual.

      return ble && mic && activity && notif;
    } catch (e) {
      print('[PermissionService] Error checking permissions: $e');
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      // Panggil fungsi global dari package permission_handler
      // Jangan panggil nama fungsi kelas ini sendiri (Recursion!)
      await openAppSettings();
    } catch (e) {
      debugPrint("[PermissionService] Error opening app settings: $e");
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';

// class PhonePermissionService {
//   static Future<bool> requestAllPermission() async {
//     try {
//       final permissions = [
//         Permission.bluetoothScan,
//         Permission.bluetoothConnect,
//         Permission.bluetooth,
//         // Permission.locationWhenInUse,
//         Permission.activityRecognition,
//         Permission.microphone,
//         Permission.notification, // For Android 13+
//         Permission.ignoreBatteryOptimizations,

//       ];

//       final Map<Permission, PermissionStatus> status = {};

//       for (final permission in permissions) {
//         try {
//           final permissionStatus = await permission.request();
//           status[permission] = permissionStatus;
//           print(
//             '[PermissionService] ${permission.toString().split('.').last}: $permissionStatus',
//           );
//         } catch (e) {
//           print('[PermissionService] Error requesting $permission: $e');
//           status[permission] = PermissionStatus.denied;
//         }

//         // Tunggu sebentar antara request permission
//         await Future.delayed(const Duration(milliseconds: 100));
//       }
//       // Check if all requested permissions are granted
//       final allGranted = status.values.every((s) => s.isGranted);

//       if (allGranted) {
//         debugPrint("[PermissionService] ✅ All permissions granted");
//       } else {
//         debugPrint(
//           "[PermissionService] ❌ Some essential permissions were denied: $status",
//         );
//       }

//       for (final entry in status.entries) {
//         if (!entry.value.isGranted) {
//           debugPrint(
//             "  - ${entry.key.toString().split('.').last}: ${entry.value}",
//           );
//         }
//       }
//       return allGranted;
//     } catch (e) {
//       debugPrint("[PermissionService] Error requesting permissions: $e");
//       return false;
//     }
//   }

//   static Future<bool> arePermissionGranted() async {
//     try {
//       bool bluetoothGranted =
//           await Permission.bluetoothScan.isGranted &&
//           await Permission.bluetoothConnect.isGranted;
//       // bool locationGranted = await Permission.locationWhenInUse.isGranted;
//       bool sensorGranted = await Permission.sensors.isGranted;
//       bool activity = await Permission.activityRecognition.isGranted;
//       final microphoneGranted = await Permission.microphone.isGranted;
//       return bluetoothGranted && microphoneGranted && sensorGranted && activity;
//     } catch (e) {
//       print('[PermissionService] Error checking permissions: $e');
//       return false;
//     }
//   }

//   static Future<void> openAppSettings() async {
//     try {
//       await openAppSettings();
//     } catch (e) {
//       debugPrint("[PermissionService] Error opening app settings: $e");
//     }
//   }
// }
