// lib/src/ui/screens/explore_screen.dart
import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ListView(
        children: [
          const Text('Explore', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Search cities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  SizedBox(height: 120, child: Center(child: Text('Explore UI placeholder', style: TextStyle(color: Colors.grey)))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(child: ListTile(title: const Text('Popular city: Delhi'), subtitle: const Text('AQI snapshot'))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
