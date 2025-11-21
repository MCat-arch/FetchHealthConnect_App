// services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aura_bluetooth/models/heart_rate_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'heart_rate_data';
  
  FirestoreService._internal();
  
  Future<void> syncHeartRateData(HeartRateData data) async {
    try {
      final docId = data.timestamp.millisecondsSinceEpoch.toString();
      
      final jsonData = {
        'bpm': data.bpm,
        'timestamp': data.timestamp.millisecondsSinceEpoch,
        'rrIntervals': data.rrIntervals,
        'hrv10s': data.HRV10s?.toJson(),
        'hrv30s': data.HRV30s?.toJson(),
        'hrv60s': data.HRV60s?.toJson(),
        'rhr': data.rhr,
        'phoneSensor': data.phoneSensor.toJson(),
        'device_id': 'armband_device', // bisa diganti dengan actual device ID
        'user_id': 'current_user_id', // perlu diintegrasikan dengan auth
      };
      
      await _firestore
          .collection(collectionName)
          .doc(docId)
          .set(jsonData, SetOptions(merge: true));
          
      print('✅ Data synced to Firestore: $docId');
    } catch (e) {
      print('❌ Firestore sync error: $e');
      // TODO: Implement retry logic atau offline queue
    }
  }
  
  // Bulk sync untuk offline data
  Future<void> syncMultipleData(List<HeartRateData> dataList) async {
    final batch = _firestore.batch();
    
    for (final data in dataList) {
      final docId = data.timestamp.millisecondsSinceEpoch.toString();
      final docRef = _firestore.collection(collectionName).doc(docId);
      
      final jsonData = {
        'bpm': data.bpm,
        'timestamp': data.timestamp.millisecondsSinceEpoch,
        'rrIntervals': data.rrIntervals,
        'hrv10s': data.HRV10s?.toJson(),
        'hrv30s': data.HRV30s?.toJson(),
        'hrv60s': data.HRV60s?.toJson(),
        'rhr': data.rhr,
        'phoneSensor': data.phoneSensor.toJson(),
        'device_id': 'armband_device',
        'user_id': 'current_user_id',
        'synced_at': FieldValue.serverTimestamp(),
      };
      
      batch.set(docRef, jsonData, SetOptions(merge: true));
    }
    
    await batch.commit();
    print('✅ Bulk synced ${dataList.length} records to Firestore');
  }
}