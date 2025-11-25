// lib/src/ui/screens/report_screen.dart
import 'package:flutter/material.dart';
import '../../services/geolocation_service.dart';
import 'package:dio/dio.dart';
import '../../services/waqi_api_service.dart';
import '../../models/air_quality.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Geolocation helper
  final GeolocationService _geo = GeolocationService();

  // Mock / visible UI state
  double _aqi = 72;
  Map<String, double> _components = {
    'PM2.5': 35.0,
    'PM10': 58.0,
    'O₃': 12.0,
    'NO₂': 18.0,
    'SO₂': 4.0,
    'CO': 0.4,
  };

  // New state: live report and loading flags
  AirQualityReport? _liveReport;
  bool _locLoading = false;
  String? _latLon;
  bool _fetchingAqi = false;

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _aqi = (_aqi + 3) % 400;
      _components['PM2.5'] = (_components['PM2.5']! + 0.8) % 500;
    });
  }

  String _aqiStatus(double aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Color _aqiColor(double aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }

  // --- Geolocation + WAQI interactions ---
  Future<void> _fetchLocation() async {
    setState(() => _locLoading = true);
    try {
      final pos = await _geo.getCurrentPosition();
      setState(() {
        _latLon = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location: $_latLon')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location error: $e')));
    } finally {
      setState(() => _locLoading = false);
    }
  }

  Future<void> _fetchLiveAqi() async {
    setState(() => _fetchingAqi = true);

    // Read token from --dart-define
    final token = const String.fromEnvironment('WAQI_TOKEN');
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('WAQI_TOKEN not provided. Run with --dart-define=WAQI_TOKEN=your_token'),
      ));
      setState(() => _fetchingAqi = false);
      return;
    }

    try {
      final pos = await _geo.getCurrentPosition();
      final waqi = WaqiApiService(dio: Dio(), token: token);
      final report = await waqi.fetchByGeo(pos.latitude, pos.longitude);

      setState(() {
        _liveReport = report;
        _aqi = report.aqi;
        _components = report.components;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AQI ${report.aqi.toInt()} @ ${report.city}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _fetchingAqi = false);
    }
  }

  Future<void> _searchByCity() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search city'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter city name (e.g. Delhi)'),
          onSubmitted: (_) => Navigator.of(ctx).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(controller.text.trim()), child: const Text('Search')),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    setState(() => _fetchingAqi = true);
    final token = const String.fromEnvironment('WAQI_TOKEN');
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WAQI_TOKEN not provided. Run with --dart-define')));
      setState(() => _fetchingAqi = false);
      return;
    }

    try {
      final waqi = WaqiApiService(dio: Dio(), token: token);
      final report = await waqi.fetchByCity(result);
      setState(() {
        _liveReport = report;
        _aqi = report.aqi;
        _components = report.components;
        _latLon = null; // optional: clear GPS since this is city-based
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AQI ${report.aqi.toInt()} @ ${report.city}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search error: $e')));
    } finally {
      setState(() => _fetchingAqi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        // extra top padding so header (in main.dart) doesn't overlap
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 16),

          // --- Responsive title + controls (replaced old Row with this LayoutBuilder) ---
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth <= 420;

              // Title widget
              final title = Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  'Current Air Report',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              );

              // Controls builder (returns either compact wrap or full buttons)
              Widget buildControls() {
                // compact icon buttons (used when wrapping or narrow)
                final compact = <Widget>[
                  IconButton(
                    tooltip: 'Get location',
                    onPressed: _fetchLocation,
                    icon: const Icon(Icons.my_location),
                  ),
                  _fetchingAqi
                      ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          tooltip: 'Fetch AQI',
                          onPressed: _fetchLiveAqi,
                          icon: const Icon(Icons.cloud),
                        ),
                  IconButton(
                    tooltip: 'Search city',
                    onPressed: _searchByCity,
                    icon: const Icon(Icons.search),
                  ),
                ];

                // full text buttons
                final full = <Widget>[
                  TextButton.icon(
                    onPressed: _fetchLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Get Location'),
                  ),
                  const SizedBox(width: 8),
                  _fetchingAqi
                      ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton.icon(
                          onPressed: _fetchLiveAqi,
                          icon: const Icon(Icons.cloud),
                          label: const Text('Fetch Live AQI'),
                        ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _searchByCity,
                    icon: const Icon(Icons.search),
                    label: const Text('Search City'),
                  ),
                ];

                if (isNarrow) {
                  return Wrap(
                    spacing: 4,
                    runSpacing: 0,
                    alignment: WrapAlignment.end,
                    children: compact,
                  );
                } else {
                  return Row(mainAxisSize: MainAxisSize.min, children: full);
                }
              }

              // Narrow: stack title above controls
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: title),
                        if (_locLoading) const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: buildControls()),
                  ],
                );
              }

              // Wide: single row with title left and controls right
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: title),
                  if (_locLoading)
                    const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Flexible(child: Align(alignment: Alignment.centerRight, child: buildControls())),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          if (_latLon != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Location: $_latLon', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),

          // AQI card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _aqiColor(_aqi).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _aqiColor(_aqi).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: _aqiColor(_aqi),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _aqi.toInt().toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_aqiStatus(_aqi), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Outdoor air quality based on WAQI data. Pull down to refresh.'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open detailed report (TODO)')));
                                },
                                icon: const Icon(Icons.analytics),
                                label: const Text('Details'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share (TODO)')));
                                },
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),

                // show live report meta
                if (_liveReport != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('Source: ${_liveReport!.city} • ${_liveReport!.timestamp.toLocal()}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text('Components', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Components list
          ..._components.entries.map((e) {
            final name = e.key;
            final value = e.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                dense: true,
                title: Text(name),
                trailing: Text(value.toStringAsFixed(1)),
              ),
            );
          }).toList(),

          const SizedBox(height: 24),

          // Quick advice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Advice', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('• ${_aqiStatus(_aqi)} — ${_aqi <= 100 ? 'No special precautions' : 'Consider wearing a mask or limiting outdoor activity'}'),
                const SizedBox(height: 6),
                const Text('• Stay hydrated and check hourly updates.'),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
