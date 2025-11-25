// lib/src/models/air_quality.dart
class AirQualityReport {
  final double aqi;
  final String city;
  final DateTime timestamp;
  final Map<String, double> components; // pm25, pm10, o3, no2, so2, co

  AirQualityReport({
    required this.aqi,
    required this.city,
    required this.timestamp,
    required this.components,
  });

  factory AirQualityReport.fromWaqiJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final iaqi = data['iaqi'] ?? {};
    final comps = <String, double>{};
    iaqi.forEach((key, value) {
      if (value is Map && value['v'] != null) {
        final v = value['v'];
        if (v is num) comps[key] = v.toDouble();
      }
    });

    final aqiVal = data['aqi'];
    final aqi = (aqiVal is num) ? aqiVal.toDouble() : double.tryParse('$aqiVal') ?? 0.0;
    final city = (data['city'] is Map && data['city']['name'] != null)
        ? data['city']['name'] as String
        : 'Unknown';
    DateTime ts = DateTime.now();
    final timeObj = data['time'];
    if (timeObj is Map && timeObj['s'] != null) {
      try {
        ts = DateTime.parse(timeObj['s']);
      } catch (_) {}
    }

    return AirQualityReport(aqi: aqi, city: city, timestamp: ts, components: comps);
  }
}
