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

    test('ball event and innings models can be constructed', () {
      expect(BallEvent, isNotNull);
      expect(InningsSummary, isNotNull);
      expect(WinEstimate, isNotNull);
    });
  });
}
