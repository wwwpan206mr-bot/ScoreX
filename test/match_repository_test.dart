import 'package:flutter_test/flutter_test.dart';
import 'package:scorex/data/match_repository.dart';
import 'package:scorex/models/cricket_match.dart';

void main() {
  test('CricketMatch parses provider-neutral JSON', () {
    final match = CricketMatch.fromJson({
      'id': 'match-1',
      'title': 'Fixture',
      'status': 'live',
      'teamA': 'Team A',
      'teamB': 'Team B',
      'startTime': '2026-10-21T12:00:00Z',
    });

    expect(match.id, 'match-1');
    expect(match.status, MatchStatus.live);
    expect(match.teamA, 'Team A');
    expect(match.startTime, isNotNull);
  });

  test('unconfigured repository returns no fabricated matches', () async {
    const repository = UnconfiguredMatchRepository();
    expect(await repository.getMatches(), isEmpty);
    expect(await repository.getMatches(status: MatchStatus.live), isEmpty);
  });
}
