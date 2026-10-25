import 'package:flutter_test/flutter_test.dart';
import 'package:scorex/data/cricapi_parser.dart';
import 'package:scorex/models/cricket_match.dart';

void main() {
  test('classifies boolean and string flags without treating false as live', () {
    expect(cricApiStatus({'matchStarted': true, 'matchEnded': false}), MatchStatus.live);
    expect(cricApiStatus({'matchStarted': 'true', 'matchEnded': 'false'}), MatchStatus.live);
    expect(cricApiStatus({'matchStarted': 'false'}), MatchStatus.upcoming);
    expect(cricApiStatus({'matchEnded': 'true'}), MatchStatus.completed);
    expect(cricApiStatus({'status': 'Argentina Women won by 165 runs'}), MatchStatus.completed);
    expect(cricApiStatus({'status': 'Match abandoned', 'matchEnded': true}), MatchStatus.abandoned);
    expect(cricApiStatus({}), MatchStatus.unknown);
  });

  test('cleans screenshot innings labels without guessing ambiguous team', () {
    final scores = cricApiScores({
      'teams': ['Mexico Women', 'Argentina Women'],
      'score': [
        {'inning': 'argentina women Inning 1', 'r': 188, 'w': 5, 'o': 20},
        {'inning': 'Mexico Women,Argentina Women Inning 1', 'r': 23, 'w': 10, 'o': 9.3},
      ],
    });
    expect(scores[0], {'team': 'Argentina Women', 'score': '188/5 (20 ov)'});
    expect(scores[1], {'team': 'Innings 2', 'score': '23/10 (9.3 ov)'});
    expect(cricApiInningsTeam('Mexico Women Innings 1', ['Mexico Women']), 'Mexico Women');
    expect(cricApiScores({'score': null}), isEmpty);
  });

  test('does not confuse teams with a shared prefix', () {
    expect(cricApiInningsTeam('India Women Inning 1', ['India', 'India Women']), 'India Women');
  });

  test('interprets zone-less GMT timestamps as UTC', () {
    final time = cricApiStartTime({'dateTimeGMT': '2026-10-25T14:00:00'});
    expect(time, DateTime.utc(2026, 10, 25, 14));
    expect(time!.isUtc, isTrue);
  });
}
