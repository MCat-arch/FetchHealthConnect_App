// // services/data_aggregation_service.dart
// import 'dart:async';
// // Impor semua yang dibutuhkan untuk agregasi dan sinkronisasi:
// import 'package:aura_bluetooth/models/hrv_metric.dart';
// import 'package:aura_bluetooth/models/raw_hr_model.dart';
// import 'package:aura_bluetooth/models/spatio.model.dart';
// import 'package:aura_bluetooth/services/ble_service.dart'; // Impor BLEService Singleton
// import 'package:aura_bluetooth/services/firestore_service.dart';
// import 'package:aura_bluetooth/services/hrv_service.dart';
// import 'package:aura_bluetooth/services/ml_panic_service.dart';
// import 'package:aura_bluetooth/services/phone_sensor_service.dart';
// import 'package:aura_bluetooth/services/rhr_service.dart';
// import '../models/heart_rate_model.dart';
// import 'package:hive/hive.dart';
// import 'package:flutter/foundation.dart';

// class DataAggregationService extends ChangeNotifier {
//   // Dependency Injection: Service ini menerima semua yang ia butuhkan!
//   final BLEService _bleService;
//   final PhoneSensorService _phoneSensorService;
//   final HRVService _hrvService;
//   final RHRService _rhrService;
//   final FirestoreService _firestoreService;
//   final MLPanicService _mlService;

//   StreamSubscription? _bleSub;
//   final List<HeartRateData> _history = []; // History kini ada di sini

//   // Output Stream (untuk UI)
//   final StreamController<HeartRateData> _finalHrCtrl =
//       StreamController<HeartRateData>.broadcast();
//   Stream<HeartRateData> get finalHrStream => _finalHrCtrl.stream;
//   final List<double> _accumulateRR = [];
//   Timer? _aggregationTimer;

//   // Constructor (DI)
//   DataAggregationService({
//     required BLEService bleService,
//     required PhoneSensorService phoneSensorService,
//     required HRVService hrvService,
//     required RHRService rhrService,
//     required FirestoreService firestoreService,
//     required MLPanicService mlService,
//   }) : _bleService = bleService,
//        _phoneSensorService = phoneSensorService,
//        _hrvService = hrvService,
//        _rhrService = rhrService,
//        _firestoreService = firestoreService,
//        _mlService = mlService {
//     // Mulai mendengarkan data mentah BLE
//     _startListeningToBLE();
//   }

//   void _startListeningToBLE() {
//     _aggregationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
//       _processAndAggregateData();
//     });

//     _bleSub = _bleService.rawHrStream.listen((rawData) {
//       // Cukup akumulasi RR interval
//       if (rawData.rrIntervals != null) {
//         _accumulateRR.addAll(rawData.rrIntervals);
//       }
//     });
//   }

//   Future<void> _processAndAggregateData() async {
//     // // 1. Hitung HRV
//     // if (raw.rrIntervals != null && raw.rrIntervals!.isNotEmpty) {
//     //   for (var r in raw.rrIntervals!) {
//     //     _hrvService.addRR(r, raw.time.millisecondsSinceEpoch);
//     //   }
//     // }

//     final List<double> rrSnapshot = List.from(_accumulateRR);
//     _accumulateRR.clear();

//     if (rrSnapshot.isEmpty) {
//       if (kDebugMode)
//         print(
//           '[Aggregator] No RR data received in the last minute. Skipping sync.',
//         );
//       return;
//     }
//     // 2. Hitung BPM rata-rata
//     // Untuk data 1 menit, BPM terbaik dihitung dari RR snapshot.
//     final double averageRR =
//         rrSnapshot.reduce((a, b) => a + b) / rrSnapshot.length;
//     // BPM = 60000 / Rata-rata RR (dalam ms)
//     final int aggregatedBPM = (60000 / averageRR).round();

//     rrSnapshot.forEach((r) {
//       _hrvService.addRR(r, DateTime.now().millisecondsSinceEpoch);
//     });
//     final hrvMetrics = _hrvService.computeForStandardWindows();

//     // Ambil Data Sensor Ponsel
//     // **ASUMSI:** PhoneSensorService mengelola statusnya sendiri dan `latestContext` aman diakses.
//     final SpatioTemporal spatio =
//         _phoneSensorService.latestContext ?? SpatioTemporal.empty();

//     // 3. Hitung RHR (dari history di kelas ini)
//     final double rhr = _rhrService.computeRHR(_history) ?? 0.0;

//     // 4. Gabungkan menjadi model HeartRateData FINAL
//     final hrFinal = HeartRateData(
//       aggregatedBPM,
//       DateTime.now(),
//       rrSnapshot,
//       hrvMetrics[10],
//       hrvMetrics[30],
//       hrvMetrics[60],
//       rhr,
//       spatio,
//     );

//     // 5. Simpan ke History dan Hive
//     _history.add(hrFinal);
//     _pruneHistory();
//     await _saveToHive(hrFinal);

//     // 6. Sinkronisasi ke Firestore
//     await _firestoreService.syncHeartRateData(hrFinal);

//     // 7. Deteksi ML
//     final prediction = await _mlService.predictPanicAttack(hrFinal);
//     if (prediction.isPanic && prediction.confidence > 0.7) {
//       // Trigger notifikasi, alert, dll.
//     }

//     // 8. Emit data final ke UI
//     _finalHrCtrl.add(hrFinal);
//     notifyListeners(); // Untuk Consumer/Selector di UI
//   }

//   // Pindahkan fungsi pruning history ke sini
//   void _pruneHistory() {
//     final cutoff = DateTime.now().millisecondsSinceEpoch - (60 * 60 * 1000);
//     _history.removeWhere((h) => h.timestamp.millisecondsSinceEpoch < cutoff);
//   }

//   // Pindahkan fungsi Hive ke sini
//   Future<void> _saveToHive(HeartRateData hr) async {
//     try {
//       final box = Hive.box('hr_box');
//       final key = hr.timestamp.millisecondsSinceEpoch.toString();
//       final jsonMap = hr
//           .toJson(); // Pastikan HeartRateData memiliki method toJson()
//       await box.put(key, jsonMap);
//     } catch (e) {
//       if (kDebugMode) print('Error saving to Hive: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _bleSub?.cancel();
//     _aggregationTimer?.cancel();
//     _finalHrCtrl.close();
//     super.dispose();
//   }
// }
