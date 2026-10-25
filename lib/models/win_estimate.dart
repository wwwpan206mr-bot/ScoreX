import 'dart:math';
import 'innings_summary.dart';

/// Experimental Monte Carlo model, not a trained or calibrated AI model.
/// Assumes constant scoring and wicket rates for the remaining legal balls.
class WinEstimate {
  const WinEstimate(this.chasingPercent, this.defendingPercent, this.tiePercent);
  final int chasingPercent;
  final int defendingPercent;
  final int tiePercent;

  static WinEstimate? calculate(InningsSummary innings, {double? firstInningsRate}) {
    final needed = innings.runsNeeded;
    final remaining = innings.ballsRemaining;
    if (needed == null || remaining == null || remaining <= 0 || needed <= 0 ||
        innings.legalBalls < 12 || innings.wickets < 0 || innings.wickets >= 10 ||
        innings.runs < 0 || !{20, 50}.contains(innings.scheduledOvers)) return null;
    final prior = firstInningsRate != null && firstInningsRate.isFinite && firstInningsRate > 0
        ? firstInningsRate / 6 : innings.runs / innings.legalBalls;
    final rate = ((innings.runs + 18 * prior) / (innings.legalBalls + 18)).clamp(0.0, 4.0);
    final wicketRate = ((innings.wickets + 1) / (innings.legalBalls + 24)).clamp(.005, .3);
    final random = Random(1947);
    var wins = 0;
    var ties = 0;
    const trials = 2000;
    final threshold = exp(-rate / (1 - wicketRate));
    for (var trial = 0; trial < trials; trial++) {
      var runs = 0;
      var wickets = innings.wickets;
      for (var ball = 0; ball < remaining && wickets < 10 && runs < needed; ball++) {
        if (random.nextDouble() < wicketRate) {
          wickets++;
        } else {
          var product = random.nextDouble();
          var scored = 0;
          while (product > threshold) {
            scored++;
            product *= random.nextDouble();
          }
          runs += scored;
        }
      }
      if (runs >= needed) wins++;
      else if (runs == needed - 1) ties++;
    }
    final chasing = (100 * wins / trials).round();
    final tie = (100 * ties / trials).round().clamp(0, 100 - chasing).toInt();
    return WinEstimate(chasing, 100 - chasing - tie, tie);
  }
}
