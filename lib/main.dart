import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/feature_pages.dart';
import 'screens/cricket_match_centre.dart';
import 'screens/fixtures_calendar.dart';

void main() => runApp(const ScoreXApp());

const Color scoreXGreen = Color(0xFF0B3D2E);
const Color scoreXGold = Color(0xFFFFC857);

class ScoreXApp extends StatefulWidget {
  const ScoreXApp({super.key});

  @override
  State<ScoreXApp> createState() => _ScoreXAppState();
}

class _ScoreXAppState extends State<ScoreXApp> {
  static const _themeKey = 'scorex_dark_mode';
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _darkMode = prefs.getBool(_themeKey) ?? true);
  }

  Future<void> _setTheme(bool value) async {
    setState(() => _darkMode = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _darkMode ? Brightness.dark : Brightness.light;
    return MaterialApp(
      title: 'ScoreX',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: scoreXGreen),
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: scoreXGreen,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: scoreXGreen, brightness: brightness),
        scaffoldBackgroundColor: const Color(0xFF071A14),
        appBarTheme: const AppBarTheme(
          backgroundColor: scoreXGreen,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF102820),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: ScoreHomePage(
        darkMode: _darkMode,
        onThemeChanged: _setTheme,
      ),
    );
  }
}

class ScoreHomePage extends StatefulWidget {
  const ScoreHomePage({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
  });

  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<ScoreHomePage> createState() => _ScoreHomePageState();
}

class _ScoreHomePageState extends State<ScoreHomePage> {
  static const _favoritesKey = 'scorex_favorite_match_ids';
  static const _notificationsKey = 'scorex_notifications_enabled';

