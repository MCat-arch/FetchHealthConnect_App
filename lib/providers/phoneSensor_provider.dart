import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:aura_bluetooth/models/spatio.model.dart';

class PhoneSensorProvider extends ChangeNotifier {

  SpatioTemporal? _context;
  
  // Kita inisialisasi dengan nilai default/kosong agar UI tidak error
  SpatioTemporal get latestContext => _context ?? SpatioTemporal.empty();

  PhoneSensorProvider() {
    _initBackgroundListener();
  }

  void _initBackgroundListener() {
    // Listen data dari Background Task
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map<dynamic, dynamic>) {
      final mapData = Map<String, dynamic>.from(data);

      // Cek apakah ini data sensor (sesuai tag 'type' di Langkah 1)
      if (mapData['type'] == 'sensor_update') {
        try {
          final sensorJson = Map<String, dynamic>.from(mapData['data']);
          _context = SpatioTemporal.fromJson(sensorJson);
          
          // Update UI
          notifyListeners();
          
          // print("📱 UI Updated: ${_context!.rawActivityStatus}");
        } catch (e) {
          print("❌ Error parsing sensor data in UI: $e");
        }
      }
    }
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }
}

// import 'package:flutter/material.dart';
// import 'package:aura_bluetooth/services/phone_sensor_service.dart';
// import 'package:aura_bluetooth/models/spatio.model.dart';

// class PhoneSensorProvider extends ChangeNotifier {
//   final PhoneSensorService _service = PhoneSensorService();

//   SpatioTemporal? _context;
//   bool _isInitialized = false;
  
//   // 🛠️ PERBAIKAN 1: Buat nullable, jangan 'late'
//   VoidCallback? _listenerCallback; 

//   PhoneSensorProvider() {
//     _init();
//   }

//   // Getter
//   SpatioTemporal? get latestContext => _context;
//   bool get isInitialized => _isInitialized;

//   Future<void> _init() async {
//     // Provider bisa jadi didispose saat menunggu ini
//     await _service.initialize(); 

//     // Cek apakah provider sudah didispose sebelum lanjut (Opsional tapi bagus)
//     if (!hasListeners) return; 

//     // Definisikan callback
//     _listenerCallback = () {
//       _context = _service.currentContextNotifier.value;
//       notifyListeners();
//     };

//     // listen ke currentContextNotifier
//     // Gunakan tanda seru (!) karena kita baru saja mengisinya
//     _service.currentContextNotifier.addListener(_listenerCallback!);

//     // Ambil nilai awal
//     _context = _service.currentContextNotifier.value;
//     _isInitialized = true;
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     // 🛠️ PERBAIKAN 2: Cek null sebelum remove
//     // Jika _listenerCallback null, berarti _init belum selesai, jadi tidak perlu remove apa-apa.
//     if (_listenerCallback != null) {
//       _service.currentContextNotifier.removeListener(_listenerCallback!);
//     }
    
//     super.dispose();
//   }
// }