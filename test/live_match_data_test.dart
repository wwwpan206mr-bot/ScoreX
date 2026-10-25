import 'package:flutter_test/flutter_test.dart';
import 'package:scorex/data/live_match_data.dart';

void main() {
  final now = DateTime.utc(2026, 10, 25, 18);
  Map<String, dynamic> event(String id, int sequence, {bool legal = true}) => {
    'id': id, 'sequence': sequence, 'inningsId': '2', 'over': 8, 'ball': 1,
    'runs': legal ? 0 : 1, 'batterRuns': 0, 'extras': legal ? 0 : 1,
    'isWicket': false, 'isLegalDelivery': legal, if (!legal) 'extraType': 'wide',
  };
  Map<String, dynamic> envelope(List<Map<String, dynamic>> events) => {'data': {
    'matchId': 'm1', 'inningsId': '2', 'source': 'Test fixture source',
    'updatedAt': '2026-10-25T18:00:00Z', 'deliveries': events,
  }};

  test('uses six legal balls per over and preserves decimal-over notation', () {
    expect(LiveSummary.legalBalls(9.3), 57);
    expect(LiveSummary.legalBalls(20), 120);
    expect(LiveSummary.legalBalls('19.6'), isNull);
  });

  test('parses a limited-overs chase and excludes revised targets', () {
    final match = <String, dynamic>{
      'matchType': 't20', 'teams': ['A', 'B'],
      'score': [
        {'r': 169, 'w': 4, 'o': 20, 'inning': 'A Inning 1'},
        {'r': 136, 'w': 4, 'o': 16, 'inning': 'B Inning 1'},
      ],
    };
    final data = LiveSummary.fromMatch(match);
    expect(data.innings!.runsNeeded, 34);
    expect(data.innings!.ballsRemaining, 24);
    expect(data.innings!.requiredRunRate, 8.5);
    expect(data.battingTeam, 'B');
    expect(data.bowlingTeam, 'A');
    expect(LiveSummary.fromMatch({...match, 'status': 'DLS revised target'}).innings!.target, isNull);
  });

  test('keeps separate wides at the same ball and orders by stable sequence', () {
    final feed = DeliveryFeed.parse(envelope([
      event('legal', 3), event('wide2', 2, legal: false),
      event('wide1', 1, legal: false), event('wide1', 1, legal: false),
      {...event('other-innings', 0), 'inningsId': '1'},
    ]), 'm1', now);
    expect(feed.deliveries.length, 3);
    expect(feed.deliveries.map((ball) => ball.marker), ['Wd', 'Wd', '0']);
    expect(feed.stale, isFalse);
  });

  test('rejects wrong matches, malformed runs, and unverifiable source times', () {
    expect(DeliveryFeed.parse(envelope([event('1', 1)]), 'other', now).deliveries, isEmpty);
    expect(DeliveryFeed.parse(envelope([{...event('1', 1), 'runs': -1}]), 'm1', now).deliveries, isEmpty);
    final invalid = envelope([event('1', 1)]);
    (invalid['data'] as Map)['updatedAt'] = '2026-10-25T18:00:00';
    expect(DeliveryFeed.parse(invalid, 'm1', now).deliveries, isEmpty);
  });

  test('marks delayed source data as stale without inventing replacement events', () {
    final feed = DeliveryFeed.parse(envelope([event('1', 1)]), 'm1', now.add(const Duration(minutes: 3)));
    expect(feed.stale, isTrue);
    expect(feed.deliveries.length, 1);
  });
}
