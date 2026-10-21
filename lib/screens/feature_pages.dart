import 'package:flutter/material.dart';

const Color _scoreXGold = Color(0xFFFFC857);

class ScoreXFeaturePage extends StatelessWidget {
  const ScoreXFeaturePage({super.key, required this.title});

  final String title;

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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.cloud_off_outlined, color: _scoreXGold, size: 34),
                  const SizedBox(height: 10),
                  const Text('Waiting for live API connection', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'This feature screen is prepared. Real scores, news, player statistics and match information will appear only after a verified data source is connected. No demo scores are displayed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: .75), height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('PLANNED CAPABILITIES', style: TextStyle(fontSize: 12, letterSpacing: 1.4, color: Colors.grey, fontWeight: FontWeight.bold)),
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
