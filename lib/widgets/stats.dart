// // widgets/statistics_widget.dart
// import 'package:aura_bluetooth/models/health_statistic.dart';
// import 'package:aura_bluetooth/services/statistic_service.dart';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

// class StatisticsWidget extends StatefulWidget {
//   const StatisticsWidget({Key? key}) : super(key: key);

//   @override
//   State<StatisticsWidget> createState() => _StatisticsWidgetState();
// }

// class _StatisticsWidgetState extends State<StatisticsWidget>
//     with SingleTickerProviderStateMixin {
//   //final StatisticsService _statsService = StatisticsService();
//   late TabController _tabController;

//   HealthStatistics? _todayStats;
//   HealthStatistics? _weeklyStats;
//   List<DailySummary>? _dailySummaries;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _loadStatistics();
//   }

//   Future<void> _loadStatistics() async {
//     setState(() => _isLoading = true);

//     try {
//       final today = await _statsService.getTodayStatistics();
//       final weekly = await _statsService.getWeeklyStatistics();
//       final daily = await _statsService.getDailySummaries();

//       setState(() {
//         _todayStats = today;
//         _weeklyStats = weekly;
//         _dailySummaries = daily;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('[Statistics] Error loading stats: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Health Statistics'),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'Today'),
//             Tab(text: 'Weekly'),
//             Tab(text: 'Trends'),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadStatistics,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildTodayTab(),
//                 _buildWeeklyTab(),
//                 _buildTrendsTab(),
//               ],
//             ),
//     );
//   }

//   Widget _buildTodayTab() {
//     if (_todayStats == null || _todayStats!.dataPoints == 0) {
//       return _buildEmptyState('No data collected today');
//     }

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           // Summary Cards
//           _buildSummaryCards(_todayStats!),

//           const SizedBox(height: 20),

//           // Activity Distribution
//           _buildActivityChart(_todayStats!),

//           const SizedBox(height: 20),

//           // Stress & Recovery
//           _buildStressRecoveryCard(_todayStats!),

//           const SizedBox(height: 20),

//           // Detailed Metrics
//           _buildDetailedMetrics(_todayStats!),
//         ],
//       ),
//     );
//   }

//   Widget _buildWeeklyTab() {
//     if (_weeklyStats == null || _weeklyStats!.dataPoints == 0) {
//       return _buildEmptyState('No data collected this week');
//     }

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           // Weekly Summary
//           _buildSummaryCards(_weeklyStats!),

//           const SizedBox(height: 20),

//           // Weekly Trends Chart
//           if (_dailySummaries != null && _dailySummaries!.isNotEmpty)
//             _buildWeeklyTrendsChart(),

//           const SizedBox(height: 20),

//           // Activity Distribution
//           _buildActivityChart(_weeklyStats!),

//           const SizedBox(height: 20),

//           // Weekly Insights
//           _buildWeeklyInsights(_weeklyStats!),
//         ],
//       ),
//     );
//   }

//   Widget _buildTrendsTab() {
//     if (_dailySummaries == null || _dailySummaries!.isEmpty) {
//       return _buildEmptyState('No trend data available');
//     }

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           // HR Trend Chart
//           _buildHRTrendChart(),

//           const SizedBox(height: 20),

//           // HRV Trend Chart
//           _buildHRVTrendChart(),

//           const SizedBox(height: 20),

//           // Panic Events Trend
//           _buildPanicTrendChart(),

//           const SizedBox(height: 20),

//           // Trend Analysis
//           _buildTrendAnalysis(),
//         ],
//       ),
//     );
//   }

//   Widget _buildSummaryCards(HealthStatistics stats) {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 2,
//       crossAxisSpacing: 12,
//       mainAxisSpacing: 12,
//       childAspectRatio: 1.2,
//       children: [
//         _buildMetricCard(
//           'Average HR',
//           '${stats.averageHR}',
//           'BPM',
//           Colors.red,
//           Icons.favorite,
//         ),
//         _buildMetricCard(
//           'HRV RMSSD',
//           stats.averageHRV.toStringAsFixed(1),
//           'ms',
//           Colors.blue,
//           Icons.show_chart,
//         ),
//         _buildMetricCard(
//           'Stress Level',
//           stats.stressLevel,
//           '',
//           _getStressColor(stats.stressLevel),
//           Icons.psychology,
//         ),
//         _buildMetricCard(
//           'Recovery',
//           '${stats.recoveryScore.toInt()}%',
//           '',
//           _getRecoveryColor(stats.recoveryScore),
//           Icons.health_and_safety,
//         ),
//       ],
//     );
//   }

