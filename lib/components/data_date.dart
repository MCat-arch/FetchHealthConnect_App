import 'package:aura/components/date_detail.dart';
import 'package:aura/model/health_data.dart';
import 'package:aura/providers/health_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DataDate extends StatelessWidget {
  const DataDate({super.key});

  @override
  Widget build(BuildContext context) {
    final healthProvider = context.read<HealthProvider>();

    // Pastikan provider mulai listen saat widget dibangun pertama kali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      healthProvider.intialize();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Kesehatan Harian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
            onPressed: () => healthProvider.fetchLatestData(),
          ),
        ],
      ),
      body: StreamBuilder<List<HealthData>>(
        stream: healthProvider.healthDataStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              healthProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final dailyData = snapshot.data ?? [];
          if (dailyData.isEmpty) {
            return const Center(child: Text('Belum ada data kesehatan'));
          }

          return ListView.builder(
            itemCount: dailyData.length,
            itemBuilder: (context, index) {
              final data = dailyData[index];
              return Card(
                child: ListTile(
                  title: Text(
                    data.date,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Panic Count: ${data.panicCount}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DateDetail(date: data.date),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
