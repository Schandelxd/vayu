// lib/src/ui/screens/insights_screen.dart

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/aqi_history_store.dart';
import '../../models/air_quality.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  /// Build FlSpots for AQI trend line
  List<FlSpot> _spotsFromRecords(List<AirQualityReport> records, {int take = 7}) {
    final list = records.length > take ? records.sublist(records.length - take) : records;
    final aqiVals = list.map((e) => e.aqi).toList();

    // Pad left if less than take
    while (aqiVals.length < take) {
      aqiVals.insert(0, aqiVals.isNotEmpty ? aqiVals.first : 0);
    }

    return List.generate(aqiVals.length, (i) => FlSpot(i.toDouble(), aqiVals[i]));
  }

  double _maxY(List<AirQualityReport> r) {
    if (r.isEmpty) return 120;
    final sub = r.length > 7 ? r.sublist(r.length - 7) : r;
    final m = sub.map((e) => e.aqi).reduce(math.max);
    return m + 40;
  }

  String _normalize(String key) =>
      key.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();

  // Improved numeric parser: extracts first numeric token (handles "12 µg/m³", "1,234.5", etc.)
  double? _toDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();

    final s = val.toString().trim();

    // Remove unicode minus/dash variants, keep digits, comma, dot, plus, minus
    final cleaned = s.replaceAll(RegExp(r'[^\d\.,\-\+]'), '');

    // Find a numeric token
    final match = RegExp(r'[-+]?\d{1,3}(?:[,]\d{3})*(?:\.\d+)?|[-+]?\d+\.\d+|[-+]?\d+')
        .firstMatch(cleaned);
    if (match == null) return null;

    final numStr = match.group(0)!.replaceAll(',', '');
    return double.tryParse(numStr);
  }

  double? _findValue(Map<String, dynamic>? map, String display) {
    if (map == null) return null;
    final t = _normalize(display);

    // Direct normalized lookup
    for (final e in map.entries) {
      final nk = _normalize(e.key.toString());
      if (nk == t) {
        final v = _toDouble(e.value);
        if (v != null) return v;
      }
    }

    // Try common variants: pm25 <-> pm2.5 etc.
    final altVariants = <String>{
      t,
      t.replaceAll('25', '2.5'),
      t.replaceAll('2.5', '25'),
    };

    for (final e in map.entries) {
      final nk = _normalize(e.key.toString());
      if (altVariants.contains(nk)) {
        final v = _toDouble(e.value);
        if (v != null) return v;
      }
    }

    // If map values are nested maps (e.g., { "pm25": {"v": 12} }) dig one level
    for (final e in map.entries) {
      if (e.value is Map) {
        try {
          final nested = Map<String, dynamic>.from(e.value as Map);
          for (final ne in nested.entries) {
            if (_normalize(ne.key) == t) {
              final v = _toDouble(ne.value);
              if (v != null) return v;
            }
          }
          // sometimes nested map has 'v'
          if (nested.containsKey('v')) {
            final v = _toDouble(nested['v']);
            if (v != null) return v;
          }
        } catch (_) {}
      }
    }

    // Final fallback: try to return any numeric value present (best-effort)
    for (final e in map.entries) {
      final v = _toDouble(e.value);
      if (v != null) return v;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    const pollutants = ["PM2.5", "PM10", "NO₂", "O₃", "SO₂", "CO"];

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        const Text(
          "Insights & Trends",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        ValueListenableBuilder<List<AirQualityReport>>(
          valueListenable: AqiHistoryStore.instance.recordsNotifier,
          builder: (context, list, _) {
            // Debug: show length & latest components when records change
            // ignore: avoid_print
            print('Insights: records length=${list.length} latestComponents=${list.isNotEmpty ? list.last.components : 'null'}');

            final spots = _spotsFromRecords(list);
            final maxY = _maxY(list);

            Map<String, dynamic>? latest;
            if (list.isNotEmpty) {
              // components in your model is Map<String,double> — convert for flexible lookup
              final compRaw = list.last.components;
              try {
                latest = Map<String, dynamic>.from(compRaw);
              } catch (_) {
                // if conversion fails, try to encode/decode as safer fallback
                try {
                  latest = jsonDecode(jsonEncode(compRaw)) as Map<String, dynamic>;
                } catch (_) {
                  latest = null;
                }
              }
            }

            final barValues = pollutants.map((p) {
              final v = _findValue(latest, p);
              return (v ?? 0).clamp(0, 500).toDouble();
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------- Trend Chart ----------------------------
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.indigo.shade600.withOpacity(0.9),
                        Colors.indigo.shade400.withOpacity(0.85),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.shade200.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "7-Day AQI Trend",
                        style: TextStyle(
                            fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 250,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxY,
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: maxY / 4,
                                  getTitlesWidget: (v, meta) => Text(
                                    v.toInt().toString(),
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (v, meta) => Text(
                                    "D${v.toInt()}",
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                isCurved: true,
                                barWidth: 4,
                                color: Colors.white,
                                dotData: FlDotData(show: true),
                                spots: spots,
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.25),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                // tooltipRoundedRadius removed for fl_chart ^1.1.1 compatibility
                                tooltipPadding: const EdgeInsets.all(8),
                                getTooltipItems: (touched) {
                                  return touched.map((spot) {
                                    return LineTooltipItem(
                                      "${spot.y.toInt()}",
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ------------------------- Pollutants Chart -------------------------
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pollutant Levels",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 260,
                        child: BarChart(
                          BarChartData(
                            gridData: FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            alignment: BarChartAlignment.spaceAround,
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  interval: 50,
                                  getTitlesWidget: (v, meta) =>
                                      Text(v.toInt().toString(),
                                          style: const TextStyle(fontSize: 11)),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, meta) =>
                                      Text(pollutants[v.toInt()],
                                          style: const TextStyle(fontSize: 11)),
                                  interval: 1,
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            barGroups: List.generate(pollutants.length, (i) {
                              final v = barValues[i];
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: v,
                                    width: 20,
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.indigo.shade400,
                                        Colors.indigo.shade700
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ],
                              );
                            }),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                // tooltipRoundedRadius removed for fl_chart ^1.1.1 compatibility
                                tooltipPadding: const EdgeInsets.all(8),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    "${pollutants[group.x.toInt()]}\n${rod.toY.toStringAsFixed(1)}",
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ],
    );
  }
}
