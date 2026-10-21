import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

void main() => runApp(const ScoreXApp());

class ScoreXApp extends StatelessWidget {
  const ScoreXApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF0B3D2E);
    const gold = Color(0xFFFFC857);
    return MaterialApp(
      title: 'ScoreX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF071A14),
        colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(backgroundColor: green, foregroundColor: Colors.white),
        cardTheme: CardThemeData(color: const Color(0xFF102820), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Color(0xFFE4EEE8))),
      ),
      home: const ScoreHomePage(),
    );
  }
}

class ScoreHomePage extends StatefulWidget {
  const ScoreHomePage({super.key});
  @override
  State<ScoreHomePage> createState() => _ScoreHomePageState();
}

class _ScoreHomePageState extends State<ScoreHomePage> {
  List<dynamic> matches = [];
  bool loading = false;
  String? error;
  String filter = 'All';

  @override
  void initState() {
    super.initState();
    if (apiBaseUrl.isNotEmpty) loadMatches();
  }

  Future<void> loadMatches() async {
    if (apiBaseUrl.isEmpty) {
      setState(() => error = 'API server not configured yet.');
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final base = Uri.parse(apiBaseUrl);
      final uri = base.replace(path: '${base.path.replaceFirst(RegExp(r'/$'), '')}/matches');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw Exception('Server returned HTTP ${response.statusCode}');
      final json = jsonDecode(response.body);
      if (json is Map && json['status'] == 'failure') {
        throw Exception(json['reason'] ?? json['message'] ?? 'Cricket API request failed');
      }
      if (json is Map && json['data'] is List) {
        matches = json['data'] as List;
      } else if (json is Map && json['matches'] is List) {
        matches = json['matches'] as List;
      } else if (json is List) {
        matches = json;
      } else {
        throw Exception(json is Map
            ? (json['message'] ?? json['reason'] ?? 'Unexpected API response format')
            : 'Unexpected API response format');
      }
    } catch (e) {
      error = 'Could not load scores. Check the API server setup and connection.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String valueOf(dynamic item, List<String> keys, [String fallback = '—']) {
    if (item is! Map) return fallback;
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;
      if (value is List && key == 'score') {
        final formatted = formatScores(value);
        if (formatted.isNotEmpty) return formatted;
      } else if (value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String formatScores(List<dynamic> scores) {
    return scores.map((entry) {
      if (entry is! Map) return entry.toString();
      final runs = entry['r'];
      final wickets = entry['w'];
      final overs = entry['o'];
      final inning = entry['inning'];
      final figures = [
        if (runs != null) runs.toString(),
        if (wickets != null) '($wickets wkts)',
        if (overs != null) 'in $overs overs',
      ].join(' ');
      if (figures.isEmpty) return inning?.toString() ?? '';
      return inning == null ? figures : '$inning: $figures';
    }).where((line) => line.isNotEmpty).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final visible = matches.where((m) {
      final status = valueOf(m, ['status', 'matchStatus'], '').toLowerCase();
      if (filter == 'Live') return status.contains('live') || status.contains('in progress');
      if (filter == 'Upcoming') return status.contains('upcoming') || status.contains('not started');
      if (filter == 'Finished') return status.contains('won') || status.contains('complete') || status.contains('result');
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.sports_cricket, color: Color(0xFFFFC857), size: 29),
          SizedBox(width: 10),
          Text('ScoreX', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ]),
        actions: [IconButton(onPressed: loadMatches, icon: const Icon(Icons.refresh), tooltip: 'Refresh scores')],
      ),
      body: RefreshIndicator(
        onRefresh: loadMatches,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(colors: [Color(0xFF15533E), Color(0xFF0B2B20)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: const Color(0x55FFC857)),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CRICKET, AT A GLANCE', style: TextStyle(color: Color(0xFFFFC857), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('Every run. Every wicket.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(height: 6),
                Text('Follow matches and scores in one place.', style: TextStyle(color: Color(0xFFD2E4D9))),
              ]),
            ),
            const SizedBox(height: 22),
            Row(children: [
              const Expanded(child: Text('Matches', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
              if (loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: ['All', 'Live', 'Upcoming', 'Finished'].map((item) =>
              ChoiceChip(label: Text(item), selected: filter == item, onSelected: (_) => setState(() => filter = item),
                selectedColor: const Color(0xFFFFC857), labelStyle: TextStyle(color: filter == item ? const Color(0xFF17231C) : Colors.white, fontWeight: FontWeight.w600),
                side: BorderSide(color: filter == item ? const Color(0xFFFFC857) : const Color(0xFF315346)),
              )).toList()),
            const SizedBox(height: 12),
            if (apiBaseUrl.isEmpty)
              _messageCard(Icons.cloud_off, 'Live API not connected', 'The app screen is ready. A secure API server URL must be added before live scores can load.')
            else if (error != null)
              _messageCard(Icons.wifi_off, 'Scores unavailable', error!)
            else if (!loading && visible.isEmpty)
              _messageCard(Icons.sports_cricket, 'No matches found', 'Try refreshing later. The free API may have no current matches.')
            else
              ...visible.map((m) => _matchCard(m)),
            const SizedBox(height: 24),
            const Center(child: Text('SCOREX  •  CRICKET LIVE SCORES', style: TextStyle(color: Color(0xFF78988A), fontSize: 10, letterSpacing: 1.4))),
          ],
        ),
      ),
    );
  }

  Widget _messageCard(IconData icon, String title, String message) => Card(
    child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
      Icon(icon, color: const Color(0xFFFFC857), size: 34),
      const SizedBox(height: 10),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 6),
      Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFADC4B8))),
    ])),
  );

  Widget _matchCard(dynamic match) {
    final teams = match is Map ? match['teams'] : null;
    final team1 = teams is List && teams.isNotEmpty ? teams[0].toString() : valueOf(match, ['team1', 'teamA', 'name']);
    final team2 = teams is List && teams.length > 1 ? teams[1].toString() : valueOf(match, ['team2', 'teamB', 'name2']);
    final status = valueOf(match, ['status', 'matchStatus'], 'Match status unavailable');
    final score = valueOf(match, ['score', 'scores', 'scoreDetails'], '');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.circle, color: Color(0xFFFFC857), size: 8),
          const SizedBox(width: 7),
          Expanded(child: Text(valueOf(match, ['name', 'series', 'matchType'], 'Cricket Match'), style: const TextStyle(color: Color(0xFFB7CFC2), fontSize: 12))),
        ]),
        const SizedBox(height: 14),
        Text(team1, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(team2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if (score.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(score, style: const TextStyle(color: Color(0xFFFFC857), fontWeight: FontWeight.bold)),
        ],
        const Divider(height: 22, color: Color(0xFF29483B)),
        Text(status, style: const TextStyle(color: Color(0xFFADC4B8), fontSize: 12)),
      ])),
    );
  }
}
