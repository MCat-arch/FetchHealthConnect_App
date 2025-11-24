import 'dart:async';
import 'package:aura_bluetooth/main.dart';
import 'package:aura_bluetooth/providers/phoneSensor_provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/ble_service.dart';
import '../models/heart_rate_model.dart';
import '../models/hrv_metric.dart';
import '../services/ml_panic_service.dart';

class BLEProvider extends ChangeNotifier {
  late final BLEService _bleService;

  String status = "disconnected";
  bool statusConnect = false;
  HeartRateData? heartRate;
  List<ScanResult> scanResults = [];
  PanicPrediction? panicPrediction;

  bool isScanning = false;
  bool isConnecting = false;

  StreamSubscription? _statusSub;
  StreamSubscription? _scanSub;
  StreamSubscription? _backgroundDataSub;

  BLEProvider() {
    _bleService = BLEService();
    _listenStreams();
  }

  // INISIASI HARUS DIPANGGIL DARI UI
  Future<void> initialize() async {
    final found = await _bleService.checkAlreadyConnectedDevice();
    if (!found) startScan();
    statusConnect = true;
    notifyListeners();
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map) {
      final mapData = Map<String, dynamic>.from(data);

      if (mapData.containsKey('bpm')) {
        heartRate = HeartRateData.fromJson(mapData);
      } else if (mapData.containsKey('isPanic')) {
        panicPrediction = PanicPrediction.fromJson(mapData);
      }

      notifyListeners();
    }
  }

  void _listenStreams() {
    _statusSub = _bleService.statusStream.listen((value) {
      status = value;
      notifyListeners();
    });

    _scanSub = _bleService.scanResultsStream.listen((r) {
      scanResults = r;
      notifyListeners();
    });

    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  Future<void> startScan() async {
    isScanning = true;
    notifyListeners();
    await _bleService.startScan();
  }

  Future<void> stopScan() async {
    isScanning = false;
    notifyListeners();
    await _bleService.stopScan();
  }

  Future<void> connectTo(ScanResult r) async {
    isConnecting = true;
    notifyListeners();

    await _bleService.connectToDevice(r);

    isConnecting = false;
    statusConnect = true;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _bleService.disconnect();
    statusConnect = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _scanSub?.cancel();
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }
}
