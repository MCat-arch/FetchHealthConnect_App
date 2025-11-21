import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';
import '../services/ble_service.dart';
import '../models/heart_rate_model.dart';
import '../models/hrv_metric.dart';
import '../services/ml_panic_service.dart';

class BLEProvider extends ChangeNotifier {
  final BLEService _ble = BLEService();

  String status = "disconnected";
  bool statusConnect = false;
  HeartRateData? heartRate;
  Map<int, HRVMetrics> hrvMetrics = {};
  List<ScanResult> scanResults = [];
  PanicPrediction? panicPrediction;

  bool isScanning = false;
  bool isConnecting = false;

  // stream subscribers
  StreamSubscription? _statusSub;
  StreamSubscription? _hrSub;
  StreamSubscription? _hrvSub;
  StreamSubscription? _scanSub;
  StreamSubscription? _panicSub;

  BLEProvider() {
    _listenStreams();
    _initAutoConnect();
  }

  void _listenStreams() {
    _statusSub = _ble.statusStream.listen((value) {
      status = value;
      notifyListeners();
    });

    _hrSub = _ble.hrStream.listen((hr) {
      heartRate = hr;
      notifyListeners();
    });

    _hrvSub = _ble.hrvStream.listen((metrics) {
      hrvMetrics = metrics;
      notifyListeners();
    });

    _scanSub = _ble.scanResultsStream.listen((results) {
      scanResults = results;
      notifyListeners();
    });

    _panicSub = _ble.panicAlertStream.listen((pred) {
      panicPrediction = pred;
      notifyListeners();
    });
  }

  Future<void> _initAutoConnect() async {
    final found = await _ble.checkAlreadyConnectedDevice();
    if (!found) startScan();
    statusConnect = true;
  }

  Future<void> startScan() async {
    isScanning = true;
    notifyListeners();
    await _ble.startScan();
  }

  Future<void> stopScan() async {
    isScanning = false;
    notifyListeners();
    await _ble.stopScan();
  }

  Future<void> connectTo(ScanResult r) async {
    isConnecting = true;
    notifyListeners();
    await _ble.connectToDevice(r);
    isConnecting = false;
    statusConnect = true;
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _ble.disconnect();
    statusConnect = false;
    notifyListeners();
  }

  void isConnect() {}

  @override
  void dispose() {
    _statusSub?.cancel();
    _hrSub?.cancel();
    _hrvSub?.cancel();
    _scanSub?.cancel();
    _panicSub?.cancel();
    super.dispose();
  }
}
