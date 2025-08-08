import 'package:app_aura/model/health_day_data.dart';
import 'package:flutter/material.dart';

class DateDetail extends StatefulWidget {
  const DateDetail({super.key, required this.data});

  final List<HealthDayData>? data;

  @override
  State<DateDetail> createState() => _DateDetailState();
}

class _DateDetailState extends State<DateDetail> {
  @override
  @override
  Widget build(BuildContext context) {
    if (widget.data == null || widget.data!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Kesehatan')),
        body: const Center(child: Text('Tidak ada data detail')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kesehatan')),
      body: ListView.builder(
        itemCount: widget.data!.length,
        itemBuilder: (context, index) {
          final dataDetail = widget.data![index];
          return Card(
            child: ListTile(
              title: Text(
                'Detail Data',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('heart rate : ${dataDetail.hr.toString()}'),
                  SizedBox(height: 2),
                  Text('steps : ${dataDetail.steps.toString()}'),
                  Text(
                    dataDetail.kategori,
                    style: TextStyle(
                      color:
                          dataDetail.kategori.toLowerCase() == 'panic'
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
      ),
    );
  }
}
