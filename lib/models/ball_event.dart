/// A provider-neutral delivery record. Never synthesise match events.
class BallEvent {
  const BallEvent({
    required this.over,
    required this.ball,
    required this.runs,
    this.batterRuns = 0,
    this.extras = 0,
    this.isWicket = false,
    this.isLegalDelivery = true,
    this.commentary,
  });

  final int over;
  final int ball;
  final int runs;
  final int batterRuns;
  final int extras;
  final bool isWicket;
  final bool isLegalDelivery;
  final String? commentary;

  String get marker {
    if (isWicket) return 'W';
    if (batterRuns == 4) return '4';
    if (batterRuns == 6) return '6';
    return runs.toString();
  }

  factory BallEvent.fromJson(Map<String, dynamic> json) {
    int number(Object? value) =>
        value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    bool boolean(Object? value, {bool fallback = false}) =>
        value is bool ? value : fallback;
    return BallEvent(
      over: number(json['over']),
      ball: number(json['ball']),
      runs: number(json['runs']),
      batterRuns: number(json['batterRuns']),
      extras: number(json['extras']),
      isWicket: boolean(json['isWicket']),
      isLegalDelivery: boolean(json['isLegalDelivery'], fallback: true),
      commentary: json['commentary']?.toString(),
    );
  }
}
