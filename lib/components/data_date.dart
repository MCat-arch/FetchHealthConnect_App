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
  bool loading = false;

  Future<void> refreshAll() async {
    setState(() => loading = true);
    await context.read<HealthProvider>().loadFromLocal();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dailyList = context.watch<HealthProvider>().dailyData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Kesehatan'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: refreshAll),
        ],
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : dailyList.isEmpty
              ? const Center(child: Text('Belum ada data kesehatan'))
              : ListView.builder(
                itemCount: dailyList.length,
                itemBuilder: (context, index) {
                  final dayData = dailyList[index];
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
              ),
    );
  }
}
