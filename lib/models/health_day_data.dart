// import 'package:hive/hive.dart';
// import 'package:json_annotation/json_annotation.dart';
// import 'biometric.model.dart';
// import 'spatio.model.dart';

// part 'health_day_data.g.dart';

// @HiveType(typeId: 2)
// @JsonSerializable(explicitToJson: true)
// class HealthDayData extends HiveObject {
//   @HiveField(0)
//   final Biometric biometricData;

//   @HiveField(1)
//   final SpatioTemporal phoneSensorData;

//   // --- DERIVED/CLASSIFICATION FIELDS (Final App Logic) ---
//   @HiveField(2)
//   final bool possiblePanicAttack; // Final contextual classification result

//   @HiveField(3)
//   final String finalKategori; // e.g., "HIGH_STRESS", "EXERCISE_NORMAL", "PANIC_ALERT"

//   @HiveField(4)
//   final String timestamp; // The specific time of this record (taken from SpatioTemporal)

//   // 1. PRIVATE INTERNAL CONSTRUCTOR
//   HealthDayData._internal({
//     required this.biometricData,
//     required this.phoneSensorData,
//     required this.possiblePanicAttack,
//     required this.finalKategori,
//   }) : timestamp = phoneSensorData.time;

//   // 2. PUBLIC FACTORY: The entry point for final classification
//   factory HealthDayData.createFromFushion({
//     required Biometric biometric,
//     required SpatioTemporal spatioTemporal,
//   }) {
//     // 3. RUN THE CONTEXTUAL CLASSIFICATION LOGIC
//     final classificationResult = _classifyContextualPanic(
//       biometric: biometric,
//       spatioTemporal: spatioTemporal,
//     );

//     // 4. RETURN THE FINAL, FUSED OBJECT
//     return HealthDayData._internal(
//       biometricData: biometric,
//       phoneSensorData: spatioTemporal,
//       possiblePanicAttack: classificationResult['isPanic'] as bool,
//       finalKategori: classificationResult['kategori'] as String,
//     );
//   }

//   // --- HELPER FUNCTION (The Contextual Logic) ---

//   static Map<String, dynamic> _classifyContextualPanic({
//     required Biometric biometric,
//     required SpatioTemporal spatioTemporal,
//   }) {
//     // STARTING POINT: Assume panic if the biometric model flagged it
//     bool isPanic = biometric.possiblePanic;
//     String finalKategori = 'NORMAL';

//     // -------------------------------------------------------------------
//     // A. BIOMETRIC-ONLY CLASSIFICATION
//     // -------------------------------------------------------------------
//     if (biometric.possiblePanic) {
//       finalKategori = 'BIOMETRIC_ALERT';
//     }

//     // -------------------------------------------------------------------
//     // B. CONTEXTUAL OVERRIDE LOGIC
//     // This is where we use phone context to invalidate or confirm the biometric alert.
//     // -------------------------------------------------------------------

//     // --- Override 1: High Physical Activity ---
//     if (biometric.possiblePanic &&
//         (spatioTemporal.isRunning || spatioTemporal.isWalking)) {
//       // If the user is running or fast walking, a high heart rate/stress is normal.
//       isPanic = false;
//       finalKategori = spatioTemporal.isRunning
//           ? 'EXERCISE_RUNNING'
//           : 'EXERCISE_WALKING';

//       // Re-check: Even while running, if HRV is extremely low (below a typical exercise floor),
//       // it might still be an issue (e.g., severe fatigue/illness).
//       if (biometric.hrv < 20.0) {
//         // Example threshold: highly individual
//         isPanic = true;
//         finalKategori = 'FATIGUE_ALERT';
//       }
//     }
//     // --- Override 2: Low Light/Sleep Context ---
//     else if (biometric.possiblePanic &&
//         spatioTemporal.timeOfDayCategory == 'night') {
//       // Alert is confirmed and potentially more severe if it happens during rest/sleep time.
//       isPanic = true;
//       finalKategori = 'NIGHT_PANIC_ALERT';
//     }
//     // --- Override 3: Low HR / Biometric Anomaly (Not Panic) ---
//     else if (biometric.heartRate < 45) {
//       // e.g., severe bradycardia
//       isPanic = false;
//       finalKategori = 'LOW_HR_BRADY_ALERT';
//     }

//     // --- Final Outcome ---
//     if (isPanic && finalKategori.contains('ALERT')) {
//       // Confirmed alert!
//       finalKategori = '!!! FINAL_PANIC_ATTACK !!!';
//     } else if (finalKategori == 'BIOMETRIC_ALERT') {
//       // Alert was biometric but context didn't confirm it as an attack (e.g., strong emotion)
//       finalKategori = 'HIGH_STRESS';
//     }

//     return {'isPanic': isPanic, 'kategori': finalKategori};
//   }

//   // 3. FACTORY FOR JSON (for cloud sync deserialization)
//   factory HealthDayData.fromJson(Map<String, dynamic> json) =>
//       _$HealthDayDataFromJson(json);
// }
