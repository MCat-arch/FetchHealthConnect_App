import 'package:app_aura/components/date_detail.dart';
import 'package:app_aura/model/health_day_data.dart';
import 'package:flutter/material.dart';
import 'package:app_aura/data/dummy.dart';

class DataDate extends StatelessWidget {
  const DataDate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: dummyHealthData.length,
      itemBuilder: (context, index) {
        String date = dummyHealthData[index].date;
        List<String> content =
            dummyHealthData[index].dateData.map((d) => d.kategori).toList();
        List<HealthDayData> data = dummyHealthData[index].dateData;
        return GestureDetector(
          key: ValueKey('item-$index'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DateDetail(detailData: data)),
            );
          },
          child: ListTile(
            title: Column(
              children: [
                Text(
                  '$date' ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('$content' ?? ''),
              ],
            ),
          ),
        );
      },
    );
  }
}
