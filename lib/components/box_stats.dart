import 'package:app_aura/model/health_data.dart';
import 'package:app_aura/model/health_day_data.dart';
import 'package:flutter/material.dart';
import 'package:app_aura/data/dummy.dart';

class BoxStats extends StatefulWidget {
  const BoxStats({super.key});

  @override
  State<BoxStats> createState() => _BoxStatsState();
}

class _BoxStatsState extends State<BoxStats> {
  int totalData = dummyHealthData.fold(
    0,
    (sum, items) => sum + items.dateData.length,
  );
  int totalPanicData = dummyHealthData.fold(
    0,
    (sum, items) =>
        sum +
        items.dateData.where((d) => d.kategori.toLowerCase() == 'panic').length,
  );
  final data = dummyHealthData;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Image.asset('stats.png', height: 60, width: 60),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistik Kesehatan',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('- Data collected : ${totalData}'),
              Text('- Panic detected : $totalPanicData'),
            ],
          ),
        ],
      ),
    );
  }
}
