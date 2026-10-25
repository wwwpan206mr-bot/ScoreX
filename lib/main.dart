import 'dart:async';
import 'screens/account_page.dart';
import 'services/app_update_service.dart';
import 'data/cricapi_match_repository.dart';
import 'data/match_repository.dart';
import 'models/cricket_match.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/feature_pages.dart';
import 'screens/live_match_centre.dart';
import 'screens/fixtures_calendar.dart';
import 'screens/advanced_analytics.dart';
import 'screens/legal_pages.dart';
import 'widgets/premium_match_card.dart';

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
        pageTransitionsTheme: PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
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
        pageTransitionsTheme: PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
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
      home: ScoreXAuthGate(child: ScoreHomePage(
        darkMode: _darkMode,
        onThemeChanged: _setTheme,
      )),
    );
  }
}

class ScoreHomePage extends StatefulWidget {
  const ScoreHomePage({
    super.key,
    required this.darkMode,
    required this.onThemeChanged,
    this.matchRepository = const CricApiMatchRepository(),
  });

  final bool darkMode;
  final ValueChanged<bool> onThemeChanged;
  final MatchRepository matchRepository;

  @override
  State<ScoreHomePage> createState() => _ScoreHomePageState();
}

class _ScoreHomePageState extends State<ScoreHomePage> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _fetchingMatches = false;
  DateTime? _lastMatchRefresh;
  static const _favoritesKey = 'scorex_favorite_match_ids';
  static const _notificationsKey = 'scorex_notifications_enabled';

  final TextEditingController _searchController = TextEditingController();
  Set<String> _favoriteIds = <String>{};
  bool _loadingPreferences = true;
  bool _notificationsEnabled = false;
  String _filter = 'All';
  List<CricketMatch> _matches = [];
  String? _matchError;
  bool _loadingMatches = true;
  int _navigationIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
    _loadMatches();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) _loadMatches();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) AppUpdateService.check(context, silent: true); });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadMatches();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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

  Future<void> _loadMatches() async {
    if (_fetchingMatches) return;
    _fetchingMatches = true;
    try {
      final matches = await widget.matchRepository.getMatches();
      if (!mounted) return;
      setState(() { _matches = matches; _matchError = null; _loadingMatches = false; _lastMatchRefresh = DateTime.now(); });
    } catch (error) {
      if (!mounted) return;
      setState(() { _matchError = error.toString(); _loadingMatches = false; });
    } finally {
      _fetchingMatches = false;
    }
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

  void _openMatchCentre(String matchId) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LiveMatchCentre(matchId: matchId),
    ));
  }

  List<CricketMatch> get _visibleMatches {
    final query = _searchController.text.trim().toLowerCase();
    final matches = _matches.where((m) {
      if (_filter == 'Live' && m.status != MatchStatus.live) return false;
      if (_filter == 'Upcoming' && m.status != MatchStatus.upcoming) return false;
      if (_filter == 'Results' && m.status != MatchStatus.completed && m.status != MatchStatus.abandoned) return false;
      if (_filter == 'Following' && !_favoriteIds.contains(m.id)) return false;
      return query.isEmpty || [m.title, m.teamA ?? '', m.teamB ?? '', m.series ?? '']
        .any((value) => value.toLowerCase().contains(query));
    }).toList();
    int rank(CricketMatch m) => m.status == MatchStatus.live ? 0 : m.status == MatchStatus.upcoming ? 1 : 2;
    matches.sort((a, b) {
      final status = rank(a).compareTo(rank(b));
      if (status != 0) return status;
      return a.status == MatchStatus.upcoming
          ? (a.startTime ?? DateTime(2100)).compareTo(b.startTime ?? DateTime(2100))
          : (b.startTime ?? DateTime(2000)).compareTo(a.startTime ?? DateTime(2000));
    });
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.asset('assets/branding/scorex_logo.png', width: 38, height: 38, fit: BoxFit.cover)),
            SizedBox(width: 9),
            Expanded(child: Text('ScoreX', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .4))),
          ],
        ),
        actions: [
          IconButton(tooltip: 'My profile', icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ScoreXAccountPage()))),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _navigationIndex == 1 || _navigationIndex == 3 || _navigationIndex == 4 || _navigationIndex == 5
          ? _navigationSection(context)
          : RefreshIndicator(
        onRefresh: () async { await _loadPreferences(); await _loadMatches(); },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            if (_navigationIndex == 0) _heroCard(context),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search cricket matches…',
                prefixIcon: const Icon(Icons.search_rounded, color: scoreXGold),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _navigationIndex == 2 ? (_filter == 'All' ? 'All matches' : '$_filter matches') : 'Match spotlight',
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
            if (_lastMatchRefresh != null)
              Text('Last checked: ${TimeOfDay.fromDateTime(_lastMatchRefresh!).format(context)} • Auto refresh every 30s', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
              spacing: 8,
              children: ['All', 'Live', 'Upcoming', 'Results', 'Following']
                  .map((item) => ChoiceChip(
                        label: Text(item),
                        selected: _filter == item,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            ),
            const SizedBox(height: 14),
            if (_loadingMatches)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_matchError != null)
              _emptyState(context, icon: Icons.cloud_off_outlined, title: 'Live scores unavailable', message: _matchError!)
            else ...[
              for (final match in _visibleMatches)
                PremiumMatchCard(
                  match: match,
                  favorite: _favoriteIds.contains(match.id),
                  onFavorite: () async {
                    setState(() {
                      if (!_favoriteIds.add(match.id)) _favoriteIds.remove(match.id);
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setStringList(_favoritesKey, _favoriteIds.toList());
                  },
                  onTap: () => _openMatchCentre(match.id),
                ),
              if (_visibleMatches.isEmpty)
                _filteredEmptyState(context),
            ],
            const SizedBox(height: 18),
            if (_navigationIndex == 0) _featureGrid(context),
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF091E19),
          border: Border(top: BorderSide(color: Color(0x44FFC857), width: 1)),
          boxShadow: [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: const Color(0xFF091E19),
              indicatorColor: const Color(0x44FFC857),
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) =>
                TextStyle(
                  fontSize: 10,
                  fontWeight: states.contains(WidgetState.selected) ? FontWeight.w900 : FontWeight.w600,
                  color: states.contains(WidgetState.selected) ? scoreXGold : const Color(0xFFBCE7D7),
                ),
              ),
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) =>
                IconThemeData(
                  size: states.contains(WidgetState.selected) ? 28 : 25,
                  color: states.contains(WidgetState.selected) ? scoreXGold : const Color(0xFF63E6BE),
                ),
              ),
            ),
            child: NavigationBar(
              height: 74,
              elevation: 0,
              backgroundColor: const Color(0xFF091E19),
              animationDuration: const Duration(milliseconds: 330),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              selectedIndex: _navigationIndex,
              onDestinationSelected: (value) => setState(() => _navigationIndex = value),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events_rounded), label: 'Series'),
                NavigationDestination(icon: Icon(Icons.sports_cricket_outlined), selectedIcon: Icon(Icons.sports_cricket_rounded), label: 'Matches'),
                NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Social'),
                NavigationDestination(icon: Icon(Icons.ondemand_video_outlined), selectedIcon: Icon(Icons.ondemand_video_rounded), label: 'Videos'),
                NavigationDestination(icon: Icon(Icons.more_horiz_rounded), selectedIcon: Icon(Icons.apps_rounded), label: 'More'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filteredEmptyState(BuildContext context) {
    final searching = _searchController.text.trim().isNotEmpty;
    final title = searching ? 'No search results'
        : _filter == 'Live' ? 'No live matches in this feed'
        : _filter == 'Upcoming' ? 'No upcoming fixtures in this feed'
        : _filter == 'Results' ? 'No results in this feed'
        : _filter == 'Following' ? 'No followed matches available'
        : 'No matches returned by the provider';
    final message = searching ? 'Try a team name or clear your search.'
        : _filter == 'Following' ? 'Star matches in All to follow them. Only matches returned by the feed appear here.'
        : 'The provider returned ${_matches.length} matches. Coverage can be limited; refresh or view all available matches.';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _emptyState(context, icon: Icons.sports_cricket, title: title, message: message),
      Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
        TextButton.icon(
          onPressed: () => setState(() { _filter = 'All'; _searchController.clear(); }),
          icon: const Icon(Icons.list_alt), label: const Text('View all matches')),
        TextButton.icon(onPressed: _fetchingMatches ? null : _loadMatches,
          icon: const Icon(Icons.refresh), label: const Text('Refresh scores')),
      ]),
    ]);
  }

  Widget _navigationSection(BuildContext context) {
    if (_navigationIndex == 1) return FixturesCalendarPage(matches: _matches);
    if (_navigationIndex == 5) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('More', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          ),
          Card(child: ListTile(
            leading: const Icon(Icons.account_circle_outlined, color: scoreXGold),
            title: const Text('My profile & account'),
            subtitle: const Text('Your UID, email and profile photo'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ScoreXAccountPage())),
          )),
          Card(child: ListTile(
            leading: const Icon(Icons.settings_outlined, color: scoreXGold),
            title: const Text('Settings & Preferences'),
            subtitle: const Text('Theme, notifications and app options'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openSettings,
          )),
          const SizedBox(height: 12),
          const Text('PRIVACY, SUPPORT & LEGAL',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          ...[
            (label: 'Privacy Policy', icon: Icons.privacy_tip_outlined, topic: ScoreXLegalTopic.privacy),
            (label: 'Support', icon: Icons.support_agent_outlined, topic: ScoreXLegalTopic.support),
            (label: 'Advertising Disclosure', icon: Icons.ads_click_outlined, topic: ScoreXLegalTopic.advertising),
            (label: 'Account & Data Deletion', icon: Icons.delete_outline, topic: ScoreXLegalTopic.deletion),
          ].map((item) => Card(child: ListTile(
            leading: Icon(item.icon, color: scoreXGold),
            title: Text(item.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ScoreXLegalPage(topic: item.topic),
            )),
          ))),
          const SizedBox(height: 12),
          const Card(child: ListTile(
            leading: Icon(Icons.info_outline, color: scoreXGold),
            title: Text('About ScoreX'),
            subtitle: Text('Version 1.0.1 • Cricket live scores'),
          )),
        ],
      );
    }
    final isSeries = _navigationIndex == 1;
    final isSocial = _navigationIndex == 3;
    final title = isSeries ? 'Cricket Series' : isSocial ? 'Cricket Community' : 'Cricket Videos';
    final icon = isSeries ? Icons.emoji_events_outlined
        : isSocial ? Icons.groups_outlined : Icons.ondemand_video_outlined;
    final description = isSeries
        ? 'Explore upcoming fixtures, tournaments and cricket series.'
        : isSocial
            ? 'Community features will be available in a future update.'
            : 'Video highlights will appear when a licensed video source is connected.';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 58, color: scoreXGold),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(description, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (isSeries)
            FilledButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('View fixtures & series'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const FixturesCalendarPage()),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _heroCard(BuildContext context) {
    final live = _matches.where((m) => m.status == MatchStatus.live).length;
    final upcoming = _matches.where((m) => m.status == MatchStatus.upcoming).length;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B6049), Color(0xFF0A2B23)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: const Color(0x66FFC857)),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.sports_cricket_rounded, color: scoreXGold, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text('THE CRICKET EDIT', style: TextStyle(
            color: scoreXGold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 16),
        const Text('Your game.\nCloser than ever.', style: TextStyle(
          fontSize: 28, height: 1.12, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 10),
        const Text('Scores, fixtures & every match that matters.',
          style: TextStyle(color: Color(0xFFCCE5D9), fontSize: 12, height: 1.5)),
        const SizedBox(height: 20),
        Wrap(spacing: 10, runSpacing: 8, children: [
          _overviewPill(Icons.bolt_rounded, _loadingMatches || _matchError != null ? 'Live • —' : '$live live'),
          _overviewPill(Icons.event_outlined, _loadingMatches || _matchError != null ? 'Upcoming • —' : '$upcoming upcoming'),
        ]),
      ]),
    );
  }

  Widget _overviewPill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0x22FFFFFF))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: scoreXGold, size: 15), const SizedBox(width: 6),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );

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
                onPressed: () {
                  final matchId = _matches.isNotEmpty ? _matches.first.id : null;
                  if (matchId != null && matchId.isNotEmpty) _openMatchCentre(matchId);
                },
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
            onTap: () {
              if (['Live score', 'Commentary', 'Scorecard'].contains(feature.title)) {
                setState(() {
                  _navigationIndex = 2;
                  _filter = feature.title == 'Live score' ? 'Live' : 'All';
                  _searchController.clear();
                });
                return;
              }
              Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => feature.title == 'Fixtures & Series'
                  ? const FixturesCalendarPage()
                  : feature.title == 'Statistics'
                      ? const ScoreXAdvancedAnalytics()
                      : ScoreXFeaturePage(title: feature.title),
            ));
            },
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
          const Text('APP UPDATES', style: TextStyle(fontSize: 12, letterSpacing: 1.4, color: Colors.grey, fontWeight: FontWeight.bold)),
          Card(child: ListTile(
            leading: const Icon(Icons.system_update_alt, color: scoreXGold),
            title: const Text('Check for updates'),
            subtitle: const Text('Check for the latest ScoreX release'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppUpdateService.check(context),
          )),
          const SizedBox(height: 20),
          const Text('HELP, PRIVACY & POLICIES', style: TextStyle(fontSize: 12, letterSpacing: 1.4, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...[
            (label: 'Privacy Policy', icon: Icons.privacy_tip_outlined, topic: ScoreXLegalTopic.privacy),
            (label: 'Support', icon: Icons.support_agent, topic: ScoreXLegalTopic.support),
            (label: 'Advertising Disclosure', icon: Icons.ads_click_outlined, topic: ScoreXLegalTopic.advertising),
            (label: 'Account & Data Deletion', icon: Icons.delete_outline, topic: ScoreXLegalTopic.deletion),
          ].map((item) => Card(child: ListTile(
            leading: Icon(item.icon),
            title: Text(item.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ScoreXLegalPage(topic: item.topic),
            )),
          ))),
          const SizedBox(height: 20),
          const Text('ABOUT SCOREX', style: TextStyle(fontSize: 12, letterSpacing: 1.4, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.sports_cricket, color: scoreXGold),
              title: Text('ScoreX Cricket'),
              subtitle: Text('Version 1.0.1 • Android-first'),
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Live scores, ball-by-ball commentary and detailed scorecards depend on the cricket data provider and will be connected in the next development phase. ScoreX does not display fictional match data or inaccurate player statistics.'),
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

