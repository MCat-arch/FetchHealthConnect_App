import 'package:flutter/material.dart';
import 'package:aura_bluetooth/services/phone_sensor_service.dart';
import 'package:aura_bluetooth/models/spatio.model.dart';

class PhoneSensorProvider extends ChangeNotifier {
  final PhoneSensorService _service = PhoneSensorService();

  SpatioTemporal? _context;
  bool _isInitialized = false;
  late VoidCallback _listenerCallback;

  PhoneSensorProvider() {
    _init();
  }

  // Getter
  SpatioTemporal? get latestContext => _context;
  bool get isInitialized => _isInitialized;

  Future<void> _init() async {
    await _service.initialize();

    // Definisikan callback
    _listenerCallback = () {
      _context = _service.currentContextNotifier.value;
      notifyListeners();
    };

    // listen ke currentContextNotifier
    _service.currentContextNotifier.addListener(_listenerCallback);

    _context = _service.currentContextNotifier.value;
    _isInitialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.currentContextNotifier.removeListener(_listenerCallback);
    super.dispose();
  }
}
