// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic scaffold smoke test', (WidgetTester tester) async {
    // Build a minimal app to ensure widget environment is healthy
    await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: AppBar(title: const Text('Smoke')))));
    await tester.pumpAndSettle();

    // Basic expectations
    expect(find.text('Smoke'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
