import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aura_bluetooth/models/heart_rate_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String collectionName = 'heart_rate_data';

  FirestoreService._internal();

  // Use parameters for flexibility
  Future<void> syncHeartRateData(
    HeartRateData data, {
    String? userId,
    String? deviceId,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        print('❌ Sync Failed: User belum login / Sesi habis');
        return;
      }

      final String userId = user.uid;
      final docId = data.timestamp.millisecondsSinceEpoch.toString();

      // Get base JSON from model
      final jsonData = data.toJson();

      // Add Metadata
      jsonData['device_id'] = deviceId ?? 'unknown_device';
      jsonData['user_id'] = userId ?? 'anonymous';
      jsonData['synced_at'] = FieldValue.serverTimestamp();

      // If there is a prediction, we might want to flag this document for easier querying
      if (data.prediction != null && data.prediction!.isPanic) {
        jsonData['has_panic_alert'] = true;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection(collectionName)
          .doc(docId)
          .set(jsonData, SetOptions(merge: true));

      print('✅ Data synced to Firestore: $docId');
    } catch (e) {
      print('❌ Firestore sync error: $e');
      throw e; // Throw so StorageService knows not to delete from queue
    }
  }

  // Bulk Sync for Workmanager
  Future<List<String>> syncRawMaps(Map<dynamic, dynamic> rawDataMap) async {
    final batch = _firestore.batch();
    final List<String> successfulKeys = [];

    if (rawDataMap.isEmpty) return [];

    rawDataMap.forEach((key, value) {
      // 'key' is the timestamp string from Hive
      final docRef = _firestore.collection(collectionName).doc(key.toString());

      final Map<String, dynamic> data = Map<String, dynamic>.from(value);

      // Add metadata
      data['synced_at'] = FieldValue.serverTimestamp();
      data['sync_method'] = 'background_batch';

      batch.set(docRef, data, SetOptions(merge: true));
      successfulKeys.add(key.toString());
    });

    await batch.commit();
    print('✅ Batch synced ${successfulKeys.length} records');
    return successfulKeys;
  }

  Future<void> updatePanicValidation(String timestamp, String status) async {
    try {
      final user = _auth.currentUser;

      final String userId = user!.uid;
      final docId = timestamp;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection(collectionName)
          .doc(docId)
          .update({
            'prediction.userFeedback': status,
            'prediction.validated_at': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Gagal update validasi: $e');
    }
  }
}

// // services/firestore_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:aura_bluetooth/models/heart_rate_model.dart';

// class FirestoreService {
//   static final FirestoreService _instance = FirestoreService._internal();
//   factory FirestoreService() => _instance;
  
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   static const String collectionName = 'heart_rate_data';
  
//   FirestoreService._internal();
  
//   Future<void> syncHeartRateData(HeartRateData data) async {
//     try {
//       final docId = data.timestamp.millisecondsSinceEpoch.toString();
      
//       final jsonData = {
//         'bpm': data.bpm,
//         'timestamp': data.timestamp.millisecondsSinceEpoch,
//         'rrIntervals': data.rrIntervals,
//         'hrv10s': data.HRV10s?.toJson(),
//         'hrv30s': data.HRV30s?.toJson(),
//         'hrv60s': data.HRV60s?.toJson(),
//         'rhr': data.rhr,
//         'phoneSensor': data.phoneSensor.toJson(),
//         'device_id': 'armband_device', // bisa diganti dengan actual device ID
//         'user_id': 'current_user_id', // perlu diintegrasikan dengan auth
//       };
      
//       await _firestore
//           .collection(collectionName)
//           .doc(docId)
//           .set(jsonData, SetOptions(merge: true));
          
//       print('✅ Data synced to Firestore: $docId');
//     } catch (e) {
//       print('❌ Firestore sync error: $e');
//       // TODO: Implement retry logic atau offline queue
//     }
//   }
  
//   // Bulk sync untuk offline data
//   Future<void> syncMultipleData(List<HeartRateData> dataList) async {
//     final batch = _firestore.batch();
    
//     for (final data in dataList) {
//       final docId = data.timestamp.millisecondsSinceEpoch.toString();
//       final docRef = _firestore.collection(collectionName).doc(docId);
      
//       final jsonData = {
//         'bpm': data.bpm,
//         'timestamp': data.timestamp.millisecondsSinceEpoch,
//         'rrIntervals': data.rrIntervals,
//         'hrv10s': data.HRV10s?.toJson(),
//         'hrv30s': data.HRV30s?.toJson(),
//         'hrv60s': data.HRV60s?.toJson(),
//         'rhr': data.rhr,
//         'phoneSensor': data.phoneSensor.toJson(),
//         'device_id': 'armband_device',
//         'user_id': 'current_user_id',
//         'synced_at': FieldValue.serverTimestamp(),
//       };
      
//       batch.set(docRef, jsonData, SetOptions(merge: true));
//     }
    
//     await batch.commit();
//     print('✅ Bulk synced ${dataList.length} records to Firestore');
//   }
// }