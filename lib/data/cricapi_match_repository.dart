import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cricket_match.dart';
import 'match_repository.dart';

class CricApiMatchRepository implements MatchRepository {
  const CricApiMatchRepository();
  static const baseUrl = String.fromEnvironment('API_BASE_URL');

  @override
  Future<List<CricketMatch>> getMatches({MatchStatus? status}) async {
    if (baseUrl.isEmpty) throw StateError('Worker URL is not configured');
    final response = await http.get(Uri.parse(baseUrl + '/matches')).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw StateError('Cricket service unavailable');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! List) throw const FormatException('Invalid response');
    return data.whereType<Map>().map((raw) {
      final m = Map<String, dynamic>.from(raw);
      final teams = m['teams'] is List ? m['teams'] as List : [];
      final scores = m['score'] is List ? m['score'] as List : [];
      String? score(int index) {
        if (scores.length <= index || scores[index] is! Map) return null;
        final s = scores[index] as Map;
        return s['r'].toString() + '/' + s['w'].toString() + ' (' + s['o'].toString() + ' ov)';
      }
      final matchStatus = m['matchEnded'] == true ? MatchStatus.completed
          : m['matchStarted'] == true ? MatchStatus.live : MatchStatus.upcoming;
      return CricketMatch(
        id: (m['id'] ?? '').toString(),
        title: (m['name'] ?? 'Cricket match').toString(),
        status: matchStatus,
        venue: m['venue']?.toString(),
        startTime: DateTime.tryParse((m['dateTimeGMT'] ?? m['date'] ?? '').toString()),
        teamA: teams.isNotEmpty ? teams[0].toString() : null,
        teamB: teams.length > 1 ? teams[1].toString() : null,
        teamAScore: score(0),
        teamBScore: score(1),
        result: m['status']?.toString(),
      );
    }).where((m) => status == null || m.status == status).toList();
  }
}
