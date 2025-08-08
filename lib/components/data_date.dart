// lib/components/data_date.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_aura/model/health_data.dart';
import 'package:app_aura/components/date_detail.dart';
import 'package:app_aura/providers/health_provider.dart';

class DataDate extends StatefulWidget {
  const DataDate({super.key});

  @override
  State<DataDate> createState() => _DataDateState();
}

class _DataDateState extends State<DataDate> {
  @override
  Widget build(BuildContext context) {
    // Ambil list HealthData dari provider
    final dailyList = context.watch<HealthProvider>().dailyData;

    if (dailyList.isEmpty) {
      return const Center(child: Text('Belum ada data kesehatan'));
    }

    return ListView.builder(
      itemCount: dailyList.length,
      itemBuilder: (context, index) {
        final dayData = dailyList[index]; // HealthData
        return GestureDetector(
          key: ValueKey('day-${dayData.date}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DateDetail(data: dayData.details),
              ),
            );
          },
          child: ListTile(
            title: Text(
              dayData.date,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text('Panic count: ${dayData.panicCount}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }
}
