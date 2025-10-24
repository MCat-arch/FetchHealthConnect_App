
/// 1️⃣ Exercise-related data
class ExerciseData {
  double? distance; // in meters
  double? ascent; // in meters
  double? altitude; // in meters
  double? mediumIntensityMinutes;
  double? highIntensityMinutes;
  double? activeHours;
  double? dailyActivitySummary;

  ExerciseData({
    this.distance,
    this.ascent,
    this.altitude,
    this.mediumIntensityMinutes,
    this.highIntensityMinutes,
    this.activeHours,
    this.dailyActivitySummary,
  });

  Map<String, dynamic> toJson() => {
        'distance': distance,
        'ascent': ascent,
        'altitude': altitude,
        'mediumIntensityMinutes': mediumIntensityMinutes,
        'highIntensityMinutes': highIntensityMinutes,
        'activeHours': activeHours,
        'dailyActivitySummary': dailyActivitySummary,
      };

  factory ExerciseData.fromJson(Map<String, dynamic> json) => ExerciseData(
        distance: (json['distance'] as num?)?.toDouble(),
        ascent: (json['ascent'] as num?)?.toDouble(),
        altitude: (json['altitude'] as num?)?.toDouble(),
        mediumIntensityMinutes:
            (json['mediumIntensityMinutes'] as num?)?.toDouble(),
        highIntensityMinutes:
            (json['highIntensityMinutes'] as num?)?.toDouble(),
        activeHours: (json['activeHours'] as num?)?.toDouble(),
        dailyActivitySummary:
            (json['dailyActivitySummary'] as num?)?.toDouble(),
      );
}

/// 2️⃣ Panic-related data
class PanicVariableData {
  int? heartRate;
  double? stress;
  double? sleepHours;
  int? systolicBP; // Blood Pressure
  int? diastolicBP;
  double? spo2;
  double? bodyTemperature;
  double? heartHealthIndex;
  String? emotion;

  PanicVariableData({
    this.heartRate,
    this.stress,
    this.sleepHours,
    this.systolicBP,
    this.diastolicBP,
    this.spo2,
    this.bodyTemperature,
    this.heartHealthIndex,
    this.emotion,
  });

  Map<String, dynamic> toJson() => {
        'heartRate': heartRate,
        'stress': stress,
        'sleepHours': sleepHours,
        'systolicBP': systolicBP,
        'diastolicBP': diastolicBP,
        'spo2': spo2,
        'bodyTemperature': bodyTemperature,
        'heartHealthIndex': heartHealthIndex,
        'emotion': emotion,
      };

  factory PanicVariableData.fromJson(Map<String, dynamic> json) =>
      PanicVariableData(
        heartRate: json['heartRate'] as int?,
        stress: (json['stress'] as num?)?.toDouble(),
        sleepHours: (json['sleepHours'] as num?)?.toDouble(),
        systolicBP: json['systolicBP'] as int?,
        diastolicBP: json['diastolicBP'] as int?,
        spo2: (json['spo2'] as num?)?.toDouble(),
        bodyTemperature: (json['bodyTemperature'] as num?)?.toDouble(),
        heartHealthIndex: (json['heartHealthIndex'] as num?)?.toDouble(),
        emotion: json['emotion'] as String?,
      );
}
