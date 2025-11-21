// pages/home_page.dart
import 'dart:async';
import 'package:aura_bluetooth/models/heart_rate_model.dart';
import 'package:aura_bluetooth/models/hrv_metric.dart';
import 'package:aura_bluetooth/services/ble_service.dart';
import 'package:aura_bluetooth/services/ml_panic_service.dart';
import 'package:aura_bluetooth/views/breathing_page.dart';
import 'package:aura_bluetooth/widgets/stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../providers/ble_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late BLEProvider _bleProvider;
  VoidCallback? _providerListener;
  PanicPrediction? _lastShownPanic;
  StreamSubscription<HeartRateData>? _hrSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProvider();
    });
  }

  void _initializeProvider() {
    _bleProvider = Provider.of<BLEProvider>(context, listen: false);

    // Auto start scan ketika app pertama kali dibuka
    if (!_bleProvider.isScanning && !_bleProvider.statusConnect) {
      _bleProvider.startScan();
    }

    // Setup listener untuk panic alerts
    _providerListener = () {
      final pred = _bleProvider.panicPrediction;
      if (pred != null && _shouldShowPanicAlert(pred)) {
        _lastShownPanic = pred;
        if (mounted) _showPanicAlert(pred);
      }
    };

    _bleProvider.addListener(_providerListener!);
  }

  bool _shouldShowPanicAlert(PanicPrediction prediction) {
    if (!prediction.isPanic) return false;
    if (_lastShownPanic == null) return true;

    // Show alert jika confidence berbeda signifikan (> 5%) atau panic status berubah
    return (prediction.confidence - _lastShownPanic!.confidence).abs() > 0.05 ||
        prediction.isPanic != _lastShownPanic!.isPanic;
  }

  Future<void> _showPanicAlert(PanicPrediction prediction) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false, // User harus tekan OK
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Panic Attack Detected'),
          ],
        ),
        content: Text(
          'High probability of panic attack detected '
          '(${(prediction.confidence * 100).toStringAsFixed(1)}% confidence).\n\n'
          'Please take deep breaths and find a comfortable position.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to breathing page jika mau
              // Navigator.push(context, MaterialPageRoute(builder: (_) => BreathingGuidePage()));
            },
            child: const Text('Breathing Exercise'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(BLEProvider ble) {
    final status = ble.status.toLowerCase();
    Color statusColor;
    IconData statusIcon;
    String statusText = ble.status;

    if (status.contains('connected')) {
      statusColor = Colors.green;
      statusIcon = Icons.bluetooth_connected;
    } else if (status.contains('connecting')) {
      statusColor = Colors.orange;
      statusIcon = Icons.bluetooth_searching;
      statusText = 'Connecting...';
    } else if (status.contains('scanning')) {
      statusColor = Colors.blue;
      statusIcon = Icons.search;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.bluetooth_disabled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard(BLEProvider ble) {
    // Gunakan watch untuk real-time updates
    final heartRate = ble.heartRate;

    if (heartRate == null) {
      return _buildPlaceholderCard(
        'Heart Rate',
        'Connect device to see data',
        Icons.favorite_border,
        color: Colors.grey,
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'HEART RATE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: heartRate.bpm > 100
                          ? Colors.red
                          : heartRate.bpm > 80
                          ? Colors.orange
                          : Colors.green,
                    ),
                    if (heartRate.rrIntervals == null ||
                        heartRate.rrIntervals!.isEmpty)
                      const Tooltip(
                        message: 'No RR Intervals - Basic HR only',
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${heartRate.bpm}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'BPM',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAdditionalInfo(heartRate),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo(HeartRateData hr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('RHR', '${hr.rhr.toStringAsFixed(1)} BPM'),
        _buildInfoRow('Activity', hr.phoneSensor.rawActivityStatus),
        _buildInfoRow(
          'Noise',
          '${hr.phoneSensor.noiseLeveldB?.toStringAsFixed(1) ?? 'N/A'} dB',
        ),
        _buildInfoRow('Time', hr.phoneSensor.timeOfDayCategory),
        if (hr.rrIntervals == null || hr.rrIntervals!.isEmpty)
          _buildInfoRow('RR Data', 'Not available', isWarning: true),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isWarning ? Colors.orange : Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isWarning ? Colors.orange : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHRVCards(BLEProvider ble) {
    final Map<int, HRVMetrics> metrics = ble.hrvMetrics;

    // Tampilkan HRV cards hanya jika ada data HRV
    final hasHRVData = metrics.values.any((m) => m.count > 0);

    if (!hasHRVData) {
      return _buildPlaceholderCard(
        'HRV Metrics',
        'HRV data will appear here\nwhen RR intervals are available',
        Icons.analytics_outlined,
        color: Colors.blue,
      );
    }

    return Column(
      children: [
        _buildHRVCard('HRV (60s)', metrics[60]),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildHRVCard('HRV (30s)', metrics[30])),
            const SizedBox(width: 12),
            Expanded(child: _buildHRVCard('HRV (10s)', metrics[10])),
          ],
        ),
      ],
    );
  }

  Widget _buildHRVCard(String title, HRVMetrics? metrics) {
    final hasData = metrics != null && metrics.count > 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            if (!hasData)
              const Text(
                'No data',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              )
            else ...[
              _buildHRVMetricRow(
                'RMSSD',
                '${metrics.rmssd?.toStringAsFixed(1) ?? 'N/A'} ms',
              ),
              _buildHRVMetricRow(
                'SDNN',
                '${metrics.sdnn?.toStringAsFixed(1) ?? 'N/A'} ms',
              ),
              _buildHRVMetricRow(
                'pNN50',
                '${metrics.pnn50?.toStringAsFixed(1) ?? 'N/A'}%',
              ),
              _buildHRVMetricRow('Samples', '${metrics.count}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHRVMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningSection(BLEProvider ble) {
    // Tampilkan scanning section hanya jika tidak connected dan perlu scan
    final shouldShow =
        !ble.statusConnect && (ble.isScanning || ble.scanResults.isNotEmpty);

    if (!shouldShow) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AVAILABLE DEVICES',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (ble.isScanning)
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Scanning...', style: TextStyle(fontSize: 12)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDeviceList(ble),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(BLEProvider ble) {
    final List<ScanResult> results = ble.scanResults;

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No devices found', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 4),
            Text(
              'Make sure your heart rate monitor is turned on and in range',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: results.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final device = results[index];
          final advName = device.advertisementData.advName?.trim() ?? '';
          final platformName = device.device.platformName?.trim() ?? '';

          String displayName = advName.isNotEmpty
              ? advName
              : platformName.isNotEmpty
              ? platformName
              : 'Unknown Device';

          return ListTile(
            leading: const Icon(Icons.fitness_center, color: Colors.blue),
            title: Text(displayName),
            subtitle: Text(
              'RSSI: ${device.rssi} • ${device.device.remoteId.str}',
            ),
            trailing: ElevatedButton(
              onPressed: () => ble.connectTo(device),
              child: const Text('Connect'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderCard(
    String title,
    String subtitle,
    IconData icon, {
    Color color = Colors.grey,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color.withOpacity(0.6)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: color.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BLEProvider ble) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (!ble.statusConnect) ...[
              ElevatedButton.icon(
                onPressed: ble.isScanning ? ble.stopScan : ble.startScan,
                icon: Icon(ble.isScanning ? Icons.stop : Icons.search),
                label: Text(ble.isScanning ? 'Stop Scan' : 'Start Scan'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => ble.disconnect(),
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: ble.startScan,
              tooltip: 'Rescan Devices',
            ),
            if (ble.statusConnect) ...[
              IconButton(
                icon: const Icon(Icons.psychology),
                onPressed: () {
                  // Navigate to breathing exercise
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BreathingGuidePage()),
                  );
                },
                tooltip: 'Breathing Exercise',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(BLEProvider ble) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Health Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatisticsWidget()),
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildQuickStatsPreview(ble),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsPreview(BLEProvider ble) {
    final hr = ble.heartRate;
    final hrvMetrics = ble.hrvMetrics[60];

    if (hr == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Connect device to see statistics',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQuickStat('HR', '${hr.bpm}', 'BPM', Colors.red),
        _buildQuickStat(
          'HRV',
          hrvMetrics?.rmssd?.toStringAsFixed(1) ?? 'N/A',
          'ms',
          Colors.blue,
        ),
        _buildQuickStat('RHR', '${hr.rhr.toInt()}', 'BPM', Colors.green),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        if (unit.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ],
    );
  }

  // Di HomePage, tambahkan debug button
  Widget _buildDebugButton() {
    return IconButton(
      icon: Icon(Icons.bug_report),
      onPressed: () {
        // Access BLEService melalui provider atau langsung
        final stats = BLEService().getDebugStats();

        // Atau show dialog dengan stats
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Debug Report'),
            content: SingleChildScrollView(child: Text(stats.toString())),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BLEProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AURA Health Monitor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildConnectionStatus(ble),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heart Rate & HRV Cards
              SizedBox(
                height: 220, // Fixed height untuk consistency
                child: Row(
                  children: [
                    Expanded(flex: 2, child: _buildHeartRateCard(ble)),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: _buildHRVCards(ble)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Device Scanning Section
              _buildScanningSection(ble),

              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(ble),

              const SizedBox(height: 20),

              // Statistics Section
              _buildStatisticsSection(ble),

              // Bottom padding untuk safe area
              const SizedBox(height: 20),
              _buildDebugButton(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hrSubscription?.cancel();
    if (_providerListener != null) {
      _bleProvider.removeListener(_providerListener!);
    }
    super.dispose();
  }
}
