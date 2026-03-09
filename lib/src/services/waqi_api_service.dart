// lib/src/services/waqi_api_service.dart

import 'package:dio/dio.dart';
import '../models/air_quality.dart';
import '../config.dart'; // <-- correct import for embedded token

class WaqiApiService {
  final Dio _dio;
  final String _token;

  /// If token is null/empty, use embedded token (kWaqiToken).
  WaqiApiService({Dio? dio, String? token})
      : _dio = dio ?? Dio(),
        _token = (token == null || token.isEmpty) ? kWaqiToken : token {
    // Debug — safe to keep during development
    // ignore: avoid_print
    print("WAQI using token: ${_token.substring(0, 6)}******");
  }

  /// Fetch live AQI using geolocation
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
    }
    throw Exception('Network error: ${resp.statusCode} ${resp.statusMessage}');
  }

  /// Fetch AQI by city name
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
    }
    throw Exception('Network error: ${resp.statusCode} ${resp.statusMessage}');
  }
}
