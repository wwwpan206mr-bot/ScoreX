import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scorex/models/ball_event.dart';
import 'package:scorex/screens/advanced_analytics.dart';

void main() {
  testWidgets('analytics explains the experimental chasing-side estimate', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ScoreXAdvancedAnalytics(
          chasingProbability: 63,
          deliveries: [
            BallEvent(over: 0, ball: 1, runs: 1),
            BallEvent(over: 0, ball: 2, runs: 4, batterRuns: 4),
            BallEvent(over: 1, ball: 1, runs: 6, batterRuns: 6),
          ],
        ),
      ),
    ));

    expect(find.text('Chasing-side model estimate'), findsOneWidget);
    expect(find.text('63%'), findsOneWidget);
    expect(find.textContaining('not an AI prediction'), findsOneWidget);
    expect(find.text('Manhattan — runs per over'), findsOneWidget);
    expect(find.text('Current partnership'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('analytics never invents a probability or delivery chart', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ScoreXAdvancedAnalytics()),
    ));

    expect(find.textContaining('Unavailable'), findsOneWidget);
    expect(find.text('No ball-by-ball data available.'), findsOneWidget);
    expect(find.text('Not available from the provider'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
