import 'package:aura/model/health_data.dart';
import 'package:aura/providers/health_provider.dart';
import 'package:aura/routes/route.dart' as route;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ManualLabelPage extends StatelessWidget {
  const ManualLabelPage({super.key});

  Future<void> _saveData(BuildContext context, String kategori) async {
    final now = DateTime.now();
    final todayDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Ambil data terakhir dari provider (bukan storage langsung)
    final provider = context.read<HealthProvider>();
    final dailyData = provider.dailyData;

    int? hrValue;
    int? stepsValue;

    final todayData = dailyData.firstWhere(
      (d) => d.date == todayDate,
      orElse: () => HealthData(const Uuid().v4(), todayDate, 0, []),
    );

    hrValue = todayData.details.where((d) => d.hr != null).lastOrNull?.hr ?? 0;
    stepsValue =
        todayData.details.where((d) => d.steps != null).lastOrNull?.steps ?? 0;

    provider.addManualLabel(kategori, hr: hrValue, steps: stepsValue);

    print(
      '[ManualLabelPage] Saved via Provider: $kategori, HR=$hrValue, Steps=$stepsValue',
    );
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
                await _saveData(context, 'panic');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Label disimpan sebagai Panic')),
                );
                route.router.go('/home');
              },
              child: const Text('Ya, saya panic'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveData(context, 'no_panic');
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
