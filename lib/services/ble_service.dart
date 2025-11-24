// services/ble_service.dart
import 'dart:async';
import 'package:aura_bluetooth/models/hrv_metric.dart';
import 'package:aura_bluetooth/models/raw_hr_model.dart';
import 'package:aura_bluetooth/models/spatio.model.dart';
import 'package:aura_bluetooth/providers/phoneSensor_provider.dart';
import 'package:aura_bluetooth/services/firestore_service.dart';
import 'package:aura_bluetooth/services/hrv_service.dart';
import 'package:aura_bluetooth/services/ml_panic_service.dart';
import 'package:aura_bluetooth/services/notification_service.dart';
import 'package:aura_bluetooth/services/phone_permission_service.dart';
import 'package:aura_bluetooth/services/phone_sensor_service.dart';
import 'package:aura_bluetooth/services/rhr_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/heart_rate_model.dart';
import 'package:hive/hive.dart';
import 'package:synchronized/synchronized.dart';

class BLEService {
  //final FlutterBluePlus _fbp = FlutterBluePlus.instance();
  // BLEService._internal();

  //first scenario
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal() {
    try {
      FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
    } catch (_) {}
  }

  // //second scenario
  // final PhoneSensorProvider phoneSensor;
  // BLEService(this.phoneSensor);

  BluetoothDevice? _device;
  BluetoothCharacteristic? _hrChar;
  final _processingLock = Lock();

  // streams untuk UI
  final StreamController<String> _statusCtrl =
      StreamController<String>.broadcast();
  final StreamController<HeartRateData> _hrCtrl =
      StreamController<HeartRateData>.broadcast();
  final StreamController<List<ScanResult>> _scanResultsCtrl =
      StreamController<List<ScanResult>>.broadcast();
  final StreamController<RawHrModel> _rawHrCtrl = StreamController.broadcast();

  final StreamController<Map<int, HRVMetrics>> _hrvCtrl =
      StreamController<Map<int, HRVMetrics>>.broadcast();

  Stream<String> get statusStream => _statusCtrl.stream;
  Stream<HeartRateData> get hrStream => _hrCtrl.stream;
  Stream<List<ScanResult>> get scanResultsStream => _scanResultsCtrl.stream;
  Stream<Map<int, HRVMetrics>> get hrvStream => _hrvCtrl.stream;
  Stream<RawHrModel> get rawHrStream => _rawHrCtrl.stream;
  // Stream<Activity> get activityStream => _activityCtrl.stream;

  // final FirestoreService _firestoreService = FirestoreService();
  // final MLPanicService _mlService = MLPanicService();

  final StreamController<PanicPrediction> _panicAlertCtrl =
      StreamController<PanicPrediction>.broadcast();

  Stream<PanicPrediction> get panicAlertStream => _panicAlertCtrl.stream;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _charSub;

  final HRVService _hrvService = HRVService();
  // final RHRService _rhrService = RHRService();
  // final SpatioTemporal _spatioTemporal = SpatioTemporal._internal();
  // final PhoneSensorService _phoneSensorService = PhoneSensorService();

  final List<HeartRateData> _history = [];
  List<HeartRateData> getHistorySnapshot() => List.unmodifiable(_history);

  bool _isScanning = false;
  bool get isConnected {
    return FlutterBluePlus.connectedDevices.isNotEmpty;
  }

  int _savedCount = 0;
  // Debug counters
  int _totalDataPoints = 0;
  int _hrvCalculations = 0;
  int _firestoreSyncs = 0;
  int _hiveSaves = 0;

  void log(String s) {
    if (!_statusCtrl.isClosed) _statusCtrl.add(s);
    if (kDebugMode) print('[BLEService] $s');
  }

