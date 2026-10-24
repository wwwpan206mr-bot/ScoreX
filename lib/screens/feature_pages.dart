import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/cricapi_match_repository.dart';
import '../models/cricket_match.dart';
import 'fixtures_calendar.dart';

const Color _scoreXGold = Color(0xFFFFC857);

class ScoreXFeaturePage extends StatefulWidget {
  const ScoreXFeaturePage({super.key, required this.title});

  final String title;

  @override
  State<ScoreXFeaturePage> createState() => _ScoreXFeaturePageState();
}

class _ScoreXFeaturePageState extends State<ScoreXFeaturePage> {
  List<CricketMatch> matches = [];
  String? error;
  bool loading = true;
  bool alerts = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => alerts = prefs.getBool('scorex_notifications_enabled') ?? false);
    try {
      final result = await const CricApiMatchRepository().getMatches();
      if (!mounted) return;
      setState(() { matches = result; loading = false; error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('scorex_notifications_enabled', value);
    if (mounted) setState(() => alerts = value);
  }

  static const Map<String, ({IconData icon, String subtitle, List<String> capabilities})> _content = {
    'Live score': (
      icon: Icons.sports_cricket,
      subtitle: 'Live match centre',
      capabilities: ['Live score and innings', 'Overs, CRR and RRR', 'Last six balls and partnership', 'Match status and toss']
    ),
    'Commentary': (
      icon: Icons.speaker_notes_outlined,
      subtitle: 'Ball-by-ball match timeline',
      capabilities: ['Ball-by-ball commentary', 'Over summaries', 'Wickets, boundaries and milestones', 'Commentary timeline']
    ),
    'Scorecard': (
      icon: Icons.table_chart_outlined,
      subtitle: 'Batting and bowling breakdown',
      capabilities: ['Batting figures and fall of wickets', 'Bowling figures and economy', 'Extras and innings totals', 'Partnership details']
    ),
    'Statistics': (
      icon: Icons.insights_outlined,
      subtitle: 'Match and player insights',
      capabilities: ['Run rate and required rate', 'Partnerships and run charts', 'Player performance', 'Win probability when a provider supports it']
    ),
    'Fixtures & Series': (
      icon: Icons.event_available_outlined,
      subtitle: 'Fixtures, schedules and tournaments',
      capabilities: ['Upcoming international matches', 'Domestic and franchise series', 'Series fixtures and results', 'Venue and local start time']
    ),
    'News & Videos': (
      icon: Icons.play_circle_outline,
      subtitle: 'Cricket news and video highlights',
      capabilities: ['Latest cricket headlines', 'Match previews and reports', 'Highlights and video links', 'Publisher/source attribution']
    ),
    'Teams & Players': (
      icon: Icons.groups_2_outlined,
      subtitle: 'Team and player profiles',
      capabilities: ['Team squads and playing XI', 'Player profiles and career stats', 'Team form and head-to-head', 'Role and player information']
    ),
    'Rankings & Compare': (
      icon: Icons.leaderboard_outlined,
      subtitle: 'Rankings and player comparison',
      capabilities: ['Team and player rankings', 'Compare two players', 'Batting and bowling statistics', 'Ranking date and source']
    ),
    'Mini score widget': (
      icon: Icons.picture_in_picture_alt_outlined,
      subtitle: 'Compact score view',
      capabilities: ['In-app compact score card', 'Choose a followed match', 'Refresh from verified match data', 'System-wide floating overlay requires a later native Android permission and implementation']
    ),
    'Match alerts': (
      icon: Icons.notifications_active_outlined,
      subtitle: 'Personal match notifications',
      capabilities: ['Wicket and innings alerts', 'Match start and result alerts', 'Favorite-team notifications', 'Push delivery requires backend and notification provider setup']
    ),
  };

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final content = _content[title] ?? (
      icon: Icons.sports_cricket,
      subtitle: 'Cricket information',
      capabilities: <String>['Match details', 'Player and team information', 'Statistics from a verified provider']
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFF15533E), Color(0xFF09271D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0x66FFC857)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(content.icon, color: _scoreXGold, size: 36),
                const SizedBox(height: 14),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(content.subtitle, style: const TextStyle(color: Color(0xFFD2E4D9))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (title == 'Match alerts') ...[
            SwitchListTile(
              title: const Text('Match alert preference'),
              subtitle: const Text('Saved on this device. Push delivery requires notification backend setup.'),
              value: alerts,
              onChanged: _toggle,
            ),
          ] else if (title == 'Fixtures & Series') ...[
            FilledButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const FixturesCalendarPage())),
              icon: const Icon(Icons.calendar_month),
              label: const Text('Open fixture calendar'),
            ),
          ] else if (title == 'Teams & Players') ...[
            if (loading) const Center(child: CircularProgressIndicator())
            else if (error != null) ListTile(title: const Text('Teams unavailable'), subtitle: Text(error!), trailing: IconButton(onPressed: _load, icon: const Icon(Icons.refresh)))
            else ...{
              for (final m in matches) ...[if (m.teamA != null) m.teamA!, if (m.teamB != null) m.teamB!]
            }.map((team) => Card(child: ListTile(leading: const Icon(Icons.groups, color: _scoreXGold), title: Text(team), subtitle: const Text('Team seen in verified match feed')))),
            const Text('Player profiles and squads require an additional licensed data endpoint.'),
          ] else if (title == 'News & Videos') ...[
            const Card(child: ListTile(
              leading: Icon(Icons.newspaper, color: _scoreXGold),
              title: Text('News and highlights source not connected'),
              subtitle: Text('Verified publisher feeds and licensed video links are required. No fabricated headlines or videos are shown.'),
            )),
          ] else ...[
            if (loading) const Center(child: CircularProgressIndicator())
            else if (error != null) ListTile(title: const Text('Match data unavailable'), subtitle: Text(error!), trailing: IconButton(onPressed: _load, icon: const Icon(Icons.refresh)))
            else ...matches.take(15).map((m) => Card(child: ListTile(
              title: Text(m.title),
              subtitle: Text('${m.teamA ?? ''} ${m.teamAScore ?? ''}  •  ${m.teamB ?? ''} ${m.teamBScore ?? ''}\n${m.result ?? ''}'),
              isThreeLine: true,
            ))),
            const Text('Advanced scorecards, commentary and analytics require supported provider endpoints.'),
          ],
          const SizedBox(height: 18),
          const Text('ADDITIONAL CAPABILITIES', style: TextStyle(fontSize: 12, letterSpacing: 1.4, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...content.capabilities.map((item) => Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline, color: _scoreXGold),
              title: Text(item),
            ),
          )),
          const SizedBox(height: 12),
          const Text(
            'Data-dependent features remain inactive until the API phase. Push notifications and a system-wide floating widget also require platform/backend setup.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
