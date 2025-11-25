import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Insights & Trends',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // --- AQI WEEKLY LINE CHART ---
        const Text('7-Day AQI Trend', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(show: true),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: Colors.indigo,
                  barWidth: 3,
                  spots: const [
                    FlSpot(0, 72),
                    FlSpot(1, 89),
                    FlSpot(2, 65),
                    FlSpot(3, 110),
                    FlSpot(4, 134),
                    FlSpot(5, 92),
                    FlSpot(6, 76),
                  ],
                )
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // --- POLLUTANT BAR CHART ---
        const Text('Pollutant Levels', 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              barGroups: [
                _bar('PM2.5', 35),
                _bar('PM10', 58),
                _bar('NO₂', 18),
                _bar('O₃', 12),
                _bar('SO₂', 4),
                _bar('CO', 1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

BarChartGroupData _bar(String label, double value) {
  return BarChartGroupData(
    x: label.hashCode,
    barRods: [
      BarChartRodData(
        toY: value,
        color: Colors.indigo,
        width: 20,
      ),
    ],
    showingTooltipIndicators: [0],
  );
}
