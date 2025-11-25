// lib/src/services/waqi_api_service.dart
import 'package:dio/dio.dart';
import '../models/air_quality.dart';

class WaqiApiService {
  final Dio _dio;
  final String _token;

  WaqiApiService({Dio? dio, required String token})
      : _dio = dio ?? Dio(),
        _token = token;

  /// Fetch AQI by latitude/longitude.
  Future<AirQualityReport> fetchByGeo(double lat, double lon) async {
    final url = 'https://api.waqi.info/feed/geo:$lat;$lon/?token=$_token';
    final resp = await _dio.get(url);
    if (resp.statusCode == 200 && resp.data is Map) {
      final json = resp.data as Map<String, dynamic>;
      if (json['status'] == 'ok') {
        return AirQualityReport.fromWaqiJson(json);
      } else {
        throw Exception('WAQI error: ${json['data'] ?? json}');
      }
    } else {
      throw Exception('Network error: ${resp.statusCode} ${resp.statusMessage}');
    }
  }

  /// Fetch AQI by city name (e.g. "Delhi" or "Los Angeles")
  Future<AirQualityReport> fetchByCity(String city) async {
    final encoded = Uri.encodeComponent(city);
    final url = 'https://api.waqi.info/feed/$encoded/?token=$_token';
    final resp = await _dio.get(url);
    if (resp.statusCode == 200 && resp.data is Map) {
      final json = resp.data as Map<String, dynamic>;
      if (json['status'] == 'ok') {
        return AirQualityReport.fromWaqiJson(json);
      } else {
        throw Exception('WAQI error: ${json['data'] ?? json}');
      }
    } else {
      throw Exception('Network error: ${resp.statusCode} ${resp.statusMessage}');
    }
  }
}
