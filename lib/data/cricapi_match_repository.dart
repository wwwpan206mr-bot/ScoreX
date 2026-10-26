import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cricket_match.dart';
import 'match_repository.dart';
import 'cricapi_parser.dart';

class CricApiMatchRepository implements MatchRepository {
  const CricApiMatchRepository();
  static final _client = http.Client();
  static const baseUrl = String.fromEnvironment('API_BASE_URL');

  @override
  Future<List<CricketMatch>> getMatches({MatchStatus? status}) async {
    if (baseUrl.isEmpty) throw StateError('Worker URL is not configured');
    final endpoint = Uri.parse('${baseUrl.replaceAll(RegExp(r"/+$"), "")}/matches');
    http.Response response;
    try {
      response = await _client.get(endpoint, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
    } catch (_) {
      // A short retry handles transient mobile DNS and connectivity failures.
      await Future<void>.delayed(const Duration(seconds: 2));
      try {
        response = await _client.get(endpoint, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 15));
      } catch (_) {
        throw StateError('Could not connect to live scores. Reconnecting automatically when online.');
      }
    }
    if (response.statusCode != 200) throw StateError('Cricket service unavailable (HTTP ${response.statusCode}). Please try again.');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'];
    if (data is! List) throw const FormatException('Invalid response');
    return data.whereType<Map>().map((raw) {
      final m = Map<String, dynamic>.from(raw);
      final teams = m['teams'] is List ? m['teams'] as List : [];
      final scores = cricApiScores(m);
      String? scoreForTeam(String? team) {
        for (final score in scores) {
          if (score['team'] == team) return score['score'];
        }
        return null;
      }
      String? imageForTeam(String? name) {
        final info = m['teamInfo'];
        if (info is! List) return null;
        for (final team in info.whereType<Map>()) {
          if (team['name'] == name) {
            final image = Uri.tryParse('${team['img']}');
            if (image != null && image.scheme == 'https' && image.host.isNotEmpty) return image.toString();
          }
        }
        return null;
      }
      final title = (m['name'] ?? 'Cricket match').toString();
      final titleParts = title.split(',');
      final series = m['series'] is String ? m['series'] as String
          : titleParts.length > 2 ? titleParts.skip(2).join(',').trim() : null;
      return CricketMatch(
        id: (m['id'] ?? '').toString(),
        title: title,
        series: series,
        status: cricApiStatus(m),
        venue: m['venue']?.toString(),
        startTime: cricApiStartTime(m),
        teamA: teams.isNotEmpty ? teams[0].toString() : null,
        teamB: teams.length > 1 ? teams[1].toString() : null,
        teamAImage: imageForTeam(teams.isNotEmpty ? teams[0].toString() : null),
        teamBImage: imageForTeam(teams.length > 1 ? teams[1].toString() : null),
        teamAScore: scoreForTeam(teams.isNotEmpty ? teams[0].toString() : null),
        teamBScore: scoreForTeam(teams.length > 1 ? teams[1].toString() : null),
        result: m['status']?.toString(),
      );
    }).where((m) => status == null || m.status == status).toList();
  }
}


