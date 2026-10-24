/// A score summary with cricket-correct run-rate calculations.
class InningsSummary {
  const InningsSummary({
    required this.runs,
    required this.wickets,
    required this.legalBalls,
    this.target,
    this.scheduledOvers,
  });

  final int runs;
  final int wickets;
  final int legalBalls;
  final int? target;
  final int? scheduledOvers;

  String get overs => '${legalBalls ~/ 6}.${legalBalls % 6}';

  double? get currentRunRate =>
      legalBalls > 0 ? runs * 6 / legalBalls : null;

  int? get runsNeeded =>
      target == null ? null : (target! - runs).clamp(0, 999999999).toInt();

  int? get ballsRemaining {
    if (scheduledOvers == null) return null;
    return (scheduledOvers! * 6 - legalBalls).clamp(0, 999999999).toInt();
  }

  double? get requiredRunRate {
    final needed = runsNeeded;
    final remaining = ballsRemaining;
    if (needed == null || remaining == null || remaining == 0) return null;
    return needed * 6 / remaining;
  }

  factory InningsSummary.fromJson(Map<String, dynamic> json) {
    int number(Object? value) =>
        value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    int? optional(Object? value) => value == null ? null : number(value);
    return InningsSummary(
      runs: number(json['runs']),
      wickets: number(json['wickets']),
      legalBalls: number(json['legalBalls']),
      target: optional(json['target']),
      scheduledOvers: optional(json['scheduledOvers']),
    );
  }
}
