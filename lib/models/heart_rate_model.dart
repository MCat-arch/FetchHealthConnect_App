import 'package:aura_bluetooth/models/hrv_metric.dart';
import 'package:aura_bluetooth/models/spatio.model.dart';
import 'dart:convert';

class HeartRateData {
  final int bpm;
  final DateTime timestamp;
  final List<double>? rrIntervals;
  final HRVMetrics? HRV10s;
  final HRVMetrics? HRV30s;
  final HRVMetrics? HRV60s;
  final double rhr;
  SpatioTemporal phoneSensor;


  HeartRateData(
    this.bpm,
    this.timestamp,
    this.rrIntervals,
    this.HRV10s,
    this.HRV30s,
    this.HRV60s,
    this.rhr,
    this.phoneSensor,
  );

  factory HeartRateData.fromJson(Map<String, dynamic> json) {
    return HeartRateData(
      (json['bpm'] is num)
          ? (json['bpm'] as num).toInt()
          : int.parse(json['bpm'].toString()),
      json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.fromMillisecondsSinceEpoch(0),
      json['rrIntervals'] != null
          ? List<double>.from(
              (json['rrIntervals'] as List).map((e) => (e as num).toDouble()),
            )
          : null,
      json['HRV10s'] != null
          ? HRVMetrics.fromJson(Map<String, dynamic>.from(json['HRV10s']))
          : null,
      json['HRV30s'] != null
          ? HRVMetrics.fromJson(Map<String, dynamic>.from(json['HRV30s']))
          : null,
      json['HRV60s'] != null
          ? HRVMetrics.fromJson(Map<String, dynamic>.from(json['HRV60s']))
          : null,
      json['rhr'] != null ? (json['rhr'] as num).toDouble() : 0.0,
      json['phoneSensor'] != null ? SpatioTemporal.fromJson(
        Map<String, dynamic>.from(json['phoneSensor']),
      ) : SpatioTemporal.empty(), // asumsi konstruktor default ada
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bpm': bpm,
      'timestamp': timestamp.toIso8601String(),
      'rrIntervals': rrIntervals,
      'HRV10s': HRV10s?.toJson(),
      'HRV30s': HRV30s?.toJson(),
      'HRV60s': HRV60s?.toJson(),
      'rhr': rhr,
      'phoneSensor': phoneSensor.toJson(),
    };
  }

  //fungsi buat decide wheather the collected data categorized as panic or not (actually using ml model)
}
