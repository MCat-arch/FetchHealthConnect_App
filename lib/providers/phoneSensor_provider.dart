import 'package:flutter/material.dart';
import 'package:aura_bluetooth/services/phone_sensor_service.dart';
import 'package:aura_bluetooth/models/spatio.model.dart';

class PhoneSensorProvider extends ChangeNotifier {
  final PhoneSensorService _service = PhoneSensorService();

  SpatioTemporal? _context;
  bool _isInitialized = false;
  
  // 🛠️ PERBAIKAN 1: Buat nullable, jangan 'late'
  VoidCallback? _listenerCallback; 

  PhoneSensorProvider() {
    _init();
  }

  // Getter
  SpatioTemporal? get latestContext => _context;
  bool get isInitialized => _isInitialized;

  Future<void> _init() async {
    // Provider bisa jadi didispose saat menunggu ini
    await _service.initialize(); 

    // Cek apakah provider sudah didispose sebelum lanjut (Opsional tapi bagus)
    if (!hasListeners) return; 

    // Definisikan callback
    _listenerCallback = () {
      _context = _service.currentContextNotifier.value;
      notifyListeners();
    };

    // listen ke currentContextNotifier
    // Gunakan tanda seru (!) karena kita baru saja mengisinya
    _service.currentContextNotifier.addListener(_listenerCallback!);

    // Ambil nilai awal
    _context = _service.currentContextNotifier.value;
    _isInitialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    // 🛠️ PERBAIKAN 2: Cek null sebelum remove
    // Jika _listenerCallback null, berarti _init belum selesai, jadi tidak perlu remove apa-apa.
    if (_listenerCallback != null) {
      _service.currentContextNotifier.removeListener(_listenerCallback!);
    }
    
    super.dispose();
  }
}