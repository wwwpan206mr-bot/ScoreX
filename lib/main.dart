import 'dart:async';
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
    return MaterialApp(
      title: 'ScoreX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF071A14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: green,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF102820),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
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
  String searchQuery = '';
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    if (apiBaseUrl.isNotEmpty) {
      loadMatches();
    }
  }

  Future<void> loadMatches() async {
    if (apiBaseUrl.isEmpty) {
      if (mounted) setState(() => error = 'API_BASE_URL is not configured.');
      return;
    }
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final base = Uri.parse(apiBaseUrl);
      final cleanPath = base.path.replaceFirst(RegExp(r'/$'), '');
      final uri = base.replace(path: '$cleanPath/matches');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final dynamic json;
      try {
        json = jsonDecode(response.body);
      } on FormatException {
        throw Exception('The cricket server returned invalid JSON.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = json is Map
            ? (json['message'] ?? json['reason'] ?? 'HTTP ${response.statusCode}')
            : 'HTTP ${response.statusCode}';
        throw Exception(message);
      }
      if (json is Map && (json['status'] == 'failure' || json['success'] == false)) {
        throw Exception(json['reason'] ?? json['message'] ?? 'Cricket API request failed');
      }
      if (json is Map && json['data'] is List) {
        matches = List<dynamic>.from(json['data'] as List);
      } else if (json is Map && json['matches'] is List) {
        matches = List<dynamic>.from(json['matches'] as List);
      } else if (json is List) {
        matches = List<dynamic>.from(json);
      } else {
        throw Exception(json is Map
            ? (json['message'] ?? json['reason'] ?? 'Unexpected API response format')
            : 'Unexpected API response format');
      }
      lastUpdated = DateTime.now();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String valueOf(dynamic item, List<String> keys, [String fallback = '—']) {
    if (item is! Map) return fallback;
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;
      if (value is List && (key == 'score' || key == 'scores')) {
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

  List<dynamic> get visibleMatches {
    return matches.where((match) {
      final status = valueOf(match, ['status', 'matchStatus'], '').toLowerCase();
      final name = valueOf(match, ['name', 'series', 'matchType'], '').toLowerCase();
      final teams = match is Map && match['teams'] is List
          ? (match['teams'] as List).join(' ').toLowerCase()
          : '${valueOf(match, ['team1', 'teamA'], '')} ${valueOf(match, ['team2', 'teamB'], '')}'.toLowerCase();
      final queryMatches = searchQuery.trim().isEmpty ||
          '$name $teams $status'.contains(searchQuery.trim().toLowerCase());
      final filterMatches = switch (filter) {
        'Live' => status.contains('live') || status.contains('in progress'),
        'Upcoming' => status.contains('upcoming') || status.contains('not started') || status.contains('fixture'),
        'Results' => status.contains('won') || status.contains('complete') || status.contains('result') || status.contains('draw'),
        _ => true,
      };
      return queryMatches && filterMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.sports_cricket, color: Color(0xFFFFC857), size: 29),
          SizedBox(width: 10),
          Text('ScoreX', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ]),
        actions: [
          IconButton(
            onPressed: loading ? null : loadMatches,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh scores',
          ),
        ],
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF15533E), Color(0xFF0B2B20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0x55FFC857)),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('LIVE CRICKET • SCOREX', style: TextStyle(color: Color(0xFFFFC857), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('Every run. Every wicket.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                SizedBox(height: 6),
                Text('Follow live scores, match status and results.', style: TextStyle(color: Color(0xFFD2E4D9))),
              ]),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search teams or matches',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF102820),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => setState(() => searchQuery = ''),
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(child: Text('Matches', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
              if (loading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
            if (lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text('Last updated: ${TimeOfDay.fromDateTime(lastUpdated!).format(context)}', style: const TextStyle(color: Color(0xFF91AB9D), fontSize: 11)),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['All', 'Live', 'Upcoming', 'Results'].map((item) => ChoiceChip(
                label: Text(item),
                selected: filter == item,
                onSelected: (_) => setState(() => filter = item),
                selectedColor: const Color(0xFFFFC857),
                labelStyle: TextStyle(
                  color: filter == item ? const Color(0xFF17231C) : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(color: filter == item ? const Color(0xFFFFC857) : const Color(0xFF315346)),
              )).toList(),
            ),
            const SizedBox(height: 12),
            if (apiBaseUrl.isEmpty)
              _messageCard(Icons.cloud_off, 'Live API not connected', 'The ScoreX screen is ready. Configure the secure API server URL to load real cricket scores.')
            else if (error != null)
              _messageCard(Icons.wifi_off, 'Scores unavailable', error!, retry: true)
            else if (!loading && visibleMatches.isEmpty)
              _messageCard(Icons.sports_cricket, 'No matches found', matches.isEmpty ? 'The API returned no matches. Try again later.' : 'No matches match your search or selected filter.')
            else
              ...visibleMatches.map(_matchCard),
            const SizedBox(height: 24),
            const Center(child: Text('SCOREX • CRICKET LIVE SCORES', style: TextStyle(color: Color(0xFF78988A), fontSize: 10, letterSpacing: 1.4))),
          ],
        ),
      ),
    );
  }

  Widget _messageCard(IconData icon, String title, String message, {bool retry = false}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        Icon(icon, color: const Color(0xFFFFC857), size: 34),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFADC4B8))),
        if (retry) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: loading ? null : loadMatches, icon: const Icon(Icons.refresh), label: const Text('Try again')),
        ],
      ]),
    ),
  );

  Widget _matchCard(dynamic match) {
    final teams = match is Map ? match['teams'] : null;
    final team1 = teams is List && teams.isNotEmpty ? teams[0].toString() : valueOf(match, ['team1', 'teamA', 'name']);
    final team2 = teams is List && teams.length > 1 ? teams[1].toString() : valueOf(match, ['team2', 'teamB', 'name2']);
    final status = valueOf(match, ['status', 'matchStatus'], 'Match status unavailable');
    final score = valueOf(match, ['score', 'scores', 'scoreDetails'], '');
    final matchName = valueOf(match, ['name', 'series', 'matchType'], 'Cricket Match');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MatchDetailsPage(
            match: match,
            team1: team1,
            team2: team2,
            matchName: matchName,
            status: status,
            score: score,
            valueOf: valueOf,
          ),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.circle, color: Color(0xFFFFC857), size: 8),
              const SizedBox(width: 7),
              Expanded(child: Text(matchName, style: const TextStyle(color: Color(0xFFB7CFC2), fontSize: 12))),
              const Icon(Icons.chevron_right, color: Color(0xFF78988A)),
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
          ]),
        ),
      ),
    );
  }
}

