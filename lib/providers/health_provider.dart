// providers/health_provider.dart
import 'dart:convert';
import 'package:aura/model/health_day_data.dart';
import 'package:aura/services/health_service.dart';
import 'package:aura/utils/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../model/health_data.dart';

class HealthProvider extends ChangeNotifier {
  List<HealthData> _dailyData = [];

  List<HealthData> get dailyData => _dailyData;
  bool isLoading = false;

  Future<void> loadData({bool forceRefresh = false}) async {
    isLoading = true;
    notifyListeners();

    final grouped = await HealthService.getHealthData(
      forceRefresh: forceRefresh,
    );
    _dailyData = grouped.entries.map((entry) {
      final panicCount = entry.value.where((d) => d.kategori == 'panic').length;
      return HealthData(
        const Uuid().v4(), // atau gunakan date sebagai id jika unik
        entry.key, // dateKey
        panicCount,
        entry.value,
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    isLoading = false;
    notifyListeners();
  }

  Future<void> addManualLabel(String kategori, {int? hr, int? steps}) async {
    await HealthService.addManualLabel(kategori, hr: hr, steps: steps);
    await loadData(forceRefresh: false);
  }

  // Future<void> addManualLabel(String kategori, {int? hr, int? steps}) async {
  //   final now = DateTime.now();
  //   final todayDate =
  //       "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

  //   HealthData? existing = _dailyData.firstWhere(
  //     (d) => d.date == todayDate,
  //     orElse: () => HealthData(const Uuid().v4(), todayDate, 0, []),
  //   );

  //   final newDetail = HealthDayData(
  //     kategori,
  //     now.toIso8601String(),
  //     hr ?? 0,
  //     steps ?? 0,
  //   );

  //   // tambah ke existing
  //   final updatedDetails = [...existing.details, newDetail];

  //   final panicCount = updatedDetails
  //       .where((d) => d.kategori == 'panic')
  //       .length;

  //   final updated = HealthData(
  //     existing.id,
  //     existing.date,
  //     panicCount,
  //     updatedDetails,
  //   );

  //   final idx = _dailyData.indexWhere((d) => d.date == todayDate);
  //   if (idx >= 0) {
  //     _dailyData[idx] = updated;
  //   } else {
  //     _dailyData.add(updated);
  //   }

  //   // urutkan & simpan
  //   _dailyData.sort((a, b) => b.date.compareTo(a.date));
  //   await StorageHelper.saveData(_dailyData);

  //   notifyListeners();
}

//   Future<void> loadFromLocal() async {
//     await HealthService.ensurePermissions();
//     final cached = await StorageHelper.loadFromLocal();
//     if (cached != null) {
//       _dailyData = cached;
//     }
//     final fetched = await HealthService.fetchHealthDataRaw(start, end);
//     for (var data in fetched) {
//       final isExisting = _dailyData.indexWhere((d) => d.id == data.id);
//       if (isExisting >= 0) {
//         _dailyData[isExisting] = data;
//       } else {
//         _dailyData.add(data);
//       }
//     }
//     await StorageHelper.saveData(_dailyData);
//     notifyListeners();
//   }

//   /// Load hanya dari SharedPreferences, tanpa fetch online
//   Future<void> loadLocalOnly() async {
//     final cached = await StorageHelper.loadFromLocal();
//     if (cached != null) {
//       _dailyData = cached;
//       notifyListeners();
//     }
//   }

//   /// Fetch online lalu simpan ke SharedPreferences
//   Future<void> fetchAndSave() async {
//     // await HealthService.ensurePermissions();
//     final fetched = await HealthService.fetchData(true);

//     // Gabungkan dengan data lama
//     for (var data in fetched) {
//       final index = _dailyData.indexWhere((d) => d.date == data.date);
//       if (index >= 0) {
//         _dailyData[index] = data;
//       } else {
//         _dailyData.add(data);
//       }
//     }

//     _dailyData.sort((a, b) => b.date.compareTo(a.date));

//     // Simpan ke local
//     await StorageHelper.saveData(_dailyData);
//     notifyListeners();
//   }
// }

//   // Future<void> saveToLocal() async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   final jsonString = jsonEncode(_dailyData.map((e) => e.toJson()).toList());
//   //   await prefs.setString('daily_health_data', jsonString);
//   // }