//   Widget _buildMetricCard(
//     String title,
//     String value,
//     String unit,
//     Color color,
//     IconData icon,
//   ) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, color: color, size: 24),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//             if (unit.isNotEmpty)
//               Text(
//                 unit,
//                 style: const TextStyle(fontSize: 10, color: Colors.grey),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- ACTIVITY PIE CHART using fl_chart ---
//   Widget _buildActivityChart(HealthStatistics stats) {
//     final entries = stats.activityDistribution.entries.toList();
//     final total = entries.fold<double>(0.0, (p, e) => p + e.value);
//     final sections = <PieChartSectionData>[];
//     for (int i = 0; i < entries.length; i++) {
//       final e = entries[i];
//       final value = e.value;
//       final percent = total == 0 ? 0.0 : (value / total) * 100.0;
//       sections.add(
//         PieChartSectionData(
//           value: value,
//           title: '${percent.toStringAsFixed(1)}%',
//           radius: 60,
//           titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
//           color: _getActivityColor(e.key),
//           showTitle: true,
//         ),
//       );
//     }

//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Activity Distribution',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             SizedBox(
//               height: 220,
//               child: Row(
//                 children: [
//                   Expanded(
//                     flex: 2,
//                     child: PieChart(
//                       PieChartData(
//                         sections: sections,
//                         centerSpaceRadius: 24,
//                         sectionsSpace: 4,
//                         borderData: FlBorderData(show: false),
//                         pieTouchData: PieTouchData(enabled: false),
//                       ),
//                       swapAnimationDuration: const Duration(milliseconds: 300),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     flex: 1,
//                     child: _buildPieLegend(entries),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPieLegend(List<MapEntry<String, double>> entries) {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: entries.map((entry) {
//           return Padding(
//             padding: const EdgeInsets.symmetric(vertical: 6),
//             child: Row(
//               children: [
//                 Container(width: 14, height: 14, color: _getActivityColor(entry.key)),
//                 const SizedBox(width: 8),
//                 Expanded(child: Text('${entry.key} — ${entry.value.toStringAsFixed(1)}%')),
//               ],
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildStressRecoveryCard(HealthStatistics stats) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Wellness Overview',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             _buildProgressBar(
//               'Stress Level',
//               stats.stressLevel,
//               _getStressColor(stats.stressLevel),
//             ),
//             const SizedBox(height: 8),
//             _buildProgressBar(
//               'Recovery Score',
//               '${stats.recoveryScore.toInt()}%',
//               _getRecoveryColor(stats.recoveryScore),
//             ),
//             const SizedBox(height: 8),
//             _buildProgressBar(
//               'HRV Consistency',
//               '${stats.hrvConsistency.toInt()}%',
//               _getConsistencyColor(stats.hrvConsistency),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildProgressBar(String label, String value, Color color) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(label, style: const TextStyle(fontSize: 14)),
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 4),
//         LinearProgressIndicator(
//           value: _getProgressValue(value),
//           backgroundColor: Colors.grey[200],
//           color: color,
//         ),
//       ],
//     );
//   }

//   double _getProgressValue(String value) {
//     if (value.contains('%')) {
//       return int.parse(value.replaceAll('%', '')) / 100;
//     }

//     switch (value) {
//       case 'Low':
//         return 0.25;
//       case 'Moderate':
//         return 0.5;
//       case 'High':
//         return 0.75;
//       case 'Very High':
//         return 1.0;
//       default:
//         return 0.0;
//     }
//   }

//   Widget _buildDetailedMetrics(HealthStatistics stats) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Detailed Metrics',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             _buildMetricRow('Resting HR', '${stats.restingHR.toInt()} BPM'),
//             _buildMetricRow('Max HR', '${stats.maxHR} BPM'),
//             _buildMetricRow('Min HR', '${stats.minHR} BPM'),
//             _buildMetricRow(
//               'HRV SDNN',
//               '${stats.hrvSDNN.toStringAsFixed(1)} ms',
//             ),
//             _buildMetricRow('Panic Events', '${stats.panicEvents}'),
//             _buildMetricRow('Data Points', '${stats.dataPoints}'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMetricRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: const TextStyle(fontSize: 14)),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- Weekly trends as LineChart (fl_chart) ---
//   Widget _buildWeeklyTrendsChart() {
//     // Map dailySummaries to FlSpot using index as x
//     final spots = <FlSpot>[];
//     for (int i = 0; i < _dailySummaries!.length; i++) {
//       final ds = _dailySummaries![i];
//       spots.add(FlSpot(i.toDouble(), ds.averageHR.toDouble()));
//     }

