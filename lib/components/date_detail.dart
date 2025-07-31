import 'package:app_aura/model/health_day_data.dart';
import 'package:flutter/material.dart';

class DateDetail extends StatefulWidget {
  const DateDetail({super.key, required this.detailData});
  final List<HealthDayData> detailData;

  @override
  State<DateDetail> createState() => _DateDetailState();
}

class _DateDetailState extends State<DateDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detail Kesehatan")),
      body: ListView.builder(
        itemCount: widget.detailData.length,
        itemBuilder: (context, index) {
          final data = widget.detailData[index];
          return Container(
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('${data.content}'),
                  Text(
                    data.kategori,
                    style: TextStyle(
                      color:
                          data.kategori.toLowerCase() == 'panic'
                              ? Colors.red
                              : Colors.black,
                    ),
                  ),
                  Text('${data.time}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
