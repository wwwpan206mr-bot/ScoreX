import '../models/ball_event.dart';
import '../models/innings_summary.dart';
import 'cricapi_parser.dart';

/// Summary parsing never invents a delivery from a change in innings totals.
class LiveSummary {
  const LiveSummary({this.innings, this.battingTeam, this.bowlingTeam, this.firstInningsRate});
  final InningsSummary? innings;
  final String? battingTeam;
  final String? bowlingTeam;
  final double? firstInningsRate;

  static int? legalBalls(Object? overs) {
    final text = overs?.toString() ?? '';
    final match = RegExp(r'^(\d+)(?:\.([0-5]))?$').firstMatch(text);
    if (match == null) return null;
    return int.parse(match[1]!) * 6 + int.parse(match[2] ?? '0');
  }

  factory LiveSummary.fromMatch(Map<String, dynamic> data) {
    final raw = data['score'];
    if (raw is! List || raw.isEmpty || raw.last is! Map) return const LiveSummary();
    final last = raw.last as Map;
    int? integer(Object? v) => v is int ? v : int.tryParse('$v');
    final runs = integer(last['r']);
    final wickets = integer(last['w']);
    final balls = legalBalls(last['o']);
    if (runs == null || runs < 0 || wickets == null || wickets < 0 || wickets > 10 || balls == null) {
      return const LiveSummary();
    }
    final format = data['matchType']?.toString().toLowerCase();
    final scheduled = integer(data['scheduledOvers']) ?? (format == 't20' ? 20 : format == 'odi' ? 50 : null);
    final status = (data['status'] ?? '').toString().toLowerCase();
    final altered = ['dls', 'd/l', 'duckworth', 'revised', 'reduced'].any(status.contains);
    final first = raw.first is Map ? raw.first as Map : null;
    final firstRuns = integer(first?['r']);
    final firstBalls = legalBalls(first?['o']);
    final explicitTarget = integer(data['target']);
    final target = raw.length == 2 && !altered && {20, 50}.contains(scheduled)
        ? explicitTarget ?? (firstRuns == null ? null : firstRuns + 1) : null;
    final teams = (data['teams'] is List ? data['teams'] as List : const [])
        .map((team) => team.toString()).toList();
    final battingTeam = cricApiInningsTeam(last['inning'], teams);
    final opponents = teams.where((team) => team != battingTeam).toList();
    return LiveSummary(
      innings: InningsSummary(runs: runs, wickets: wickets, legalBalls: balls,
        target: target, scheduledOvers: altered ? null : scheduled),
      battingTeam: battingTeam,
      bowlingTeam: battingTeam != null && opponents.length == 1 ? opponents.single : null,
      firstInningsRate: raw.length == 2 && firstRuns != null && firstBalls != null && firstBalls > 0
          ? firstRuns * 6 / firstBalls : null,
    );
  }
}

class DeliveryFeed {
  const DeliveryFeed({this.deliveries = const [], this.batting = const [], this.bowling = const [],
    this.updatedAt, this.source, this.stale = false, this.reason});
  final List<BallEvent> deliveries;
  final List<Map<String, String>> batting;
  final List<Map<String, String>> bowling;
  final DateTime? updatedAt;
  final String? source;
  final bool stale;
  final String? reason;

  factory DeliveryFeed.parse(Map<String, dynamic> envelope, String matchId, DateTime now) {
    final data = envelope['data'];
    if (data is! Map || data['matchId'] != matchId) {
      return const DeliveryFeed(reason: 'Ball-by-ball is not available for this match.');
    }
    final source = data['source']?.toString().trim();
    final updated = DateTime.tryParse('${data['updatedAt']}');
    final active = data['inningsId']?.toString();
    if (updated == null || !updated.isUtc || source == null || source.isEmpty ||
        active == null || active.isEmpty || updated.isAfter(now.toUtc().add(const Duration(seconds: 30)))) {
      return const DeliveryFeed(reason: 'Delivery source could not be verified.');
    }
    final stale = now.toUtc().difference(updated).inSeconds > 120;
    final events = <({int sequence, BallEvent event})>[];
    final seen = <String>{};
    final raw = data['deliveries'];
    if (raw is List) {
      for (final item in raw.whereType<Map>()) {
        if (item['inningsId']?.toString() != active || item['id'] is! String ||
            (item['id'] as String).isEmpty || item['sequence'] is! int ||
            item['sequence'] < 0 || item['over'] is! int || item['over'] < 0 ||
            item['ball'] is! int || item['ball'] < 1 || item['ball'] > 6 ||
            item['runs'] is! int || item['runs'] < 0 || item['batterRuns'] is! int ||
            item['extras'] is! int || item['batterRuns'] < 0 || item['extras'] < 0 ||
            item['runs'] != item['batterRuns'] + item['extras'] ||
            item['isWicket'] is! bool || item['isLegalDelivery'] is! bool) continue;
        if (!seen.add(item['id'] as String)) continue;
        events.add((sequence: item['sequence'] as int,
          event: BallEvent.fromJson(Map<String, dynamic>.from(item))));
      }
    }
    events.sort((a, b) => a.sequence.compareTo(b.sequence));
    List<Map<String, String>> players(Object? value, List<String> keys) {
      if (value is! List) return [];
      return value.whereType<Map>().where((row) => row['name'] is String &&
          (row['name'] as String).trim().isNotEmpty).map((row) => <String, String>{
        for (final key in keys) if (row[key] != null) key: row[key].toString(),
      }).toList();
    }
    return DeliveryFeed(
      deliveries: events.map((event) => event.event).toList(),
      batting: players(data['batting'], ['name', 'runs', 'balls', 'fours', 'sixes', 'strikeRate']),
      bowling: players(data['bowling'], ['name', 'overs', 'maidens', 'runs', 'wickets', 'economy']),
      updatedAt: updated, source: source, stale: stale,
      reason: events.isEmpty ? 'Ball-by-ball is not available for this match.' : null,
    );
  }
}
