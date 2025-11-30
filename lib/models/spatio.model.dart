// import 'package:hive/hive.dart';
// import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'spatio.model.g.dart';

// @HiveType(typeId: 1)
@JsonSerializable(explicitToJson: true)
class SpatioTemporal {
  // --- RAW INPUT FIELDS (From Phone APIs) ---
  // @HiveField(0)
  final String rawActivityStatus;

  // @HiveField(1)
  final String time;

  // @HiveField(2)
  final double? noiseLeveldB;

  // @HiveField(3)
  final bool isWalking;

  // @HiveField(4)
  final bool isRunning;

  // @HiveField(5)
  final bool isStill;

  // @HiveField(6)
  final String timeOfDayCategory;

  // -----------------------------------------------------------
  // 1. DEFAULT CONSTRUCTOR (WAJIB untuk Hive)
  //    Field dibuat nullable karena Hive akan set nilainya belakangan.
  // -----------------------------------------------------------
  SpatioTemporal({
    required this.rawActivityStatus, //memberikan data aktivitas
    required this.time,
    this.noiseLeveldB, //memberikan data apakah user di kerumunan
    required this.isWalking,
    required this.isRunning,
    required this.isStill,
    required this.timeOfDayCategory,
  });

  factory SpatioTemporal.empty() {
    return SpatioTemporal(
      rawActivityStatus: "UNKNOWN",
      time: "00:00:00",
      noiseLeveldB: 0.0,
      isWalking: false,
      isRunning: false,
      isStill: true,
      timeOfDayCategory: "unknown",
    );
  }

  // -----------------------------------------------------------
  // 2. PRIVATE INTERNAL CONSTRUCTOR untuk dipakai factory
  // -----------------------------------------------------------
  SpatioTemporal._internal({
    required this.rawActivityStatus,
    required this.time,
    this.noiseLeveldB,
    required this.isWalking,
    required this.isRunning,
    required this.isStill,
    required this.timeOfDayCategory,
  });

  SpatioTemporal copyWith({
    String? rawActivityStatus,
    String? time,
    double? noiseLeveldB,
    bool? isWalking,
    bool? isRunning,
    bool? isStill,
    String? timeOfDayCategory,
  }) {
    return SpatioTemporal._internal(
      rawActivityStatus: rawActivityStatus ?? this.rawActivityStatus,
      time: time ?? this.time,
      noiseLeveldB: noiseLeveldB ?? this.noiseLeveldB,
      isWalking: isWalking ?? this.isWalking,
      isRunning: isRunning ?? this.isRunning,
      isStill: isStill ?? this.isStill,
      timeOfDayCategory: timeOfDayCategory ?? this.timeOfDayCategory,
    );
  }

  // -----------------------------------------------------------
  // 3. PUBLIC FACTORY: Entry point for construction from raw sensor data
  // -----------------------------------------------------------
  factory SpatioTemporal.fromRawData({
    required String activityStatus,
    required DateTime timestamp,
    double? noiseDB,
  }) {
    final normalizedActivity = activityStatus.toUpperCase().trim();
    // Derived booleans
    final isWalkingState = normalizedActivity == 'WALKING';
    final isRunningState = normalizedActivity == 'RUNNING';
    final isStillState = normalizedActivity == 'STILL';

    // Derived time-of-day category
    final timeCategory = _classifyTimeOfDay(timestamp.hour);

    // Formatting time string
    final timeString =
        "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}";

    return SpatioTemporal._internal(
      rawActivityStatus: normalizedActivity,
      time: timeString,
      noiseLeveldB: noiseDB,
      isWalking: isWalkingState,
      isRunning: isRunningState,
      isStill: isStillState,
      timeOfDayCategory: timeCategory,
    );
  }

  // HELPER
  static String _classifyTimeOfDay(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 20) return 'evening';
    return 'night';
  }

  // JSON Serialization
  factory SpatioTemporal.fromJson(Map<String, dynamic> json) =>
      _$SpatioTemporalFromJson(json);

  Map<String, dynamic> toJson() => _$SpatioTemporalToJson(this);
}
