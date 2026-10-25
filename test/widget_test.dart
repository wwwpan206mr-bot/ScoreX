import 'package:flutter/material.dart';
import 'package:scorex/screens/cricket_match_centre.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scorex/main.dart';
import 'package:scorex/screens/feature_pages.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('ScoreX launches with its branding', (tester) async {
    await tester.pumpWidget(const ScoreXApp());
    await tester.pump();
    expect(find.text('ScoreX'), findsWidgets);
  });

  testWidgets('feature screen presents its verified-data capabilities', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ScoreXFeaturePage(title: 'Live score')),
    );
    await tester.pump();
    expect(find.text('Live score'), findsWidgets);
    expect(find.text('ADDITIONAL CAPABILITIES'), findsOneWidget);
    expect(find.text('Live score and innings'), findsOneWidget);
  });

  testWidgets('news screen does not invent headlines', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ScoreXFeaturePage(title: 'News & Videos')),
    );
    await tester.pump();
    expect(find.text('News and highlights source not connected'), findsOneWidget);
  });

  testWidgets('match centre retains score header when switching tabs', (tester) async {
    var refreshed = false;
    await tester.pumpWidget(MaterialApp(home: CricketMatchCentre(
      title: 'Team A vs Team B',
      status: 'Team A batting',
      scores: const [{'team': 'Team A', 'score': '120/3 (15 ov)'}],
      onRefresh: () => refreshed = true,
    )));
    expect(find.text('120/3 (15 ov)'), findsOneWidget);
    await tester.tap(find.text('Scorecard'));
    await tester.pumpAndSettle();
    expect(find.text('120/3 (15 ov)'), findsOneWidget);
    expect(find.text('No verified scorecard available yet'), findsOneWidget);
    await tester.tap(find.byTooltip('Refresh match'));
    expect(refreshed, isTrue);
  });
}
