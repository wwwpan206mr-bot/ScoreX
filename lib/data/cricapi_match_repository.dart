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
    final endpoint = Uri.parse('${baseUrl.replaceAll(RegExp(r"/+$"), "")}/matches');
    http.Response response;
    try {
      response = await http.get(endpoint).timeout(const Duration(seconds: 15));
    } catch (_) {
      // A short retry handles transient mobile DNS and connectivity failures.
      await Future<void>.delayed(const Duration(seconds: 2));
      try {
        response = await http.get(endpoint).timeout(const Duration(seconds: 15));
      } catch (_) {
        throw StateError('Could not connect to live scores. Check your internet connection and try refreshing.');
      }
    }
    if (response.statusCode != 200) throw StateError('Cricket service unavailable (HTTP ${response.statusCode}). Please try again.');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! List) throw const FormatException('Invalid response');
    return data.whereType<Map>().map((raw) {
      final m = Map<String, dynamic>.from(raw);
      final teams = m['teams'] is List ? m['teams'] as List : [];
      final scores = m['score'] is List ? m['score'] as List : [];
      String? scoreForTeam(String? team) {
        if (team == null) return null;
        for (final rawScore in scores) {
          if (rawScore is! Map) continue;
          final inning = (rawScore['inning'] ?? '').toString().toLowerCase();
          final teamName = team.toLowerCase();
          if (inning != teamName && !inning.startsWith('$teamName inning') &&
              !inning.startsWith('$teamName innings')) continue;
          final runs = rawScore['r'];
          final wickets = rawScore['w'];
          final overs = rawScore['o'];
          if (runs == null || wickets == null) return null;
          return '$runs/$wickets' + (overs == null ? '' : ' ($overs ov)');
        }
        return null;
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
        teamAScore: scoreForTeam(teams.isNotEmpty ? teams[0].toString() : null),
        teamBScore: scoreForTeam(teams.length > 1 ? teams[1].toString() : null),
        result: m['status']?.toString(),
      );
    }).where((m) => status == null || m.status == status).toList();
  }
}
