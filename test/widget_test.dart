import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:scorex/screens/account_page.dart';
import 'package:scorex/services/scorex_auth.dart';
import 'package:scorex/screens/cricket_match_centre.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scorex/main.dart';
import 'package:scorex/data/match_repository.dart';
import 'package:scorex/models/cricket_match.dart';
import 'package:scorex/models/ball_event.dart';
import 'package:scorex/models/innings_summary.dart';
import 'package:scorex/models/win_estimate.dart';
import 'package:scorex/widgets/live_score_dashboard.dart';
import 'package:scorex/screens/feature_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key == 'assets/branding/firebase_config.json') {
        return ByteData.sublistView(Uint8List.fromList(utf8.encode('{}')));
      }
      return null;
    });
  });

  testWidgets('ScoreX launches with its branding', (tester) async {
    await tester.pumpWidget(const ScoreXApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('ScoreX'), findsWidgets);
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

  testWidgets('completed match opens result summary without a waiting message', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CricketMatchCentre(
      title: 'Mexico Women vs Argentina Women',
      completed: true,
      status: 'Argentina Women won by 165 runs',
      scores: [{'team': 'Argentina Women', 'score': '188/5 (20 ov)'}],
    )));
    expect(find.text('Result'), findsOneWidget);
    expect(find.text('Match result'), findsOneWidget);
    expect(find.text('Ball-by-ball commentary unavailable'), findsOneWidget);
    expect(find.text('Live'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live dashboard renders real delivery markers and experimental percentages', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LiveScoreDashboard(
      innings: InningsSummary(runs: 136, wickets: 4, legalBalls: 96, target: 170, scheduledOvers: 20),
      battingTeam: 'Team B', bowlingTeam: 'Team A', estimate: WinEstimate(60, 39, 1),
      deliveries: [
        BallEvent(over: 15, ball: 5, runs: 0, isWicket: true),
        BallEvent(over: 15, ball: 6, runs: 4, batterRuns: 4),
      ],
    ))));
    expect(find.text('34 runs needed in 24 balls'), findsOneWidget);
    expect(find.text('W'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Estimated win probability'), 150,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('60%'), findsOneWidget);
    expect(find.textContaining('not trained AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delayed data suppresses estimates instead of showing live percentages', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LiveScoreDashboard(
      stale: true, battingTeam: 'Team B', bowlingTeam: 'Team A', estimate: WinEstimate(60, 39, 1),
    ))));
    expect(find.textContaining('Updates delayed'), findsOneWidget);
    expect(find.textContaining('60%'), findsNothing);
    expect(find.textContaining('Estimate paused'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty live filter explains feed coverage and restores all matches', (tester) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // This screen renders the real bundled logo; retain the engine asset loader.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null);
    await tester.pumpWidget(MaterialApp(home: ScoreHomePage(
      darkMode: true, onThemeChanged: (_) {}, matchRepository: _ResultsOnlyRepository(),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(ChoiceChip).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ChoiceChip).at(1));
    await tester.pumpAndSettle();
    expect(find.text('No live matches in this feed'), findsOneWidget);
    expect(find.text('Completed fixture'), findsNothing);
    await tester.ensureVisible(find.text('View all matches'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View all matches'));
    await tester.pumpAndSettle();
    expect(find.text('Completed fixture'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('unconfigured builds provide a labelled device guest UID', (tester) async {
    final auth = ScoreXAuth.instance;
    await auth.initialize();
    await auth.enterGuest();
    expect(auth.uid, startsWith('device_guest_'));
    final firstUid = auth.uid;
    await auth.enterGuest();
    expect(auth.uid, firstUid);
    await tester.pumpWidget(const MaterialApp(home: ScoreXAccountPage()));
    expect(find.text('Guest account'), findsOneWidget);
    expect(find.text(firstUid!), findsOneWidget);
    expect(find.textContaining('Device-only guest ID'), findsOneWidget);
    expect(find.text('Create account'), findsNothing);
  });
}


class _ResultsOnlyRepository implements MatchRepository {
  @override
  Future<List<CricketMatch>> getMatches({MatchStatus? status}) async => const [
    CricketMatch(id: 'finished', title: 'Completed fixture', status: MatchStatus.completed,
      teamA: 'Team A', teamB: 'Team B', result: 'Team A won by 10 runs'),
  ];
}
