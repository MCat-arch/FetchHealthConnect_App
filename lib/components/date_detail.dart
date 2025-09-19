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
      body: StreamBuilder(
        stream: provider.streamHealthDayData(date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final details = snapshot.data ?? [];

          if (details.isEmpty) {
            return Center(child: Text('Tidak ada data'));
          }

          return ListView.builder(
            itemCount: details.length,
            itemBuilder: (context, index) {
              final dataDetail = details[index];
              return Card(
                child: ListTile(
                  title: const Text(
                    'Detail Data',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('heart rate : ${dataDetail.hr ?? "-"}'),
                      const SizedBox(height: 2),
                      Text('steps : ${dataDetail.steps ?? "-"}'),
                      Text(
                        dataDetail.kategori,
                        style: TextStyle(
                          color: dataDetail.kategori.toLowerCase() == 'panic'
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                      Text(dataDetail.time),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
