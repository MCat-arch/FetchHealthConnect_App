// import 'package:aura/model/health_day_data.dart';
// import 'package:aura/providers/health_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class DateDetail extends StatelessWidget {
//   const DateDetail({super.key, required this.date});

//   final String date;

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.read<HealthProvider>();
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Detail Kesehatan'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => provider.fetchLatestData(),
//           ),
//         ],
//       ),
//       body: StreamBuilder(
//         stream: provider.streamHealthDayData(date),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting ||
//               provider.isLoading) {
//             return Center(
//               child: CircularProgressIndicator(color: Colors.black),
//             );
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
//           }

//           final details = snapshot.data ?? [];

//           if (details.isEmpty) {
//             return Center(child: Text('Tidak ada data'));
//           }

//           return ListView.builder(
//             itemCount: details.length,
//             itemBuilder: (context, index) {
//               final dataDetail = details[index];
//               return Card(
//                 child: ListTile(
//                   title: const Text(
//                     'Detail Data',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const SizedBox(height: 4),
//                       Text('heart rate : ${dataDetail.hr ?? "-"}'),
//                       const SizedBox(height: 2),
//                       Text('steps : ${dataDetail.steps ?? "-"}'),
//                       Text(
//                         dataDetail.kategori,
//                         style: TextStyle(
//                           color: dataDetail.kategori.toLowerCase() == 'panic'
//                               ? Colors.red
//                               : Colors.black,
//                         ),
//                       ),
//                       Text(dataDetail.time),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:aura/model/health_day_data.dart';
import 'package:aura/providers/health_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DateDetail extends StatelessWidget {
  const DateDetail({super.key, required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HealthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kesehatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchLatestData(),
          ),
        ],
      ),
      body: StreamBuilder<List<HealthDayData>>(
        stream: provider.streamHealthDayData(date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final details = snapshot.data ?? [];

          if (details.isEmpty) {
            return const Center(child: Text('Tidak ada data'));
          }

          // Pisahkan berdasarkan kategori
          final exerciseData = details
              .where((d) => d.kategori.toLowerCase() == 'exercise')
              .toList();
          final panicData = details
              .where((d) => d.kategori.toLowerCase() == 'panichealth')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (exerciseData.isNotEmpty) ...[
                const Text(
                  '🏃‍♂️ Aktivitas Fisik (Exercise)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...exerciseData.map((data) => _buildExerciseCard(data)),
              ],

              const SizedBox(height: 24),

              if (panicData.isNotEmpty) ...[
                const Text(
                  '❤️‍🔥 Kesehatan Emosi (Panic Health)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...panicData.map((data) => _buildPanicCard(data)),
              ],

              if (exerciseData.isEmpty && panicData.isEmpty)
                const Center(child: Text('Belum ada data untuk kategori ini')),
            ],
          );
        },
      ),
    );
  }

  // 🏃 Exercise Data Card
  Widget _buildExerciseCard(HealthDayData data) {
    final e = data.exerciseData;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          'Waktu: ${data.time}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('Jarak: ${e?.distance?.toStringAsFixed(2) ?? "-"} m'),
            Text('Ketinggian: ${e?.altitude?.toStringAsFixed(2) ?? "-"} m'),
            Text('Pendakian: ${e?.ascent?.toStringAsFixed(2) ?? "-"} m'),
            Text(
              'Menit Intensitas Sedang: ${e?.mediumIntensityMinutes?.toStringAsFixed(0) ?? "-"}',
            ),
            Text(
              'Menit Intensitas Tinggi: ${e?.highIntensityMinutes?.toStringAsFixed(0) ?? "-"}',
            ),
            Text('Jam Aktif: ${e?.activeHours?.toStringAsFixed(1) ?? "-"} jam'),
            Text(
              'Aktivitas Harian: ${e?.dailyActivitySummary?.toStringAsFixed(1) ?? "-"}',
            ),
          ],
        ),
      ),
    );
  }

  // ❤️ Panic/Health Data Card
  Widget _buildPanicCard(HealthDayData data) {
    final p = data.panicData;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(
          'Waktu: ${data.time}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text('Detak Jantung: ${p?.heartRate ?? "-"} bpm'),
            Text('Stres: ${p?.stress?.toStringAsFixed(1) ?? "-"}'),
            Text('Tidur: ${p?.sleepHours?.toStringAsFixed(1) ?? "-"} jam'),
            Text(
              'Tekanan Darah: ${p?.systolicBP ?? "-"} / ${p?.diastolicBP ?? "-"} mmHg',
            ),
            Text('Saturasi Oksigen (SpO₂): ${p?.spo2 ?? "-"} %'),
            Text(
              'Suhu Tubuh: ${p?.bodyTemperature?.toStringAsFixed(1) ?? "-"} °C',
            ),
            Text(
              'Indeks Kesehatan Jantung: ${p?.heartHealthIndex?.toStringAsFixed(2) ?? "-"}',
            ),
            Text('Emosi: ${p?.emotion ?? "-"}'),
          ],
        ),
      ),
    );
  }
}