//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Weekly Heart Rate Trend',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             SizedBox(
//               height: 200,
//               child: LineChart(
//                 LineChartData(
//                   lineBarsData: [
//                     LineChartBarData(
//                       spots: spots,
//                       isCurved: true,
//                       barWidth: 3,
//                       dotData: FlDotData(show: true),
//                       belowBarData: BarAreaData(show: false),
//                       color: Colors.red,
//                     ),
//                   ],
//                   titlesData: FlTitlesData(
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 36,
//                         getTitlesWidget: (value, meta) {
//                           final idx = value.toInt();
//                           if (idx < 0 || idx >= _dailySummaries!.length) {
//                             return const SizedBox.shrink();
//                           }
//                           final label = _formatDate(_dailySummaries![idx].date);
//                           return SideTitleWidget(child: Text(label, style: const TextStyle(fontSize: 10)), axisSide: meta.axisSide);
//                         },
//                         interval: 1,
//                       ),
//                     ),
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: true, reservedSize: 40),
//                     ),
//                     topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   ),
//                   gridData: FlGridData(show: true),
//                   borderData: FlBorderData(show: false),
//                 ),
//                 duration: const Duration(milliseconds: 300),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHRTrendChart() {
//     // Placeholder — keep same API: return Container for now
//     return Container();
//   }

//   Widget _buildHRVTrendChart() {
//     // Placeholder — keep same API: return Container for now
//     return Container();
//   }

//   Widget _buildPanicTrendChart() {
//     // Placeholder — keep same API: return Container for now
//     return Container();
//   }

//   Widget _buildWeeklyInsights(HealthStatistics stats) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Weekly Insights',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             _buildInsightItem(
//               Icons.trending_up,
//               'Your average HRV improved by 12% this week',
//               Colors.green,
//             ),
//             _buildInsightItem(
//               Icons.psychology,
//               'Stress levels were highest on Wednesday',
//               Colors.orange,
//             ),
//             _buildInsightItem(
//               Icons.health_and_safety,
//               'Recovery score indicates good sleep quality',
//               Colors.blue,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTrendAnalysis() {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Trend Analysis',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Based on your data trends, we recommend:',
//               style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//             ),
//             const SizedBox(height: 8),
//             _buildRecommendation('Practice breathing exercises daily'),
//             _buildRecommendation('Maintain consistent sleep schedule'),
//             _buildRecommendation('Consider reducing caffeine intake'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInsightItem(IconData icon, String text, Color color) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: color, size: 20),
//           const SizedBox(width: 12),
//           Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecommendation(String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           const Icon(Icons.check_circle, color: Colors.green, size: 16),
//           const SizedBox(width: 8),
//           Text(text, style: const TextStyle(fontSize: 14)),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState(String message) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             message,
//             style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Continue using the app to collect data',
//             style: TextStyle(fontSize: 14, color: Colors.grey[500]),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}';
//   }

//   Color _getStressColor(String level) {
//     switch (level) {
//       case 'Low':
//         return Colors.green;
//       case 'Moderate':
//         return Colors.orange;
//       case 'High':
//         return Colors.red;
//       case 'Very High':
//         return Colors.purple;
//       default:
//         return Colors.grey;
//     }
//   }

//   Color _getRecoveryColor(double score) {
//     if (score >= 80) return Colors.green;
//     if (score >= 60) return Colors.orange;
//     return Colors.red;
//   }

//   Color _getConsistencyColor(double consistency) {
//     if (consistency >= 80) return Colors.green;
//     if (consistency >= 60) return Colors.orange;
//     return Colors.red;
//   }

//   // returns Flutter Color for activity legend and pie sections
//   Color _getActivityColor(String activity) {
//     switch (activity) {
//       case 'Still':
//         return Colors.blue;
//       case 'Walking':
//         return Colors.green;
//       case 'Running':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
// }
