// providers/health_provider.dart
import 'package:flutter/material.dart';
import 'package:aura/model/health_data.dart';
import 'package:aura/model/health_day_data.dart';
import 'package:aura/services/health_service.dart';
import 'package:aura/utils/storage_helper.dart';

class HealthProvider extends ChangeNotifier {
  /// ✅ Stream semua healthData (summary harian)
  Stream<List<HealthData>> get healthDataStream =>
      StorageHelper.streamAllHealthData();

  /// ✅ Cache data terakhir untuk penggunaan cepat di UI
  List<HealthData> _dailyData = [];
  List<HealthData> get dailyData => _dailyData;

  /// ✅ Loading state (untuk menampilkan spinner di UI)
  bool isLoading = false;

  bool _initialized = false;

  Future<void> intialize() async {
    if (_initialized) return;

    isLoading = true;
    notifyListeners();

    try {
      // initialFetch: fetch 24 jam terakhir, dedupe, simpan ke Firestore
      await HealthService.initialFetch();
    } catch (e, st) {
      // optionally log atau tampilkan error
      print('[HealthProvider] initialFetch failed: $e\n$st');
    } finally {
      // mulai listen ke Firestore stream (UI akan auto update)
      listenToHealthData();
    }
  }

  /// ✅ Start listen Firestore stream dan simpan data ke memory
  void listenToHealthData() {
    isLoading = true;
    notifyListeners();

    StorageHelper.streamAllHealthData().listen((data) {
      _dailyData = data;
      isLoading = false;
      notifyListeners();
    });
  }

  /// ✅ Stream data detail per hari
  Stream<List<HealthDayData>> streamHealthDayData(String date) {
    return StorageHelper.streamHealthDayData(date);
  }

  /// ✅ Trigger background fetch manual (misal: pull to refresh)
  Future<void> fetchLatestData() async {
    isLoading = true;
    notifyListeners();

    await HealthService.backgroundFetch();

    isLoading = false;
    notifyListeners();
  }

  /// ✅ Tambah data manual
  // Future<void> addManualLabel(String kategori, {int? hr, int? steps}) async {
  //   await HealthService.addManualLabel(kategori, hr: hr, steps: steps);
  //   // Tidak perlu reload manual karena Firestore stream otomatis update
  // }
}
