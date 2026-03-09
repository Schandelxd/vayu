// lib/src/services/aqi_history_store.dart
import 'package:flutter/foundation.dart';
import '../models/air_quality.dart';

class AqiHistoryStore {
  AqiHistoryStore._private();
  static final AqiHistoryStore instance = AqiHistoryStore._private();

  final List<AirQualityReport> _records = [];

  /// Notifier which publishes an immutable snapshot of the records list.
  final ValueNotifier<List<AirQualityReport>> recordsNotifier = ValueNotifier<List<AirQualityReport>>(const []);

  /// Read-only view of stored records
  List<AirQualityReport> get records => List.unmodifiable(_records);

  /// ValueListenable for UI to listen to updates
  ValueListenable<List<AirQualityReport>> get listenable => recordsNotifier;

  /// Add a full AirQualityReport record (keeps last 50)
  void addReport(AirQualityReport report) {
    _records.add(report);
    if (_records.length > 50) {
      _records.removeAt(0);
    }

    // publish a new snapshot (new list instance)
    recordsNotifier.value = List<AirQualityReport>.unmodifiable(_records);

    // Debug: show brief log so we can confirm data flow during development
    // ignore: avoid_print
    print('AqiHistoryStore: added AQI=${report.aqi.toStringAsFixed(1)} city=${report.city} total=${_records.length}');
  }

  /// Convenience: keep older API for adding a raw AQI value if needed.
  /// This creates a minimal AirQualityReport with timestamp=now and empty components.
  void add(double value) {
    final rec = AirQualityReport(
      aqi: value,
      components: <String, double>{},
      city: 'unknown',
      timestamp: DateTime.now(),
    );
    addReport(rec);
  }

  /// Clear history (useful for testing)
  void clear() {
    _records.clear();
    recordsNotifier.value = const [];
  }
}
