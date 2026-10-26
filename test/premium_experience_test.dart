import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scorex/data/match_repository.dart';
import 'package:scorex/main.dart';
import 'package:scorex/models/cricket_match.dart';
import 'package:scorex/services/match_cache.dart';
import 'package:scorex/theme/scorex_theme.dart';
import 'package:scorex/widgets/premium_match_card.dart';
import 'package:scorex/widgets/live_score_dashboard.dart';
import 'package:scorex/models/ball_event.dart';
import 'package:scorex/models/innings_summary.dart';

const fixture = CricketMatch(id: 'verified-match', title: 'Long Team A vs Long Team B, 3rd T20I',
  status: MatchStatus.live, teamA: 'A very long cricket team name', teamB: 'Another long cricket team name',
  teamAScore: '153/4 (18.2 ov)', teamBScore: '150/8 (20 ov)', result: 'Team A batting');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('offline snapshot retains score values and source time; clearing keeps favorites', () async {
    final when = DateTime.utc(2026, 10, 25, 18);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('scorex_favorite_match_ids', ['verified-match']);
    await MatchCache.save([fixture], when);
    final snapshot = await MatchCache.read();
    expect(snapshot!.savedAt, when);
    expect(snapshot.matches.single.status, MatchStatus.live);
    expect(snapshot.matches.single.teamAScore, '153/4 (18.2 ov)');
    await MatchCache.clear();
    expect(await MatchCache.read(), isNull);
    expect(prefs.getStringList('scorex_favorite_match_ids'), ['verified-match']);
  });

  test('damaged device snapshot is ignored', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(MatchCache.key, '{broken data');
    expect(await MatchCache.read(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('score card fits 320px at large text in ${brightness.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(theme: ScoreXTheme.build(brightness),
        home: MediaQuery(data: const MediaQueryData(size: Size(320, 1200), textScaler: TextScaler.linear(2)),
          child: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(12),
            child: PremiumMatchCard(match: fixture, favorite: false, onFavorite: () {}, onTap: () {})))))));
      await tester.pumpAndSettle();
      expect(find.text('153/4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('refresh failure retains received scores with an explicit saved label', (tester) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: ScoreXTheme.build(Brightness.dark), home: ScoreHomePage(
      darkMode: true, onThemeChanged: (_) {}, matchRepository: _RefreshFailureRepository(),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();
    expect(find.text('153/4'), findsOneWidget);
    await tester.tap(find.byTooltip('Refresh scores'));
    await tester.pumpAndSettle();
    expect(find.text('153/4'), findsOneWidget);
    expect(find.text('Saved scores • updates delayed'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    expect(find.text('SAVED'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('home remains usable at 320px with large text and reduced motion', (tester) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: ScoreXTheme.build(Brightness.light),
      home: MediaQuery(data: const MediaQueryData(size: Size(320, 1100), textScaler: TextScaler.linear(2), disableAnimations: true),
        child: ScoreHomePage(darkMode: false, onThemeChanged: (_) {}, matchRepository: _RefreshFailureRepository()))));
    await tester.pumpAndSettle();
    expect(find.text('Cricket starts here'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('last ball appears only for a current active innings', (tester) async {
    for (final state in [(false, false), (true, false), (false, true)]) {
      await tester.pumpWidget(MaterialApp(theme: ScoreXTheme.build(Brightness.light),
        home: Scaffold(body: LiveScoreDashboard(
          innings: const InningsSummary(runs: 100, wickets: 2, legalBalls: 72),
          deliveries: const [BallEvent(over: 11, ball: 6, runs: 4, batterRuns: 4)],
          stale: state.$1, completed: state.$2,
        ))));
      await tester.pump();
      expect(find.text('LAST BALL'), !state.$1 && !state.$2 ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('settings theme switch updates immediately', (tester) async {
    bool? changed;
    await tester.pumpWidget(MaterialApp(theme: ScoreXTheme.build(Brightness.dark), home: ScoreXSettingsPage(
      darkMode: true, notificationsEnabled: false, onThemeChanged: (value) => changed = value,
      onNotificationsChanged: (_) {},
    )));
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pump();
    expect(changed, isFalse);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value, isFalse);
    expect(tester.takeException(), isNull);
  });
}

class _RefreshFailureRepository implements MatchRepository {
  var calls = 0;
  @override
  Future<List<CricketMatch>> getMatches({MatchStatus? status}) async {
    if (calls++ > 0) throw StateError('Connection lost');
    return [fixture];
  }
}
