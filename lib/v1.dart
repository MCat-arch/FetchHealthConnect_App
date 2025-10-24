// import 'package:flutter/material.dart';
// import 'package:health/health.dart';
// import 'package:permission_handler/permission_handler.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Health Connect Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const HealthDataPage(),
//     );
//   }
// }

// class HealthDataPage extends StatefulWidget {
//   const HealthDataPage({super.key});

//   @override
//   State<HealthDataPage> createState() => _HealthDataPageState();
// }

// class _HealthDataPageState extends State<HealthDataPage> {
//   List<HealthDataPoint> _healthData = [];
//   bool _isLoading = false;
//   String _errorMessage = '';

//   // 1. Define the data types you want to access
//   final _dataTypes = [
//     HealthDataType.HEART_RATE,
//     HealthDataType.STEPS,
//   ];

//   Future<void> _fetchHealthData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       // 2. Initialize Health Factory
//       Health health = Health();

//       // 3. Check if Health Connect is available
//       bool healthConnectAvailable = await health.isHealthConnectAvailable();
//       if (!healthConnectAvailable) {
//         throw Exception('Health Connect not available on this device');
//       }

//       // 4. Request permissions with explicit READ/WRITE
//       bool granted = await health.requestAuthorization(
//         _dataTypes,
//         permissions: [
//           HealthDataAccess.READ,
//           HealthDataAccess.READ,
//         ],
//       );

//       if (!granted) {
//         throw Exception('Permissions not granted');
//       }

//       // 5. Get data for the last 24 hours
//       DateTime now = DateTime.now();
//       DateTime yesterday = now.subtract(const Duration(days: 1));

//       List<HealthDataPoint> data = await health.getHealthDataFromTypes(
//         startTime: yesterday,
//         endTime: now,
//         types: _dataTypes,
//       );

//       setState(() {
//         _healthData = data;
//       });

//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Error: $e';
//       });
//       debugPrint('Health Data Error: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Health Data'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _fetchHealthData,
//           ),
//         ],
//       ),
//       body: _buildContent(),
//     );
//   }

//   Widget _buildContent() {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_errorMessage.isNotEmpty) {
//       return Center(child: Text(_errorMessage));
//     }

//     if (_healthData.isEmpty) {
//       return Center(
//         child: ElevatedButton(
//           onPressed: _fetchHealthData,
//           child: const Text('Fetch Health Data'),
//         ),
//       );
//     }

//     return ListView.builder(
//       itemCount: _healthData.length,
//       itemBuilder: (context, index) {
//         HealthDataPoint point = _healthData[index];
//         return ListTile(
//           title: Text('${point.type.toString().split('.').last}: ${point.value}'),
//           subtitle: Text('Source: ${point.sourceName}\nTime: ${point.dateFrom}'),
//           trailing: Text(point.unit.toString()),
//         );
//       },
//     );
//   }
// }