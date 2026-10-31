import 'dart:async';
import 'dart:convert';
import 'services/score_refresh_loop.dart';
import 'services/ads_service.dart';
import 'widgets/scorex_ads.dart';
import 'screens/account_page.dart';
import 'services/app_update_service.dart';
import 'data/cricapi_match_repository.dart';
import 'data/match_repository.dart';
import 'models/cricket_match.dart';
import 'package:flutter/services.dart';
import 'theme/scorex_theme.dart';
import 'services/match_cache.dart';
import 'widgets/app_version_tile.dart';
import 'widgets/home_overview.dart';
import 'widgets/festival_header_widget.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(AdsService.instance.initialize());
    });
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
    return MaterialApp(
      title: 'ScoreX',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ScoreXTheme.build(Brightness.light),
      darkTheme: ScoreXTheme.build(Brightness.dark),
      themeAnimationDuration: const Duration(milliseconds: 220),
      home: AppUpdateHost(child: ScoreXAuthGate(child: ScoreHomePage(
        darkMode: _darkMode,
        onThemeChanged: _setTheme,
      ))),
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
  late final ScoreRefreshLoop _refreshLoop;
  bool _matchCentreOpen = false;
  int _refreshFailures = 0;
  String? _matchSignature;
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
  bool _showingSavedScores = false;
  int _navigationIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshLoop = ScoreRefreshLoop(load: _loadMatches, interval: () => Duration(
      seconds: _refreshFailures > 0 ? (_refreshFailures > 2 ? 60 : 30)
          : _matches.any((m) => m.status == MatchStatus.live) ? 10 : 30));
    _bootstrap();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_matchCentreOpen) {
      _refreshLoop.start();
    } else {
      _refreshLoop.pause();
    }
  }

  @override
  void dispose() {
    _refreshLoop.dispose();
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

  Future<void> _bootstrap() async {
    await _loadPreferences();
    final cached = await MatchCache.read();
    if (!mounted) return;
    if (cached != null && _lastMatchRefresh == null) {
      setState(() {
        _matches = cached.matches;
        _lastMatchRefresh = cached.savedAt;
        _loadingMatches = false;
        _showingSavedScores = true;
      });
    }
    if (WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _refreshLoop.start();
    }
  }

  Future<void> _loadMatches() async {
    if (_fetchingMatches || !mounted) return;
    _fetchingMatches = true;
    try {
      final matches = await widget.matchRepository.getMatches();
      if (!mounted) return;
      final now = DateTime.now();
      final signature = jsonEncode(matches.map((match) => match.toJson()).toList());
      final changed = signature != _matchSignature || _matchError != null || _showingSavedScores || _loadingMatches;
      _refreshFailures = 0;
      if (!changed) return;
      _matchSignature = signature;
      setState(() {
        _matches = matches;
        _matchError = null;
        _loadingMatches = false;
        _lastMatchRefresh = now;
        _showingSavedScores = false;
      });
      await MatchCache.save(matches, now);
    } catch (error) {
      if (!mounted) return;
      _refreshFailures++;
      setState(() {
        _matchError = error.toString();
        _loadingMatches = false;
        _showingSavedScores = _matches.isNotEmpty;
      });
    } finally {
      _fetchingMatches = false;
    }
  }

  void _selectNavigation(int value) {
    if (value == _navigationIndex) return;
    HapticFeedback.selectionClick();
    setState(() => _navigationIndex = value);
  }

  Future<void> _toggleFavorite(String id) async {
    HapticFeedback.selectionClick();
    setState(() { if (!_favoriteIds.add(id)) _favoriteIds.remove(id); });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favoriteIds.toList());
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

  Future<void> _openMatchCentre(String matchId) async {
    final initial = _matches.where((match) => match.id == matchId).firstOrNull;
    _matchCentreOpen = true;
    _refreshLoop.pause();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LiveMatchCentre(matchId: matchId, initialMatch: initial,
        initialStale: _showingSavedScores),
    ));
    if (!mounted) return;
    _matchCentreOpen = false;
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed ||
        WidgetsBinding.instance.lifecycleState == null) _refreshLoop.start();
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
    final scheme = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(
            'assets/branding/scorex_logo.png', width: 38, height: 38, fit: BoxFit.cover)),
          const SizedBox(width: 10),
          const Expanded(child: Text('ScoreX', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.8))),
        ]),
        actions: [
          IconButton(tooltip: 'Festivals and special days', icon: const Icon(Icons.celebration_outlined), onPressed: () => showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => const SafeArea(child: Padding(padding: EdgeInsets.all(16), child: FestivalHeaderWidget())))),
          IconButton(tooltip: 'My profile', icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ScoreXAccountPage()))),
          IconButton(onPressed: _openSettings, icon: const Icon(Icons.tune_rounded), tooltip: 'Settings'),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(top: false, bottom: false, child: Align(alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1040),
          child: _navigationIndex == 0 || _navigationIndex == 2 ? _matchFeed(context) : _navigationSection(context),
        ),
      )),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: scheme.outlineVariant))),
        child: NavigationBar(
          animationDuration: reducedMotion ? Duration.zero : const Duration(milliseconds: 230),
          labelBehavior: MediaQuery.sizeOf(context).width < 360 || MediaQuery.textScalerOf(context).scale(12) > 18
              ? NavigationDestinationLabelBehavior.onlyShowSelected : NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: _navigationIndex, onDestinationSelected: _selectNavigation,
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
    );
  }

  Widget _matchFeed(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final allVisible = _visibleMatches;
    final shown = _navigationIndex == 0 ? allVisible.take(4).toList() : allVisible;
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 760 && MediaQuery.textScalerOf(context).scale(14) <= 20 ? 2 : 1;
      return RefreshIndicator(onRefresh: _refreshLoop.refreshNow, child: CustomScrollView(
        key: PageStorageKey('match-feed-$_navigationIndex'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), sliver: SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_navigationIndex == 0) ...[
                const FestivalHeaderWidget(),
                _heroCard(context), const SizedBox(height: 16),
              ],
              TextField(
                controller: _searchController, onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search teams or matches', prefixIcon: Icon(Icons.search_rounded, color: scheme.primary),
                  suffixIcon: _searchController.text.isEmpty ? null : IconButton(tooltip: 'Clear search',
                    onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close_rounded)),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: Text(_navigationIndex == 0 ? 'Featured matches' : 'All matches',
                  style: Theme.of(context).textTheme.titleLarge)),
                if (_loadingPreferences) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                else Text('${allVisible.length} matches', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              ]),
              const SizedBox(height: 14),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                for (final item in ['All', 'Live', 'Upcoming', 'Results', 'Following'])
                  Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
                    label: Text(item == 'Live' ? 'Live (${_matches.where((m) => m.status == MatchStatus.live).length})' : item), selected: _filter == item, showCheckmark: false,
                    labelStyle: TextStyle(fontWeight: FontWeight.w700,
                      color: _filter == item ? (Theme.of(context).brightness == Brightness.dark ? scheme.onPrimary : Colors.white)
                          : scheme.onSurfaceVariant),
                    onSelected: (_) { HapticFeedback.selectionClick(); setState(() => _filter = item); },
                  )),
              ])),
              const SizedBox(height: 14),
              MatchFeedNotice(stale: _showingSavedScores, updatedAt: _lastMatchRefresh,
                refreshing: _loadingMatches, onRefresh: _refreshLoop.refreshNow, error: _matchError),
              const SizedBox(height: 16),
              if (_loadingMatches) const MatchLoadingCards(),
              if (_matchError != null && _matches.isEmpty) ...[
                _emptyState(context, icon: Icons.wifi_off_rounded, title: 'Live scores unavailable', message: _matchError!),
                FilledButton.icon(onPressed: _refreshLoop.refreshNow,
                  icon: const Icon(Icons.refresh), label: const Text('Try again')),
              ],
              if (!_loadingMatches && allVisible.isEmpty && (_matchError == null || _matches.isNotEmpty)) _filteredEmptyState(context),
            ]),
          )),
          if (!_loadingMatches && shown.isNotEmpty)
            SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverList.builder(
              itemCount: (shown.length / columns).ceil(),
              itemBuilder: (context, row) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (var column = 0; column < columns; column++) ...[
                  if (column > 0) const SizedBox(width: 14),
                  Expanded(child: row * columns + column >= shown.length ? const SizedBox.shrink() :
                    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (row == 0 || columns > 1 || shown[row - 1].series != shown[row].series)
                      Padding(padding: const EdgeInsets.fromLTRB(4, 16, 4, 10), child: Text(
                        shown[row * columns + column].series ?? 'Cricket matches',
                        style: Theme.of(context).textTheme.titleMedium)),
                    RepaintBoundary(child: PremiumMatchCard(
                      key: ValueKey(shown[row * columns + column].id),
                      match: shown[row * columns + column],
                      favorite: _favoriteIds.contains(shown[row * columns + column].id),
                      stale: _showingSavedScores,
                      onFavorite: () => _toggleFavorite(shown[row * columns + column].id),
                      onTap: () => _openMatchCentre(shown[row * columns + column].id),
                    )),
                    ])),
                ],
              ]),
            )),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  ScoreXAdSlot(format: ScoreXAdFormat.native),
                  SizedBox(height: 8),
                  ScoreXAdSlot(format: ScoreXAdFormat.banner),
                ],
              ),
            ),
          ),
          SliverPadding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 28), sliver: SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_navigationIndex == 0) ...[
                TextButton.icon(onPressed: () => _selectNavigation(2),
                  label: const Text('Explore all matches'), icon: const Icon(Icons.arrow_forward_rounded, size: 18)),
                const SizedBox(height: 22),
                Text('Explore ScoreX', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14), _featureGrid(context),
              ],
              const SizedBox(height: 24),
              Text('SCOREX  /  EVERY RUN. EVERY WICKET.', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, letterSpacing: 1.1, color: scheme.onSurfaceVariant)),
            ]),
          )),
        ],
      ));
    });
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
        TextButton.icon(onPressed: _refreshLoop.refreshNow,
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
          const AdsPrivacyTile(),
          const AppVersionTile(),
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

  Widget _heroCard(BuildContext context) => HomeOverview(
    live: _matches.where((m) => m.status == MatchStatus.live).length,
    upcoming: _matches.where((m) => m.status == MatchStatus.upcoming).length,
    following: _favoriteIds.length, loading: _loadingMatches, stale: _showingSavedScores,
    onFilter: (filter) => setState(() { _filter = filter; _navigationIndex = 2; _searchController.clear(); }),
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
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 180 * MediaQuery.textScalerOf(context).scale(14) / 14,
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
                  Text(feature.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(feature.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ScoreXSettingsPage extends StatefulWidget {
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
  State<ScoreXSettingsPage> createState() => _ScoreXSettingsPageState();
}

class _ScoreXSettingsPageState extends State<ScoreXSettingsPage> {
  late bool darkMode = widget.darkMode;
  late bool notificationsEnabled = widget.notificationsEnabled;

  void onThemeChanged(bool value) {
    setState(() => darkMode = value);
    widget.onThemeChanged(value);
  }

  void onNotificationsChanged(bool value) {
    setState(() => notificationsEnabled = value);
    widget.onNotificationsChanged(value);
  }

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
          const AdsPrivacyTile(),
          Card(child: ListTile(
            leading: const Icon(Icons.cleaning_services_outlined), title: const Text('Clear saved scores'),
            subtitle: const Text('Remove the offline match snapshot from this device'),
            onTap: () async {
              await MatchCache.clear();
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved scores cleared')));
            },
          )),
          const Text('HELP, PRIVACY & POLICIES' , style: TextStyle(fontSize: 12, letterSpacing: 1.4, color: Colors.grey, fontWeight: FontWeight.bold)),
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
          const AppVersionTile(),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Scores and delivery coverage depend on the cricket provider. Saved scores show the last received update and are labelled when refresh is delayed. Updates reconnect automatically when you return to the app.'),
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


