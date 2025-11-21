class HRVMetrics {
  final int count; // jumlah RR dalam window
  final double? meanRR; // ms
  final double? sdnn; // ms
  final double? rmssd; // ms
  final int? nn50;
  final double? pnn50; // persen

  HRVMetrics({
    required this.count,
    this.meanRR,
    this.sdnn,
    this.rmssd,
    this.nn50,
    this.pnn50,
  });

  @override
  String toString() {
    return 'HRVMetrics(count: $count, meanRR: ${meanRR?.toStringAsFixed(2)}, sdnn: ${sdnn?.toStringAsFixed(2)}, rmssd: ${rmssd?.toStringAsFixed(2)}, nn50: $nn50, pnn50: ${pnn50?.toStringAsFixed(2)})';
  }

  factory HRVMetrics.fromJson(Map<String, dynamic> json) {
    return HRVMetrics(
      count: (json['count'] is num)
          ? (json['count'] as num).toInt()
          : int.parse(json['count'].toString()),
      meanRR: json['meanRR'] != null
          ? (json['meanRR'] as num).toDouble()
          : null,
      sdnn: json['sdnn'] != null ? (json['sdnn'] as num).toDouble() : null,
      rmssd: json['rmssd'] != null ? (json['rmssd'] as num).toDouble() : null,
      nn50: json['nn50'] != null
          ? ((json['nn50'] is num)
                ? (json['nn50'] as num).toInt()
                : int.parse(json['nn50'].toString()))
          : null,
      pnn50: json['pnn50'] != null ? (json['pnn50'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'meanRR': meanRR,
      'sdnn': sdnn,
      'rmssd': rmssd,
      'nn50': nn50,
      'pnn50': pnn50,
    };
  }
}
