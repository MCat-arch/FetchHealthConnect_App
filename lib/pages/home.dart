import 'package:aura/components/box_stats.dart';
import 'package:aura/components/data_date.dart';
import 'package:aura/pages/manual_input_form.dart';
import 'package:aura/providers/health_provider.dart';
import 'package:aura/services/health_service.dart';
import 'package:aura/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('Home initState called');
  }

  @override
  bool get wantKeepAlive => true; // Pertahankan state Home

  @override
  Widget build(BuildContext context) {
    super.build(
      context,
    ); // Panggil super.build untuk AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(15)),
            const BoxStats(),
            const Expanded(child: DataDate()),
            ElevatedButton(
              onPressed: () async {
                await NotificationService().showNotification();
              },
              child: const Text('Simulasi Panic Notifikasi'),
            ),
            if (_isLoading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManualLabelPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
