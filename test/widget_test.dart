import 'package:flutter/material.dart';
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
}