class MatchDetailsPage extends StatelessWidget {
  const MatchDetailsPage({
    super.key,
    required this.match,
    required this.team1,
    required this.team2,
    required this.matchName,
    required this.status,
    required this.score,
    required this.valueOf,
  });

  final dynamic match;
  final String team1;
  final String team2;
  final String matchName;
  final String status;
  final String score;
  final String Function(dynamic, List<String>, [String]) valueOf;

  @override
  Widget build(BuildContext context) {
    final venue = valueOf(match, ['venue', 'ground'], 'Not provided by data provider');
    final date = valueOf(match, ['dateTimeGMT', 'date', 'dateTime'], 'Not provided by data provider');
    final matchType = valueOf(match, ['matchType', 'type'], 'Not provided by data provider');
    final toss = valueOf(match, ['tossWinner', 'toss'], 'Not provided by data provider');
    return Scaffold(
      appBar: AppBar(title: const Text('Match Centre')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(matchName, style: const TextStyle(color: Color(0xFFFFC857), fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(team1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(team2, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (score.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(score, style: const TextStyle(color: Color(0xFFFFC857), fontSize: 16, fontWeight: FontWeight.bold)),
                ],
                const Divider(height: 26),
                Text(status, style: const TextStyle(color: Color(0xFFB7CFC2))),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          _infoCard('Match information', [
            _infoRow('Format', matchType),
            _infoRow('Venue', venue),
            _infoRow('Start time', date),
            _infoRow('Toss', toss),
          ]),
          const SizedBox(height: 12),
          _infoCard('Ball-by-ball commentary', const [
            Text('Commentary is not included in the current matches feed. It will appear here only after a provider endpoint that supplies real ball-by-ball data is connected.'),
          ]),
          const SizedBox(height: 12),
          _infoCard('Full scorecard', const [
            Text('Detailed batting and bowling figures are not included in the current matches feed. No statistics are fabricated. A scorecard endpoint is required to show this section.'),
          ]),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ]),
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 95, child: Text(label, style: const TextStyle(color: Color(0xFF91AB9D)))),
      Expanded(child: Text(value)),
    ]),
  );
}
