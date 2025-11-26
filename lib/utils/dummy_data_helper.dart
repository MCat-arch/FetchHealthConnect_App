import 'package:firebase_auth/firebase_auth.dart';

import '../models/heart_rate_model.dart';
import '../models/hrv_metric.dart';
import '../models/spatio.model.dart';
import '../services/firestore_service.dart';
import '../services/ml_panic_service.dart' show PanicPrediction;

class DummyDataHelper {
  static HeartRateData getNormalData() {
    final now = DateTime.now();

    final sensor = SpatioTemporal(
      rawActivityStatus: "STILL",
      time: "${now.hour}:${now.minute}:${now.second}",
      noiseLeveldB: 45.2, // Quiet room
      isWalking: false,
      isRunning: false,
      isStill: true,
      timeOfDayCategory: 'morning',
    );

    // 2. Dummy HRV (Healthy values)
    final hrv = HRVMetrics(
      count: 60,
      meanRR: 850.0,
      sdnn: 50.5,
      rmssd: 42.0, // Healthy resting HRV
      nn50: 10,
      pnn50: 16.6,
    );

    return HeartRateData(
      72, // BPM
      now,
      [800.0, 810.0, 790.0, 805.0, 800.0], // Sample RR Intervals
      hrv, // HRV 10s
      hrv, // HRV 30s
      hrv, // HRV 60s
      68.0, // RHR
      sensor,
      PanicPrediction(
        isPanic: false,
        confidence: 0.1,
        features: {'bpm': 72, 'hrv': 42.0},
        timestamp: now,
      ),
    );
  }

  static Future<void> uploadDummyData() async {
    print("🚀 Seeding Firestore with dummy data...");
    if (FirebaseAuth.instance.currentUser == null) {
      print("⚠️ Cannot seed data: No user logged in.");
      return;
    }

    print(
      "🚀 Seeding Firestore for user: ${FirebaseAuth.instance.currentUser!.email}...",
    );

    final FirestoreService firestore = FirestoreService();

    // 1. Upload Normal Data
    await firestore.syncHeartRateData(getNormalData());
    print("✅ Normal data added.");

    // 2. Upload Panic Data (Optional, to test UI alert)
    // await firestore.syncHeartRateData(getPanicData());
    // print("✅ Panic data added.");
  }
}
