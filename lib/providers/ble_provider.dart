import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/ble_service.dart';
import '../models/heart_rate_model.dart';
import '../services/ml_panic_service.dart';

class BLEProvider extends ChangeNotifier {
  // Instance BLEService KHUSUS UNTUK UI (Hanya dipakai scanning)
  late final BLEService _uiBleService;

  // UI State
  List<ScanResult> scanResults = [];
  bool isScanning = false;
  
  // Background State (Data dari TaskHandler)
  String status = "disconnected";
  bool statusConnect = false;
  HeartRateData? heartRate;
  PanicPrediction? panicPrediction;

  // Subscriptions
  StreamSubscription? _scanSub;
  StreamSubscription? _statusSub; // Optional: kalau mau liat status raw

  BLEProvider() {
    // 1. Init BLEService untuk UI Isolate
    _uiBleService = BLEService();
    
    // 2. Setup Listener komunikasi dengan Background
    _initBackgroundListener();
    
    // 3. Listen perubahan status scan (Scanning/Idle)
    FlutterBluePlus.isScanning.listen((scanning) {
        isScanning = scanning;
        notifyListeners();
    });
  }

  // ----------------------------------------------------------------
  // BAGIAN 1: SCANNING (Dikelola UI)
  // ----------------------------------------------------------------

  void startScan() {
    // Reset hasil scan lama
    scanResults.clear();
    notifyListeners();

    // Listen hasil scan dari hardware langsung ke UI
    _scanSub?.cancel();
    _scanSub = _uiBleService.scanResultsStream.listen((results) {
      // Filter device yang punya nama agar list rapi (Opsional)
      scanResults = results.where((r) => r.device.platformName.isNotEmpty).toList();
      notifyListeners();
    });

    // Mulai scan fisik
    _uiBleService.startScan();
  }

  void stopScan() {
    _uiBleService.stopScan();
    _scanSub?.cancel();
  }

  // ----------------------------------------------------------------
  // BAGIAN 2: CONNECTING (Perintah ke Background)
  // ----------------------------------------------------------------

  Future<void> connectTo(ScanResult r) async {
    // 1. WAJIB: Stop Scan di UI dulu agar Bluetooth Resource bebas
    stopScan();
    
    // 2. Update UI jadi "Connecting..."
    status = "Requesting Connection...";
    notifyListeners();

    // 3. Kirim Perintah ke Background Task
    print("📡 UI -> BG: Connect to ${r.device.remoteId.str}");
    
    FlutterForegroundTask.sendDataToTask({
      'action': 'connect',
      'deviceId': r.device.remoteId.str,
    });
  }

  Future<void> disconnect() async {
    print("📡 UI -> BG: Disconnect");
    
    FlutterForegroundTask.sendDataToTask({
      'action': 'disconnect',
    });
    
    // Reset UI lokal
    statusConnect = false;
    heartRate = null;
    notifyListeners();
  }

  // ----------------------------------------------------------------
  // BAGIAN 3: LISTENING (Data dari Background)
  // ----------------------------------------------------------------

  void _initBackgroundListener() {
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      // A. Terima Data Heart Rate
      if (map.containsKey('bpm')) {
        try {
          heartRate = HeartRateData.fromJson(map);
          statusConnect = true; // Tandai Connected
          status = "Monitoring: ${heartRate!.bpm} BPM";
          notifyListeners();
        } catch (e) {
          print("❌ Parse Error UI: $e");
        }
      } 
      
      // B. Terima Status Koneksi (Opsional, jika BG kirim status update)
      else if (map.containsKey('status')) {
         final bgStatus = map['status'];
         if (bgStatus == 'connected') statusConnect = true;
         if (bgStatus == 'disconnected') statusConnect = false;
         status = "BG Status: $bgStatus";
         notifyListeners();
      }
      
      // C. Terima Panic Prediction
      else if (map.containsKey('isPanic')) {
         // Handle panic UI
      }
    }
  }

  @override
  void dispose() {
    stopScan(); // Pastikan scan mati saat widget hancur
    _scanSub?.cancel();
    _statusSub?.cancel();
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }
}