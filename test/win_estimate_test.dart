import 'package:flutter_test/flutter_test.dart';
import 'package:scorex/models/innings_summary.dart';
import 'package:scorex/models/win_estimate.dart';

void main() {
  InningsSummary chase({int target = 170, int wickets = 4}) => InningsSummary(
    runs: 136, wickets: wickets, legalBalls: 96, target: target, scheduledOvers: 20);

  test('estimates supported chases deterministically and accounts for ties', () {
    final a = WinEstimate.calculate(chase())!;
    final b = WinEstimate.calculate(chase())!;
    expect(a.chasingPercent + a.defendingPercent + a.tiePercent, 100);
    expect(a.chasingPercent, inInclusiveRange(0, 100));
    expect(a.chasingPercent, b.chasingPercent);
  });

  test('harder required totals and fewer wickets reduce the chase estimate', () {
    final easy = WinEstimate.calculate(chase(target: 150))!;
    final hard = WinEstimate.calculate(chase(target: 200))!;
    final lastWicket = WinEstimate.calculate(chase(wickets: 9))!;
    expect(easy.chasingPercent, greaterThan(hard.chasingPercent));
    expect(lastWicket.chasingPercent, lessThan(WinEstimate.calculate(chase())!.chasingPercent));
  });

  test('does not produce percentages for missing targets, tests, or finished innings', () {
    expect(WinEstimate.calculate(const InningsSummary(runs: 53, wickets: 4, legalBalls: 54)), isNull);
    expect(WinEstimate.calculate(const InningsSummary(runs: 136, wickets: 10, legalBalls: 96,
      target: 170, scheduledOvers: 20)), isNull);
    expect(WinEstimate.calculate(const InningsSummary(runs: 136, wickets: 4, legalBalls: 96,
      target: 170)), isNull);
  });
}
