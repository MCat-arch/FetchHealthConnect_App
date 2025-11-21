// pages/heart_rate_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../models/heart_rate_model.dart';

class HeartRatePage extends StatefulWidget {
  const HeartRatePage({Key? key}) : super(key: key);

  @override
  State<HeartRatePage> createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> {
  final BLEService _ble = BLEService();

  StreamSubscription<String>? _statusSub;
  StreamSubscription<HeartRateData>? _hrSub;
  StreamSubscription<List<ScanResult>>? _scanResSub;

  String _status = 'Idle';
  HeartRateData? _current;
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();

    _statusSub = _ble.statusStream.listen((s) {
      setState(() => _status = s);
      debugPrint('UI STATUS: $s');
    });

    _hrSub = _ble.hrStream.listen((hr) {
      setState(() => _current = hr);
      debugPrint('UI HR: ${hr.bpm}');
    });

    _scanResSub = _ble.scanResultsStream.listen((list) {
      setState(() => _scanResults = list);
      debugPrint('UI SCAN RESULTS count: ${list.length}');
    });

    // start scan automatically once UI ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ble.startScan();
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _hrSub?.cancel();
    _scanResSub?.cancel();
    _ble.dispose();
    super.dispose();
  }

  Widget _buildScanList() {
    if (_scanResults.isEmpty) {
      return const Text('No devices found yet.');
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _scanResults.length,
      itemBuilder: (context, i) {
        final r = _scanResults[i];
        final advName = r.advertisementData.advName ?? '';
        final platformName = r.device.platformName ?? '';
        final displayName = advName.isNotEmpty
            ? advName
            : (platformName.isNotEmpty ? platformName : r.device.remoteId.str);
        return ListTile(
          title: Text(displayName),
          subtitle: Text('id: ${r.device.remoteId.str}  rssi: ${r.rssi}'),
          trailing: ElevatedButton(
            child: const Text('Connect'),
            onPressed: () async {
              await _ble.connectToDevice(r);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Heart Rate Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _ble.startScan(),
            tooltip: 'Rescan',
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: () => _ble.stopScan(),
            tooltip: 'Stop scan',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Status: $_status',
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  title: const Text('Latest HR'),
                  subtitle: _current == null
                      ? const Text('No HR received yet')
                      : Text(
                          '${_current!.bpm} bpm\n${_current!.timestamp.toLocal()}',
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ExpansionTile(
                  title: const Text('Scan Results'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _buildScanList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _ble.startScan(),
                icon: const Icon(Icons.search),
                label: const Text('Start Scan'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _ble.stopScan(),
                icon: const Icon(Icons.stop),
                label: const Text('Stop Scan'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _ble.disconnect(),
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
