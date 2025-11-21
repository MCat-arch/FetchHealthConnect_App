// import 'package:hive/hive.dart';
// import 'package:json_annotation/json_annotation.dart';
// import 'dart:math';

// part 'biometric.model.g.dart';

// @HiveType(typeId: 0)
// @JsonSerializable(explicitToJson: true) // For cloud sync JSON
// class Biometric extends HiveObject {
//   // --- REQUIRED FIELDS (Input & Calculated) ---
//   @HiveField(0)
//   final int heartRate; // Raw input (or primary derived)

//   @HiveField(1)
//   final double hrv; // Calculated: ms (Heart Rate Variability)

//   @HiveField(2)
//   final double hrmad10; // Calculated: deviation in bpm over 10s window
//   // ... (hrmad30, hrmad60, etc.)

//   @HiveField(3)
//   final double hrmad30;

//   @HiveField(4)
//   final double hrmad60;

//   @HiveField(5)
//   final List<int>? rrIntervals; // Raw input

//   // --- DERIVED/CLASSIFICATION FIELDS ---
//   @HiveField(9)
//   final bool possiblePanic; // Calculated result

//   // --- BASELINE FIELDS (Usually fed in from a history service, so they can be null) ---
//   @HiveField(6)
//   final double? baselineHR;

//   @HiveField(8)
//   final double? baselineRestingHR;

//   // 1. PRIVATE INTERNAL CONSTRUCTOR (Used ONLY by the factory)
//   Biometric._internal({
//     required this.heartRate,
//     required this.hrv,
//     required this.hrmad10,
//     required this.hrmad30,
//     required this.hrmad60,
//     required this.rrIntervals,
//     required this.possiblePanic,
//     this.baselineHR,
//     this.baselineRestingHR,
//   });

//   // 2. PUBLIC FACTORY: The entry point for creation from raw BLE data
//   factory Biometric.fromRawData({
//     required int heartRate,
//     required List<int> rrIntervals,
//     double? userBaselineHR, // Data passed from an external service/memory
//   }) {
//     // 3. PERFORM ALL COMPLEX CALCULATIONS HERE

//     // A. HRV Calculation (Placeholder logic)
//     final calculatedHrv = _calculateHRV(rrIntervals);

//     // B. HRMAD10 Calculation (Placeholder logic)
//     final calculatedHrmad10 = _calculateHRMAD10(rrIntervals);

//     // C. Panic State Classification
//     final panicClassification = _classifyPanicState(
//       heartRate: heartRate,
//       hrv: calculatedHrv,
//       baselineHR: userBaselineHR,
//     );

//     final calculateHrmad30 = _calculateHRMAD30(rrIntervals);
//     final calculateHrmad60 = _calculateHRMAD60(rrIntervals);

//     // 4. RETURN THE FINAL, FULLY CONSTRUCTED OBJECT
//     return Biometric._internal(
//       heartRate: heartRate,
//       hrv: calculatedHrv,
//       hrmad10: calculatedHrmad10,
//       hrmad30: calculateHrmad30,
//       hrmad60: calculateHrmad60,
//       rrIntervals: rrIntervals,
//       possiblePanic: panicClassification['possiblePanic'] as bool,
//       baselineHR: userBaselineHR,
//       baselineRestingHR: null, // Placeholder for history data
//     );
//   }

//   // --- HELPER FUNCTIONS (Private and Static) ---

//   static double _calculateHRV(List<int> rrIntervals) {
//     if (rrIntervals.isEmpty) return 0.0;
//     // Example logic: Simplified RMSSD calculation (Root Mean Square of Successive Differences)
//     // The actual calculation is more complex, but this shows where the logic lives.
//     double sumOfDifferences = 0;
//     for (int i = 1; i < rrIntervals.length; i++) {
//       final diff = rrIntervals[i] - rrIntervals[i - 1];
//       sumOfDifferences += pow(diff, 2);
//     }
//     return sqrt(sumOfDifferences / rrIntervals.length);
//   }

//   static double _calculateHRMAD10(List<int> rrIntervals) {
//     // Placeholder logic for HRMAD
//     return 0.0;
//   }

//   static double _calculateHRMAD30(List<int> rrIntervals) {
//     return 0.0;
//   }

//   static double _calculateHRMAD60(List<int> rrIntervals) {
//     return 0.0;
//   }

//   static Map<String, dynamic> _classifyPanicState({
//     required int heartRate,
//     required double hrv,
//     double? baselineHR,
//   }) {
//     bool isPanic = false;
//     String? state;

//     // Example Rule 1: High Heart Rate AND Low HRV
//     if (heartRate > 120 && hrv < 30.0) {
//       isPanic = true;
//       state = 'Tachycardia_LowHRV';
//     }
//     // Example Rule 2: Significant deviation from baseline
//     else if (baselineHR != null && (heartRate - baselineHR).abs() > 30) {
//       isPanic = true;
//       state = 'Baseline_Deviation';
//     }

//     return {'possiblePanic': isPanic, 'panicState': state};
//   }

//   // 3. FACTORY FOR JSON (for network data loading)
//   factory Biometric.fromJson(Map<String, dynamic> json) =>
//       _$BiometricFromJson(json);
// }
