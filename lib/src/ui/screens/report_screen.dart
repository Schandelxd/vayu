// lib/src/ui/screens/report_screen.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/geolocation_service.dart';
import '../../services/waqi_api_service.dart';
import '../../services/aqi_history_store.dart';
import '../../models/air_quality.dart';
import '../widgets/personalized_report_card.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  final GeolocationService _geo = GeolocationService();

  double _aqi = 72;
  Map<String, double> _components = {
    'PM2.5': 35.0,
    'PM10': 58.0,
    'O₃': 12.0,
    'NO₂': 18.0,
    'SO₂': 4.0,
    'CO': 0.4,
  };

  AirQualityReport? _liveReport;
  bool _locLoading = false;
  String? _latLon;
  bool _fetchingAqi = false;

  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Color _aqiColor(double aqi) {
    if (aqi <= 50) return const Color(0xFF2ECC71);
    if (aqi <= 100) return const Color(0xFFF1C40F);
    if (aqi <= 150) return const Color(0xFFE67E22);
    if (aqi <= 200) return const Color(0xFFE74C3C);
    if (aqi <= 300) return const Color(0xFF8E44AD);
    return const Color(0xFF6B4C2B);
  }

  String _aqiStatus(double aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Map<String, double> _parseComponents(dynamic raw) {
    final out = <String, double>{};
    if (raw == null) return out;

    try {
      if (raw is Map) {
        for (final e in raw.entries) {
          final key = e.key.toString();
          final val = e.value;
          double? dv;

          if (val is double) {
            dv = val;
          } else if (val is int) dv = val.toDouble();
          else if (val is String) dv = double.tryParse(val.replaceAll(",", ""));

          if (dv != null) {
            final kl = key.toLowerCase();
            if (kl.contains("pm25") || kl.contains("pm2.5")) {
              out["PM2.5"] = dv;
            } else if (kl.contains("pm10")) out["PM10"] = dv;
            else if (kl.contains("no2")) out["NO₂"] = dv;
            else if (kl.contains("o3")) out["O₃"] = dv;
            else if (kl.contains("so2")) out["SO₂"] = dv;
            else if (kl.contains("co")) out["CO"] = dv;
          }
        }
      }
    } catch (_) {}
    return out;
  }

  Future<void> _fetchLocation() async {
    if (!mounted) return;

    setState(() => _locLoading = true);

    try {
      final pos = await _geo.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _latLon =
            "${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location: $_latLon")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location error: $e")),
      );
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  Future<void> _fetchLiveAqi() async {
    if (!mounted) return;

    setState(() => _fetchingAqi = true);

    try {
      final pos = await _geo.getCurrentPosition();
      if (!mounted) return;

      final waqi = WaqiApiService(dio: Dio());
      final report = await waqi.fetchByGeo(pos.latitude, pos.longitude);
      if (!mounted) return;

      final parsed = _parseComponents(report.components);

      setState(() {
        _liveReport = report;
        _aqi = report.aqi;

        if (parsed.isNotEmpty) {
          _components = {..._components, ...parsed};
        }
      });

      // store the fetched report so InsightsScreen receives it
      AqiHistoryStore.instance.addReport(report);

      _animCtrl.forward(from: 0.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AQI ${report.aqi}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fetch error: $e")),
      );
    } finally {
      if (mounted) setState(() => _fetchingAqi = false);
    }
  }

  Future<void> _searchByCity() async {
    final ctrl = TextEditingController();

    final city = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Search city"),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter city name",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text("Search"),
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
          )
        ],
      ),
    );

    if (city == null || city.isEmpty) return;

    setState(() => _fetchingAqi = true);

    try {
      final waqi = WaqiApiService(dio: Dio());
      final report = await waqi.fetchByCity(city);

      final parsed = _parseComponents(report.components);

      setState(() {
        _liveReport = report;
        _aqi = report.aqi;
        _components = {..._components, ...parsed};
      });

      // save into history so Insights picks it up
      AqiHistoryStore.instance.addReport(report);

      _animCtrl.forward(from: 0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AQI ${report.aqi} for $city")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Search error: $e")),
      );
    } finally {
      if (mounted) setState(() => _fetchingAqi = false);
    }
  }

  IconData _iconForPollutant(String key) {
    final k = key.toLowerCase();
    if (k.contains("pm2")) return Icons.grain;
    if (k.contains("pm10")) return Icons.blur_on;
    if (k.contains("no2")) return Icons.cloud_queue;
    if (k.contains("o3")) return Icons.wb_sunny;
    if (k.contains("so2")) return Icons.ac_unit;
    if (k.contains("co")) return Icons.local_gas_station;
    return Icons.biotech;
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = _aqiColor(_aqi);
    final status = _aqiStatus(_aqi);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _fetchLiveAqi,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          physics: const BouncingScrollPhysics(),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    headerColor.withOpacity(0.9),
                    headerColor.withOpacity(0.75),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Current Air",
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),

                      // location button
                      IconButton(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: _fetchLocation,
                        icon: _locLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, color: Colors.white),
                      ),

                      const SizedBox(width: 4),

                      // Live AQI
                      !_fetchingAqi
                          ? IconButton(
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 40, minHeight: 40),
                              onPressed: _fetchLiveAqi,
                              icon:
                                  const Icon(Icons.cloud, color: Colors.white),
                            )
                          : const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),

                      const SizedBox(width: 4),

                      // search
                      IconButton(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: _searchByCity,
                        icon: const Icon(Icons.search, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Text(
                        _aqi.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 56,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(status,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            _liveReport?.city ?? "Unknown location",
                            style: const TextStyle(color: Colors.white70),
                          )
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // pollutants horizontal
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        ..._components.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                Icon(_iconForPollutant(e.key),
                                    color: Colors.white, size: 18),
                                const SizedBox(height: 4),
                                Text(e.key,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text("${e.value.toInt()}",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // pollutant cards
            ..._components.entries.map(
              (e) {
                final pct = (e.value / 500).clamp(0.0, 1.0);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: headerColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_iconForPollutant(e.key),
                              color: headerColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(e.key,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Text(e.value.toStringAsFixed(1)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                      AlwaysStoppedAnimation(headerColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // personalized card (uses SharedPreferences profile)
            PersonalizedReportCard(aqi: _aqi.toInt()),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _fetchLiveAqi,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Refresh"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Raw Data"),
                          content: Text(_rawPreview(_liveReport)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Close"))
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.code),
                    label: const Text("Raw"),
                  ),
                )
              ],
            ),

            const SizedBox(height: 50)
          ],
        ),
      ),
    );
  }

  String _rawPreview(AirQualityReport? r) {
    if (r == null) return "No report";
    try {
      final comps = (r.components as Map)
              .entries
              .map((e) => "${e.key}: ${e.value}")
              .join(", ");

      return """
city: ${r.city}
aqi: ${r.aqi}
timestamp: ${r.timestamp}
components: $comps
""";
    } catch (e) {
      return r.toString();
    }
  }
}