  void _debugLog(String message, {String type = "INFO"}) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$type] $message';

    if (kDebugMode) {
      print('🔍 [BLEService-DEBUG] $logMessage');
    }

    if (!_statusCtrl.isClosed) {
      _statusCtrl.add(message);
    }
  }

  /// Start scanning for BLE devices (filtered by HR service to reduce noise)
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    log('Start scan requested');
    // cancel previous scan subscription if any
    await _scanSub?.cancel();

    // ensure adapter on
    final adapterState = await FlutterBluePlus.adapterStateNow;
    log('Adapter state now: $adapterState');
    if (adapterState != BluetoothAdapterState.on) {
      log('Waiting for adapter ON...');
      await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first;
      log('Adapter is ON');
    }

    try {
      _isScanning = true;
      // filter with heart rate service to reduce results; Guid('180D') also accepted
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [Guid('180D')],
      );
      log('startScan called (timeout ${timeout.inSeconds}s)');

      // subscribe to onScanResults
      _scanSub = FlutterBluePlus.onScanResults.listen(
        (results) {
          // forward full results to UI
          _scanResultsCtrl.add(results);
          // debug print each result
          for (final r in results) {
            final advName = r.advertisementData.advName ?? '';
            final platformName = r.device.platformName ?? '';
            final id = r.device.remoteId.str;
            log(
              'ScanResult -> name:"$advName" platformName:"$platformName" id:$id rssi:${r.rssi} manufacturer:${r.advertisementData.manufacturerData} services:${r.advertisementData.serviceUuids}',
            );
          }
        },
        onError: (e) {
          log('scan error: $e');
        },
      );

      // when scanning stops, ensure flag reset
      FlutterBluePlus.isScanning.where((v) => v == false).first.then((_) {
        _isScanning = false;
        log('Scanning stopped');
      });
    } catch (e) {
      log('startScan exception: $e');
      _isScanning = false;
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    if (_isScanning) {
      try {
        await FlutterBluePlus.stopScan();
        log('stopScan called');
      } catch (e) {
        log('stopScan error: $e');
      }
    }
    await _scanSub?.cancel();
    _scanSub = null;
  }

  /// Connect to a specific ScanResult's device (and subscribe HR)
  Future<void> connectToDevice(
    ScanResult? scanResult, {
    BluetoothDevice? device,
  }) async {
    BluetoothDevice? targetDevice = device ?? scanResult?.device;

    if (targetDevice == null) {
      final systemDevs = await FlutterBluePlus.connectedDevices;
      if (systemDevs.isNotEmpty) targetDevice = systemDevs.first;
    }

    if (targetDevice == null) {
      log("connectToDevice: No device found to connect.");
      return;
    }

    _device = targetDevice;

    await stopScan();

    // listen connection state
    _connSub?.cancel();
    _connSub = _device!.connectionState.listen((state) {
      log('Connection state: $state');
      if (state == BluetoothConnectionState.disconnected) {
        log('Device disconnected');
      }
    });
    // Connect only if not already connected
    final stateNow = await _device!.connectionState.first;

    // 4. LOGIKA UTAMA: Cek status DULU sebelum bertindak
    // Kita cek langsung ke Hardware apakah dia sudah connect?
    final connectedList = await FlutterBluePlus.connectedDevices;
    final isAlreadyConnected = connectedList.any(
      (d) => d.remoteId == targetDevice!.remoteId,
    );

    if (isAlreadyConnected) {
      _debugLog(
        "ℹ️ Device ${_device!.platformName} is ALREADY CONNECTED. Skipping connect()...",
      );
      // LANGSUNG DISCOVER SERVICES
      // Beri jeda sedikit agar stabil
      await Future.delayed(const Duration(milliseconds: 500));
      await _discoverServices();
    } else {
      _debugLog("🔗 Connecting to ${_device!.platformName}...");
      try {
        // Lakukan koneksi fisik
        await _device!.connect(autoConnect: false, license: License.free);
        _debugLog("✅ Connection successful. Discovering services...");
        await _discoverServices();
      } catch (e) {
        // Jika errornya "Already Connected", kita tetap lanjut discover
        if (e.toString().contains("already_connected")) {
          _debugLog(
            "⚠️ Exception caught: Already connected. Proceeding to discover...",
          );
          await _discoverServices();
        } else {
          _debugLog("❌ Connection failed: $e", type: 'ERROR');
        }
      }
    }
  }

  // try {
  //   // connect (no extra args)
  //   await _device!.connect(license: License.free);
  //   log('connect() returned (await completed)');
  // } catch (e) {
  //   log('connect() error: $e');
  //   // still try to discover services if connection succeeded partially
  //   // but normally if connect fails, abort
  // }

  Future<bool> checkAlreadyConnectedDevice() async {
    final systemConnected = await FlutterBluePlus.connectedDevices;

    if (systemConnected.isNotEmpty) {
      // Gunakan fungsi connectToDevice yang sudah kita perbaiki di atas
      // Kirim null untuk scanResult, tapi kirim device yang ditemukan
      log("Found existing device, re-attaching...");
      await connectToDevice(null, device: systemConnected.first);
      return true;
    }

    log("⚠️ No system connected BLE device.");
    return false;
  }

  /// Discover services and find HR characteristic
  Future<void> _discoverServices() async {
    if (_device == null) {
      log('discoverServices called but device==null');
      return;
    }

    try {
      final services = await _device!.discoverServices();
      log('discoverServices -> found ${services.length} services');

      for (final s in services) {
        log(
          'Service: ${s.uuid} characteristics: ${s.characteristics.map((c) => c.uuid).toList()}',
        );
        final su = s.uuid.toString().toLowerCase();
        if (su.contains('180d')) {
          log('Found Heart Rate service ${s.uuid}');
          for (final c in s.characteristics) {
            final cu = c.uuid.toString().toLowerCase();
            if (cu.contains('2a37')) {
              _hrChar = c;
              log('Found Heart Rate Measurement characteristic ${c.uuid}');
              await _subscribeToHr();
              return;
            }
          }
        }
      }
      log('Heart Rate service/characteristic NOT found');
    } catch (e) {
      log('discoverServices error: $e');
    }
  }

  /// Subscribe (notifications) to HR characteristic
  Future<void> _subscribeToHr() async {
    if (_hrChar == null) {
      _debugLog('❌ subscribeToHr called but _hrChar is null', type: 'ERROR');
      return;
    }
    try {
      await _hrChar!.setNotifyValue(true);
      _debugLog('✅ Notifications enabled successfully');
    } catch (e) {
      log('setNotifyValue error: $e');
      return;
    }
    // cancel previous charSub
    await _charSub?.cancel();

    _charSub = _hrChar!.onValueReceived.listen(
      (bytes) {
        _debugLog('📨 Raw HR data received: ${bytes.length} bytes');
        _debugLog('Raw bytes: $bytes');
        final parsed = _parseHeartRateAndRR(bytes);
        final bpm = parsed['bpm'] as int;
        final rr = parsed['rr'] as List<double>?;

        _debugLog('📊 Parsed HR: $bpm BPM, RR intervals: ${rr?.length ?? 0}');

        final rawData = RawHrModel(
          bpm: bpm,
          rrIntervals: rr,
          time: DateTime.now(),
        );
        _rawHrCtrl.add(rawData);
      },
      onError: (e) {
        log('char onValue error: $e');
      },
    );

    // ensure charSub canceled on device disconnect
    _device?.cancelWhenDisconnected(_charSub!, delayed: true, next: true);
    _debugLog('✅ HR subscription setup completed with disconnect handling');
  }

  Map<String, dynamic> _parseHeartRateAndRR(List<int> data) {
    if (data.isEmpty) return {'bpm': 0, 'rr': null};

    final flags = data[0];
    final hr16bit = (flags & 0x01) != 0;
    final hasRR = (flags & 0x10) != 0;

    int index = 1;
    int bpm = 0;

    // --- Heart rate value ---
    if (hr16bit) {
      if (data.length >= 3) {
        bpm = data[index] | (data[index + 1] << 8);
        index += 2;
      }
    } else {
      bpm = data[index];
      index += 1;
    }

    // --- Skip energy expended if present ---
    final hasEnergy = (flags & 0x08) != 0;
    if (hasEnergy && data.length >= index + 2) {
      index += 2;
    }

    // --- RR interval(s) ---
    List<double>? rrList;
    if (hasRR && data.length >= index + 2) {
      rrList = [];
      while (index + 1 < data.length) {
        int rrRaw = data[index] | (data[index + 1] << 8);
        double rrMs = rrRaw * 1000.0 / 1024; // convert ke ms
        rrList.add(rrMs);
        index += 2;
      }
    }
    return {'bpm': bpm, 'rr': rrList};
  }

  //prune history older than 1 hour
  void _pruneHistory() {
    final cutoff = DateTime.now().millisecondsSinceEpoch - (60 * 60 * 1000);
    final initialCount = _history.length;
    _history.removeWhere((h) => h.timestamp.millisecondsSinceEpoch < cutoff);
    final removed = initialCount - _history.length;
    if (removed > 0) {
      _debugLog('🧹 Pruned $removed old data points from history');
    }
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    log('Disconnect requested');
    await stopScan();

    try {
      await _charSub?.cancel();
    } catch (_) {}
    _charSub = null;

    try {
      await _connSub?.cancel();
    } catch (_) {}
    _connSub = null;

    if (_device != null) {
      try {
        await _device!.disconnect();
        log('device.disconnect() done');
      } catch (e) {
        log('device.disconnect() error: $e');
      }
      _device = null;
    }
  }

  /// dispose controllers/subscriptions (call from UI dispose)
  Future<void> dispose() async {
    await disconnect();
    await _scanSub?.cancel();
    _scanSub = null;
    if (!_statusCtrl.isClosed) _statusCtrl.close();
    if (!_hrCtrl.isClosed) _hrCtrl.close();
    if (!_scanResultsCtrl.isClosed) _scanResultsCtrl.close();
  }

  /// Public helper: compute latest RHR from cached history
  // double? rhrData() {
  //   return RHRService.computeRHR(_history);
  // }

  // /// Public helper: latest spatio temporal context (from PhoneSensorService)
  // SpatioTemporal? spatioData() {
  //   return _phoneSensorService.latestContext;
  // }

  /// Get debug statistics
  Map<String, dynamic> getDebugStats() {
    return {
      'totalDataPoints': _totalDataPoints,
      'hrvCalculations': _hrvCalculations,
      'firestoreSyncs': _firestoreSyncs,
      'hiveSaves': _hiveSaves,
      'historySize': _history.length,
      'isConnected': isConnected,
      'isScanning': _isScanning,
      'deviceName': _device?.platformName ?? 'No device',
    };
  }

  void printDebugReport() {
    _debugLog('''
    📊 BLESERVICE DEBUG REPORT:
    ┌─────────────────────────────────────
    │ Data Points Processed: $_totalDataPoints
    │ HRV Calculations: $_hrvCalculations
    │ Firestore Syncs: $_firestoreSyncs
    │ Hive Saves: $_hiveSaves
    │ History Size: ${_history.length}
    │ Connected: $isConnected
    │ Scanning: $_isScanning
    │ Device: ${_device?.platformName ?? 'None'}
    │ Last HRV: ${_hrvService.computeForStandardWindows()[60]?.rmssd?.toStringAsFixed(2) ?? 'N/A'}
    └─────────────────────────────────────
    ''', type: 'REPORT');
  }
}
