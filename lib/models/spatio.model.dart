// import 'package:hive/hive.dart';
// import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'spatio.model.g.dart';

// @HiveType(typeId: 1)
@JsonSerializable(explicitToJson: true)
class SpatioTemporal extends HiveObject {
  // --- RAW INPUT FIELDS (From Phone APIs) ---
  // @HiveField(0)
  String rawActivityStatus;

  // @HiveField(1)
  String time;

  // @HiveField(2)
  double? noiseLeveldB;

  // @HiveField(3)
  bool isWalking;

  // @HiveField(4)
  bool isRunning;

  // @HiveField(5)
  bool isStill;

  // @HiveField(6)
  String timeOfDayCategory;

  // -----------------------------------------------------------
  // 1. DEFAULT CONSTRUCTOR (WAJIB untuk Hive)
  //    Field dibuat nullable karena Hive akan set nilainya belakangan.
  // -----------------------------------------------------------
  SpatioTemporal({
    required this.rawActivityStatus, //memberikan data aktivitas
    required this.time,
    this.noiseLeveldB,  //memberikan data apakah user di kerumunan
    required this.isWalking,
    required this.isRunning,
    required this.isStill,
    required this.timeOfDayCategory,
  });

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

// part 'spatio.model.g.dart';

// @HiveType(typeId: 1)
// @JsonSerializable(explicitToJson: true)
// class SpatioTemporal extends HiveObject {
//   // --- RAW INPUT FIELDS (From Phone APIs) ---
//   @HiveField(0)
//   String rawActivityStatus; // e.g., 'STILL', 'WALKING', 'RUNNING' from an API

//   @HiveField(1)
//   String time; // Specific time string (e.g., "02:30:45")

//   // @HiveField(2)
//   //  double? ambientLightLux; // Raw lux value

//   @HiveField(2)
//   double? noiseLeveldB; // Raw decibel reading

//   @HiveField(3)
//   bool isWalking; // Derived boolean: true jika ActivityStatus adalah "WALKING"

//   @HiveField(4)
//   bool isRunning; // Derived boolean

//   @HiveField(5)
//   bool isStill;

//   @HiveField(6)
//   String timeOfDayCategory; // Derived: "morning", "afternoon", "night"

//   // 1. PRIVATE INTERNAL CONSTRUCTOR
//   SpatioTemporal._internal({
//     required this.rawActivityStatus,
//     required this.time,
//     // this.ambientLightLux,
//     this.noiseLeveldB,
//     required this.isWalking,
//     required this.isRunning,
//     required this.isStill,
//     required this.timeOfDayCategory,
//   });

//   // 2. PUBLIC FACTORY: Entry point for construction from raw sensor data
//   factory SpatioTemporal.fromRawData({
//     required String activityStatus,
//     required DateTime timestamp,
//     // double? lightLux,
//     double? noiseDB,
//   }) {
//     final normalizedActivity = activityStatus.toUpperCase().trim();

//     // A. Derived Activity Booleans
//     final isWalkingState = normalizedActivity == 'WALKING';
//     final isRunningState = normalizedActivity == 'RUNNING';
//     final isStillState = normalizedActivity == 'STILL';

//     // B. Derived Time Category
//     final timeCategory = _classifyTimeOfDay(timestamp.hour);

//     // C. Formatted Time String
//     final timeString =
//         "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}";

//     return SpatioTemporal._internal(
//       rawActivityStatus: normalizedActivity,
//       time: timeString,
//       // ambientLightLux: lightLux,
//       noiseLeveldB: noiseDB,
//       isWalking: isWalkingState,
//       isRunning: isRunningState,
//       isStill: isStillState,
//       timeOfDayCategory: timeCategory,
//     );
//   }

//   // --- HELPER FUNCTION (Used by the Factory) ---

//   static String _classifyTimeOfDay(int hour) {
//     if (hour >= 5 && hour < 12) {
//       return 'morning';
//     } else if (hour >= 12 && hour < 17) {
//       return 'afternoon';
//     } else if (hour >= 17 && hour < 20) {
//       return 'evening';
//     } else {
//       return 'night';
//     }
//   }

//   // 3. FACTORY FOR JSON (for network data loading)
//   factory SpatioTemporal.fromJson(Map<String, dynamic> json) =>
//       _$SpatioTemporalFromJson(json);

//   Map<String, dynamic> toJson() => _$SpatioTemporalToJson(this);
// }
