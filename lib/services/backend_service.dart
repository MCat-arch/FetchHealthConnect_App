import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aura_bluetooth/models/heart_rate_model.dart';
import 'package:aura_bluetooth/services/ml_panic_service.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();


  static const String _baseUrl = 'https://khoerunnisautami-aura.hf.space';

  Future<PanicPrediction> sendPredictionRequest(HeartRateData data, String deviceId) async {
    final url = Uri.parse('$_baseUrl/predict');
    print('========================================');
    print('🌐 [BackendService] Mengirim POST ke: $url');
    print('📦 [BackendService] Data BPM: ${data.bpm}, HRV: ${data.HRV60s?.sdnn}');
    print('========================================');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Device-Id': deviceId,
        },
        body: jsonEncode(data.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ [BackendService] Sukses (200) - Data: ${response.body}');
        final jsonResponse = jsonDecode(response.body);
        return PanicPrediction.fromJson(jsonResponse);
      } else {
        print('❌ [BackendService] Backend error: ${response.statusCode} - ${response.body}');
        return _fallbackPrediction(data, "API Error: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ [BackendService] Network error menghubungkan ke $_baseUrl: $e');
      return _fallbackPrediction(data, "Network Error");
    }
  }

  Future<void> resetSession(String deviceId) async {
    final url = Uri.parse('$_baseUrl/reset');
    try {
      await http.post(
        url,
        headers: {
          'X-Device-Id': deviceId,
        },
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      print('Failed to reset session on backend: $e');
    }
  }

  PanicPrediction _fallbackPrediction(HeartRateData data, String reason) {
    return PanicPrediction(
      trigger: false,
      pPanic: null,
      status: 'Offline ($reason)',
      bpm: data.bpm,
      sdnn: data.HRV60s?.sdnn,
      timestamp: data.timestamp,
    );
  }
}
