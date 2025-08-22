import 'package:aura/model/health_data.dart';
import 'package:aura/model/health_day_data.dart';
import 'package:aura/services/health_service.dart';
import 'package:aura/utils/storage_helper.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:aura/routes/route.dart' as route;

class ManualLabelPage extends StatelessWidget {
  const ManualLabelPage({super.key});

  Future<void> _saveData(String kategori) async {
    final lastData = await StorageHelper.loadFromLocal() ?? [];
    final now = DateTime.now();
    final todayDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Ambil data terbaru dari HealthService
    final healthDataList = await HealthService.fetchData(false);

    // Cari data HR & Steps terdekat dengan waktu sekarang
    int? hrValue;
    int? stepsValue;

    for (var dayData in healthDataList) {
      if (dayData.date == todayDate) {
        // Ambil HR terbaru
        hrValue = dayData.details
            .where((d) => d.hr != null)
            .toList()
            .lastOrNull
            ?.hr;

        // Ambil Steps terbaru
        stepsValue = dayData.details
            .where((d) => d.steps != null)
            .toList()
            .lastOrNull
            ?.steps;
        break;
      }
    }

    // Kalau tidak ketemu, set default 0
    hrValue ??= 0;
    stepsValue ??= 0;

    // Buat detail baru manual label
    final newDetail = HealthDayData(
      kategori,
      now.toIso8601String(),
      hrValue,
      stepsValue,
    );

    // Cek apakah sudah ada data untuk hari ini
    HealthData? existingDayData = lastData.firstWhere(
      (d) => d.date == todayDate,
      orElse: () => HealthData(const Uuid().v4(), todayDate, 0, []),
    );

    // Tambah detail manual
    existingDayData.details.add(newDetail);

    // Hitung ulang panicCount
    final panicCount = existingDayData.details
        .where((d) => d.kategori == 'panic')
        .length;
    existingDayData = HealthData(
      existingDayData.id,
      existingDayData.date,
      panicCount,
      existingDayData.details,
    );

    // Update list di storage
    final index = lastData.indexWhere((d) => d.date == todayDate);
    if (index >= 0) {
      lastData[index] = existingDayData;
    } else {
      lastData.add(existingDayData);
    }

    await StorageHelper.saveData(lastData);
    print('[ManualLabelPage] Saved: $kategori, HR=$hrValue, Steps=$stepsValue');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Label')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Apakah kamu sedang mengalami panic attack?'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _saveData('panic');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Label disimpan sebagai Panic')),
                );
                route.router.go('/home');
              },
              child: const Text('Ya, saya panic'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveData('no_panic');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Label disimpan sebagai Tidak Panic'),
                  ),
                );
                route.router.go('/home');
              },
              child: const Text('Tidak, saya baik-baik saja'),
            ),
          ],
        ),
      ),
    );
  }
}
