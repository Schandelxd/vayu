// lib/src/ui/widgets/personalized_report_card.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/personalization_service.dart';

/// A reusable widget that:
/// - loads user profile from SharedPreferences
/// - computes personalization using PersonalizationService
/// - shows recommendations
/// - provides "What if" toggles (simulate smoker/asthma)
/// - lets user save the computed score into a local risk history
class PersonalizedReportCard extends StatefulWidget {
  final int aqi;
  const PersonalizedReportCard({super.key, required this.aqi});

  @override
  State<PersonalizedReportCard> createState() => _PersonalizedReportCardState();
}

class _PersonalizedReportCardState extends State<PersonalizedReportCard> {
  bool loading = true;
  PersonalizationResult? result;

  // real profile values read from prefs
  int? _age;
  bool _smoker = false;
  bool _asthma = false;
  bool _chronic = false;

  // "what if" simulated toggles (start as real values)
  bool _simSmoker = false;
  bool _simAsthma = false;

  @override
  void initState() {
    super.initState();
    _loadAndCompute();
  }

  Future<void> _loadAndCompute() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();

    final age = prefs.containsKey('local_age') ? prefs.getInt('local_age') : null;
    final smoker = prefs.getBool('local_smoking') ?? false;
    final asthma = prefs.getBool('local_asthma') ?? false;
    final chronic = prefs.getBool('local_chronic') ?? false;

    _age = age;
    _smoker = smoker;
    _asthma = asthma;
    _chronic = chronic;

    _simSmoker = smoker;
    _simAsthma = asthma;

    _compute();

    if (mounted) setState(() => loading = false);
  }

  void _compute() {
    result = PersonalizationService.generate(
      aqi: widget.aqi,
      age: _age,
      smoker: _simSmoker,
      asthma: _simAsthma,
      chronic: _chronic,
    );
  }

  Future<void> _saveToHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    final entry = {
      'timestamp': now,
      'aqi': widget.aqi,
      'riskScore': result!.riskScore,
      'riskLevel': result!.riskLevel,
      'age': _age,
      'smoker': _simSmoker,
      'asthma': _simAsthma,
      'chronic': _chronic,
    };

    final existing = prefs.getString('risk_history');
    List<dynamic> arr = [];
    if (existing != null) {
      try {
        arr = jsonDecode(existing) as List<dynamic>;
      } catch (_) {
        arr = [];
      }
    }
    arr.add(entry);

    await prefs.setString('risk_history', jsonEncode(arr));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved risk snapshot')));
  }

  @override
  Widget build(BuildContext context) {
    if (loading || result == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final r = result!;
    Color levelColor;
    if (r.riskLevel == "Low") {
      levelColor = Colors.green;
    } else if (r.riskLevel == "Moderate") levelColor = Colors.orange;
    else if (r.riskLevel == "High") levelColor = Colors.redAccent;
    else levelColor = Colors.deepPurple;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: levelColor, child: Text('${r.riskScore}', style: const TextStyle(color: Colors.white))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Personalized risk: ${r.riskLevel}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(r.shortMessage),
              ]),
            ),
            Text('AQI ${widget.aqi}', style: const TextStyle(color: Colors.grey)),
          ]),

          const SizedBox(height: 12),
          const Text('Recommendations', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...r.recommendations.map((rec) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [const Icon(Icons.chevron_right, size: 18), const SizedBox(width: 6), Expanded(child: Text(rec))]),
          )),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // What-if simulator
          Text('What if (simulate)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Row(children: [
              const Text('Smoker'),
              const Spacer(),
              Switch(value: _simSmoker, onChanged: (v) {
                setState(() {
                  _simSmoker = v;
                  _compute();
                });
              })
            ])),
            const SizedBox(width: 8),
            Expanded(child: Row(children: [
              const Text('Asthma'),
              const Spacer(),
              Switch(value: _simAsthma, onChanged: (v) {
                setState(() {
                  _simAsthma = v;
                  _compute();
                });
              })
            ])),
          ]),

          const SizedBox(height: 10),
          Row(children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save snapshot'),
              onPressed: _saveToHistory,
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('View history'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final raw = prefs.getString('risk_history') ?? '[]';
                // small viewer dialog
                if (!mounted) return;
                showDialog(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Saved snapshots'),
                  content: SingleChildScrollView(child: Text(raw)),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                ));
              },
            ),
          ]),
        ]),
      ),
    );
  }
}
