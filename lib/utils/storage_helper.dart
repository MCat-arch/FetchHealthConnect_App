import 'package:aura/model/health_day_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:aura/model/health_data.dart';

class StorageHelper {
  static final _db = FirebaseFirestore.instance;
  static const String _key = 'healthData';
  static const String _permissionKey = 'healthPermissionsKey';
  static const String _groupedKey = 'health_grouped_data';
  static const String _lastUpdatedKey = 'health_data_last_update';

  static const String _lastFetchKey = "last_fetch_time";

  static Future<void> saveLastFetchTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFetchKey, time.toIso8601String());
  }

  static Future<DateTime?> getLastFetchTime() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastFetchKey);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  static Future<void> permissionGranted(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionKey, granted);
  }

  static Future<bool> isPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionKey) ?? false;
  }

  static String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");
    return user.uid;
  }

  /// ✅ Stream semua healthData (summary + details)
  static Stream<List<HealthData>> streamAllHealthData() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('healthData')
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<HealthData> results = [];
          for (var doc in snapshot.docs) {
            // ambil details dari subcollection
            final detailSnap = await doc.reference
                .collection('healthDayData')
                .get();
            final details = detailSnap.docs
                .map((d) => HealthDayData.fromJson(d.data()))
                .toList();

            results.add(HealthData.fromJson(doc.data(), details: details));
          }
          return results;
        });
  }

  /// ✅ Stream semua healthDayData untuk hari tertentu
  static Stream<List<HealthDayData>> streamHealthDayData(String date) {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('healthData')
        .doc(date)
        .collection('healthDayData')
        .orderBy('time', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HealthDayData.fromJson(doc.data()))
              .toList(),
        );
  }

  /// ✅ Simpan meta harian
  static Future<void> saveHealthData(HealthData data) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('healthData')
        .doc(data.date)
        .set(data.toJson(), SetOptions(merge: true));
  }

  /// ✅ Simpan detail per 15 menit
  static Future<void> addHealthDayData(
    String date,
    HealthDayData detail,
  ) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('healthData')
        .doc(date)
        .collection('healthDayData')
        .doc(detail.time) // gunakan time sebagai docId supaya unik
        .set(detail.toJson(), SetOptions(merge: true));
  }

  /// ✅ Ambil satu hari summary (tanpa stream)
  static Future<HealthData?> getHealthData(String date) async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('healthData')
        .doc(date)
        .get();
    if (!doc.exists) return null;

    final detailSnap = await doc.reference
        .collection('healthDayData')
        .orderBy('time')
        .get();
    final details = detailSnap.docs
        .map((d) => HealthDayData.fromJson(d.data()))
        .toList();

    return HealthData.fromJson(doc.data()!, details: details);
  }

  // di StorageHelper
  static Future<Set<String>> getDetailIdsForDate(String date) async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('healthData')
        .doc(date)
        .collection('healthDayData')
        .get();
    return snapshot.docs.map((d) => d.id).toSet();
  }

  static Future<void> addHealthDayDataBatch(
    String date,
    List<HealthDayData> details,
  ) async {
    final batch = _db.batch();
    final base = _db
        .collection('users')
        .doc(_uid)
        .collection('healthData')
        .doc(date);
    for (final d in details) {
      final docRef = base.collection('healthDayData').doc(d.time); // time as id
      batch.set(docRef, d.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  static Future<void> incrementPanicCount(String date, int by) async {
    final docRef = _db
        .collection('users')
        .doc(_uid)
        .collection('healthData')
        .doc(date);
    await docRef.set({
      'panicCount': FieldValue.increment(by),
    }, SetOptions(merge: true));
  }
}

  // static Future<void> saveGroupedData(Map<String, HealthData> grouped) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final jsonData = grouped.map((k, v) => MapEntry(k, v.toJson()));
  //   await prefs.setString(_groupedKey, jsonEncode(jsonData));
  //   await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
  // }

  // static Future<Map<String, HealthData>?> loadGroupedData() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final jsonString = prefs.getString(_groupedKey);
  //   if (jsonString == null) return null;

  //   final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
  //   final Map<String, HealthData> result = {};

  //   jsonMap.forEach((k, v) {
  //     result[k] = HealthData.fromJson(v);
  //   });

  //   return result;
  // }

  // static Future<DateTime?> getLastUpdated() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final lastUpdateStr = prefs.getString(_lastUpdatedKey);
  //   if (lastUpdateStr == null) return null;
  //   return DateTime.tryParse(lastUpdateStr);
  // }
