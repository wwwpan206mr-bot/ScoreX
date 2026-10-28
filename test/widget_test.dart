import 'package:flutter_test/flutter_test.dart';
import 'package:scorex/models/ball_event.dart';
import 'package:scorex/models/innings_summary.dart';
import 'package:scorex/models/win_estimate.dart';
import 'package:scorex/services/festival_calendar_service.dart';

void main() {
  group('ScoreX model smoke tests', () {
    test('festival event stores title and date', () {
      final date = DateTime(2026, 12, 25);
      final event = FestivalEvent(title: 'Christmas Day', date: date);
      expect(event.title, 'Christmas Day');
      expect(event.date, date);
    });

    test('ball event formats a boundary correctly', () {
      const ball = BallEvent(over: 0, ball: 4, runs: 4, batterRuns: 4);
      expect(ball.marker, '4');
    });

    test('innings summary calculates overs and run rate', () {
      const innings = InningsSummary(runs: 30, wickets: 1, legalBalls: 12);
      expect(innings.overs, '2.0');
      expect(innings.currentRunRate, 15.0);
    });

    test('win estimate rejects incomplete innings', () {
      const innings = InningsSummary(runs: 20, wickets: 1, legalBalls: 6);
      expect(WinEstimate.calculate(innings), isNull);
    });
  });
}
