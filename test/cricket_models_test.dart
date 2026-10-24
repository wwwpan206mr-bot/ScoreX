import 'package:flutter_test/flutter_test.dart';
import 'package:scorex/models/ball_event.dart';
import 'package:scorex/models/innings_summary.dart';

void main() {
  group('InningsSummary', () {
    test('uses six legal deliveries per over', () {
      const innings = InningsSummary(runs: 82, wickets: 2, legalBalls: 53);
      expect(innings.overs, '8.5');
      expect(innings.currentRunRate, closeTo(82 * 6 / 53, 0.0001));
    });

    test('calculates chase requirement using remaining balls', () {
      const innings = InningsSummary(
        runs: 100, wickets: 3, legalBalls: 60,
        target: 181, scheduledOvers: 20,
      );
      expect(innings.runsNeeded, 81);
      expect(innings.ballsRemaining, 60);
      expect(innings.requiredRunRate, 8.1);
    });

    test('does not divide by zero at the end of innings', () {
      const innings = InningsSummary(
        runs: 180, wickets: 8, legalBalls: 120,
        target: 181, scheduledOvers: 20,
      );
      expect(innings.requiredRunRate, isNull);
    });
  });

  group('BallEvent', () {
    test('identifies wicket and boundary markers', () {
      expect(const BallEvent(over: 1, ball: 2, runs: 0, isWicket: true).marker, 'W');
      expect(const BallEvent(over: 1, ball: 3, runs: 4, batterRuns: 4).marker, '4');
      expect(const BallEvent(over: 1, ball: 4, runs: 6, batterRuns: 6).marker, '6');
    });
    test('retains no-ball or wide as nonlegal when provider marks it', () {
      final event = BallEvent.fromJson({
        'over': 3, 'ball': 2, 'runs': 2, 'extras': 1,
        'isLegalDelivery': false,
      });
      expect(event.isLegalDelivery, isFalse);
      expect(event.extras, 1);
    });
  });
}
