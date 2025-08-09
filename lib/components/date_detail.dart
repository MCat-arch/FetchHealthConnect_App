import 'package:app_aura/model/health_day_data.dart';
import 'package:app_aura/services/health_service.dart';
import 'package:flutter/material.dart';

class DateDetail extends StatefulWidget {
  const DateDetail({super.key, required this.data});

  final List<HealthDayData>? data;

  @override
  State<DateDetail> createState() => _DateDetailState();
}

class _DateDetailState extends State<DateDetail> {
  List<HealthDayData>? _details;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _details = widget.data;
  }

  Future<void> refreshDetail() async {
    setState(() => _loading = true);
    final fetched = await HealthService.fetchData();
    setState(() {
      _details = fetched.isNotEmpty ? fetched.first.details : [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;
    if (details == null || details.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Kesehatan'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: refreshDetail,
            ),
          ],
        ),
        body:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : const Center(child: Text('Tidak ada data detail')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kesehatan'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: refreshDetail),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
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
                          Text(
                            'heart rate : ${dataDetail.hr?.toString() ?? "-"}',
                          ),
                          SizedBox(height: 2),
                          Text(
                            'steps : ${dataDetail.steps?.toString() ?? "-"}',
                          ),
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