  final TextEditingController _searchController = TextEditingController();
  Set<String> _favoriteIds = <String>{};
  bool _loadingPreferences = true;
  bool _notificationsEnabled = false;
  String _filter = 'All';
  int _navigationIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favoriteIds = (prefs.getStringList(_favoritesKey) ?? <String>{}.toList()).toSet();
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? false;
      _loadingPreferences = false;
    });
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ScoreXSettingsPage(
        darkMode: widget.darkMode,
        notificationsEnabled: _notificationsEnabled,
        onThemeChanged: widget.onThemeChanged,
        onNotificationsChanged: _setNotifications,
      ),
    ));
  }

  void _openMatchCentre() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const CricketMatchCentre(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isFavorites = _navigationIndex == 1;
    final visibleFavorites = _favoriteIds.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sports_cricket, color: scoreXGold, size: 29),
            SizedBox(width: 9),
            Text('ScoreX', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .4)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPreferences,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            _heroCard(context),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search teams, tournaments or matches',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
            if (_searchController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Search results will appear when verified cricket data is connected.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isFavorites ? 'Favorite matches' : 'Cricket matches',
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                ),
                if (_loadingPreferences)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isFavorites)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['All', 'Live', 'Upcoming', 'Results']
                    .map((item) => ChoiceChip(
                          label: Text(item),
                          selected: _filter == item,
                          onSelected: (_) => setState(() => _filter = item),
                          selectedColor: scoreXGold,
                          labelStyle: TextStyle(
                            color: _filter == item ? const Color(0xFF17231C) : null,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(
                            color: _filter == item ? scoreXGold : Theme.of(context).dividerColor,
                          ),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 14),
            if (isFavorites && !visibleFavorites)
              _emptyState(
                context,
                icon: Icons.star_border_rounded,
                title: 'No favorites yet',
                message: 'Tap the star on a match when live cricket data is connected. Your favorites will be saved on this device.',
              )
            else
              _emptyState(
                context,
                icon: Icons.cloud_off_rounded,
                title: 'Live cricket data is not connected yet',
                message: 'The ScoreX app interface is being prepared first. No sample or invented scores are shown. In the next phase, we will connect the approved cricket API through the secure backend.',
                showAction: true,
              ),
            const SizedBox(height: 18),
            _featureGrid(context),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'SCOREX  •  EVERY RUN. EVERY WICKET.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navigationIndex,
        onDestinationSelected: (value) => setState(() => _navigationIndex = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sports_cricket_outlined), selectedIcon: Icon(Icons.sports_cricket), label: 'Matches'),
          NavigationDestination(icon: Icon(Icons.star_border), selectedIcon: Icon(Icons.star), label: 'Favorites'),
        ],
      ),
    );
  }

  Widget _heroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(
          colors: [Color(0xFF15533E), Color(0xFF09271D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x66FFC857)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: scoreXGold, size: 17),
              SizedBox(width: 5),
              Text('CRICKET, AT A GLANCE', style: TextStyle(color: scoreXGold, fontSize: 11, letterSpacing: 1.7, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 12),
          Text('Every run.\nEvery wicket.', style: TextStyle(fontSize: 29, height: 1.12, fontWeight: FontWeight.w900, color: Colors.white)),
          SizedBox(height: 10),
          Text('Live scores, match centre and full scorecards — all in one place.', style: TextStyle(color: Color(0xFFD2E4D9), height: 1.4)),
        ],
      ),
    );
  }

  Widget _emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    bool showAction = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 25),
        child: Column(
          children: [
            Icon(icon, size: 42, color: scoreXGold),
            const SizedBox(height: 13),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: .75), height: 1.45)),
            if (showAction) ...[
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: _openMatchCentre,
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: const Text('Preview match centre'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.tune),
                label: const Text('App settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _featureGrid(BuildContext context) {
    final features = <({IconData icon, String title, String subtitle})>[
      (icon: Icons.sports_cricket, title: 'Live score', subtitle: 'Live match centre'),
      (icon: Icons.speaker_notes_outlined, title: 'Commentary', subtitle: 'Ball-by-ball'),
      (icon: Icons.table_chart_outlined, title: 'Scorecard', subtitle: 'Batting and bowling'),
      (icon: Icons.insights_outlined, title: 'Statistics', subtitle: 'Rates and partnerships'),
      (icon: Icons.event_available_outlined, title: 'Fixtures & Series', subtitle: 'Schedules and tournaments'),
      (icon: Icons.play_circle_outline, title: 'News & Videos', subtitle: 'Stories and highlights'),
      (icon: Icons.groups_2_outlined, title: 'Teams & Players', subtitle: 'Squads and profiles'),
      (icon: Icons.leaderboard_outlined, title: 'Rankings & Compare', subtitle: 'Rankings and stats'),
      (icon: Icons.picture_in_picture_alt_outlined, title: 'Mini score widget', subtitle: 'Compact score view'),
      (icon: Icons.notifications_active_outlined, title: 'Match alerts', subtitle: 'Personal notifications'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.28,
      ),
      itemBuilder: (context, index) {
        final feature = features[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => feature.title == 'Fixtures & Series'
                  ? const FixturesCalendarPage()
                  : ScoreXFeaturePage(title: feature.title),
            )),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(feature.icon, color: scoreXGold, size: 25),
                  const SizedBox(height: 9),
                  Text(feature.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(feature.subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ScoreXSettingsPage extends StatelessWidget {
  const ScoreXSettingsPage({
    super.key,
    required this.darkMode,
    required this.notificationsEnabled,
    required this.onThemeChanged,
    required this.onNotificationsChanged,
  });

  final bool darkMode;
  final bool notificationsEnabled;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('PREFERENCES', style: TextStyle(fontSize: 12, letterSpacing: 1.4, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              secondary: Icon(darkMode ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Dark theme'),
              subtitle: const Text('Choose your preferred appearance'),
              value: darkMode,
              onChanged: onThemeChanged,
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('Match notifications'),
              subtitle: const Text('Preference saved on this device; push alerts will be enabled after backend setup.'),
              value: notificationsEnabled,
              onChanged: onNotificationsChanged,
            ),
          ),
          const SizedBox(height: 20),
          const Text('ABOUT SCOREX', style: TextStyle(fontSize: 12, letterSpacing: 1.4, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.sports_cricket, color: scoreXGold),
              title: Text('ScoreX Cricket'),
              subtitle: Text('Version 1.0.0 • Android-first'),
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Live scores, ball-by-ball commentary and detailed scorecards depend on the cricket data provider and will be connected in the next development phase. ScoreX does not display invented match data.'),
            ),
          ),
        ],
      ),
    );
  }
}


class ScoreXMatchCentrePage extends StatelessWidget {
  const ScoreXMatchCentrePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Match Centre'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview', icon: Icon(Icons.scoreboard_outlined)),
              Tab(text: 'Commentary', icon: Icon(Icons.speaker_notes_outlined)),
              Tab(text: 'Scorecard', icon: Icon(Icons.table_chart_outlined)),
              Tab(text: 'Squads', icon: Icon(Icons.groups_outlined)),
              Tab(text: 'Stats', icon: Icon(Icons.insights_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MatchCentrePanel(
              icon: Icons.sports_cricket,
              title: 'Match overview',
              description: 'The selected teams, score, innings, venue, toss and match status will appear here when real match data is connected.',
            ),
            _MatchCentrePanel(
              icon: Icons.speaker_notes_outlined,
              title: 'Ball-by-ball commentary',
              description: 'Each delivery, over summary, boundary and wicket will be shown here only when the data provider supplies genuine commentary.',
            ),
            _MatchCentrePanel(
              icon: Icons.table_chart_outlined,
              title: 'Full scorecard',
              description: 'Batting figures, bowling figures, extras, innings totals and fall of wickets will appear here when a scorecard feed is available.',
            ),
            _MatchCentrePanel(
              icon: Icons.groups_outlined,
              title: 'Playing XI and squads',
              description: 'Team squads, playing XI, captain, wicketkeeper and player roles will appear here when supplied by the provider.',
            ),
            _MatchCentrePanel(
              icon: Icons.insights_outlined,
              title: 'Match statistics',
              description: 'Run rates, partnerships, recent balls and run progression will be calculated from verified match data when available.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCentrePanel extends StatelessWidget {
  const _MatchCentrePanel({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              children: [
                Icon(icon, size: 42, color: scoreXGold),
                const SizedBox(height: 14),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(description, textAlign: TextAlign.center, style: const TextStyle(height: 1.5, color: Colors.grey)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Waiting for live API connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, color: scoreXGold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'No fictional scores or player statistics are shown.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
