import '../models/cricket_match.dart';

/// Provider flags sometimes arrive as JSON strings rather than booleans.
MatchStatus cricApiStatus(Map<String, dynamic> data) {
  bool yes(Object? value) => value == true || value == 1 || value == 'true';
  final status = (data['status'] ?? '').toString().toLowerCase();
  if (status.contains('abandoned') || status.contains('cancelled')) {
    return MatchStatus.abandoned;
  }
  if (yes(data['matchEnded']) || status.contains(' won by ') ||
      status.contains('match drawn') || status.contains('match tied') ||
      status.contains('no result')) return MatchStatus.completed;
  if (yes(data['matchStarted'])) return MatchStatus.live;
  // Missing flags are unknown, rather than evidence of a future fixture.
  if (data['matchStarted'] == false || data['matchStarted'] == 'false' ||
      data['matchStarted'] == 0) return MatchStatus.upcoming;
  return MatchStatus.unknown;
}

String? cricApiInningsTeam(Object? label, List<String> teams) {
  final name = (label ?? '').toString().trim().toLowerCase()
      .replaceFirst(RegExp(r'\s+innings?\s*\d*$', caseSensitive: false), '')
      .trim();
  // Do not guess a team from a composite label such as "Mexico,Argentina".
  for (final team in teams) {
    if (name == team.trim().toLowerCase()) return team;
  }
  return null;
}

List<Map<String, String>> cricApiScores(Map<String, dynamic> data) {
  final teams = (data['teams'] is List ? data['teams'] as List : const [])
      .map((team) => team.toString()).toList();
  final raw = data['score'];
  if (raw is! List) return [];
  return [
    for (var index = 0; index < raw.length; index++)
      if (raw[index] is Map)
        {
          'team': cricApiInningsTeam(raw[index]['inning'], teams) ?? 'Innings ${index + 1}',
          'score': raw[index]['r'] == null || raw[index]['w'] == null ? '—' :
            '${raw[index]['r']}/${raw[index]['w']}${raw[index]['o'] == null ? '' : ' (${raw[index]['o']} ov)'}',
        },
  ];
}

DateTime? cricApiStartTime(Map<String, dynamic> data) {
  final gmt = data['dateTimeGMT']?.toString();
  if (gmt != null && gmt.isNotEmpty) {
    // CricAPI's GMT timestamps omit the zone suffix.
    return DateTime.tryParse(gmt.endsWith('Z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(gmt) ? gmt : '${gmt}Z');
  }
  return DateTime.tryParse((data['date'] ?? '').toString());
}
