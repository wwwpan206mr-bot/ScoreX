import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scorex/models/cricket_match.dart';
import 'package:scorex/screens/live_match_centre.dart';

const initial = CricketMatch(id: 'm1', title: 'A vs B', status: MatchStatus.live,
  teamA: 'A', teamB: 'B', teamAScore: '53/4 (9 ov)');

void main() {
  testWidgets('card score opens immediately and delivery request starts in parallel', (tester) async {
    final pending = Completer<http.Response>();
    final requests = <String>[];
    final client = MockClient((request) async {
      requests.add(request.url.path);
      if (request.url.path == '/match') return pending.future;
      return http.Response('{"data":null,"available":false}', 200);
    });
    await tester.pumpWidget(MaterialApp(home: LiveMatchCentre(matchId: 'm1', initialMatch: initial,
      client: client, apiBaseUrl: 'https://test.invalid')));
    await tester.pump();
    expect(find.text('53/4 (9 ov)'), findsOneWidget);
    expect(requests, containsAll(['/match', '/live']));
    pending.complete(http.Response(jsonEncode({'data': {'id': 'm1', 'name': 'A vs B', 'matchStarted': true,
      'matchEnded': false, 'teams': ['A', 'B'], 'score': [{'r': 54, 'w': 4, 'o': 9.1, 'inning': 'A Inning 1'}]}}), 200));
    await tester.pumpAndSettle();
    expect(find.textContaining('54/4'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    client.close();
  });

  testWidgets('late response from a previous match never replaces the selected match', (tester) async {
    final old = Completer<http.Response>();
    final client = MockClient((request) async {
      if (request.url.path == '/live') return http.Response('{"data":null}', 200);
      if (request.url.queryParameters['id'] == 'm1') return old.future;
      return http.Response(jsonEncode({'data': {'id': 'm2', 'name': 'New match',
        'matchStarted': false, 'matchEnded': false, 'teams': ['C', 'D']}}), 200);
    });
    Widget page(String id) => MaterialApp(home: LiveMatchCentre(matchId: id,
      client: client, apiBaseUrl: 'https://test.invalid'));
    await tester.pumpWidget(page('m1'));
    await tester.pumpWidget(page('m2'));
    old.complete(http.Response(jsonEncode({'data': {'id': 'm1', 'name': 'Wrong old match'}}), 200));
    await tester.pumpAndSettle();
    expect(find.text('New match'), findsOneWidget);
    expect(find.text('Wrong old match'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    client.close();
  });
}
