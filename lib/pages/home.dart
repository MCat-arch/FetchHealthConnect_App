import 'package:app_aura/components/box_stats.dart';
import 'package:app_aura/components/data_date.dart';
import 'package:app_aura/pages/manual_input_form.dart';
import 'package:app_aura/providers/health_provider.dart';
import 'package:app_aura/services/health_service.dart';
import 'package:app_aura/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isLoading = false;
  String? _error;

  Future<void> _fetchAndSaveHealthData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Sekaligus minta permission dan fetch data
      // final data = await HealthService.fetchData();
      await Provider.of<HealthProvider>(context, listen: false).loadFromLocal();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Health data updated!')));
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestHealthPermission() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await HealthService.requestRuntimePermissions();
      await HealthService.ensurePermissions();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Permission granted!')));
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Permission error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   // Bisa otomatis fetch di awal, atau hapus jika ingin manual lewat tombol
  //   _fetchAndSaveHealthData();
  //   // Future.microtask(
  //   //   () => Provider.of<HealthProvider>(context, listen: false).loadFromLocal(),
  //   // );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user),
            tooltip: 'Request Health Connect Permission',
            onPressed: _isLoading ? null : _requestHealthPermission,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Fetch Health Data',
            onPressed: _isLoading ? null : _fetchAndSaveHealthData,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(15)),
            BoxStats(),
            Expanded(child: DataDate()),
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
                child: Text(_error!, style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManualInputForm()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
