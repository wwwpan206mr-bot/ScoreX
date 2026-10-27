import 'package:flutter/material.dart';

class HomeOverview extends StatelessWidget {
  const HomeOverview({super.key, required this.live, required this.upcoming,
    required this.following, required this.loading, required this.stale, required this.onFilter});
  final int live, upcoming, following;
  final bool loading, stale;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF8CE6C3);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: dark ? const [Color(0xFF123C35), Color(0xFF102823)]
              : const [Color(0xFF125447), Color(0xFF0B342C)]),
        border: Border.all(color: const Color(0xFF6BC5A4).withValues(alpha: .24)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.sports_cricket_rounded, color: accent, size: 18),
          const SizedBox(width: 8),
          const Expanded(child: Text('THE MATCHDAY EDIT',
            style: TextStyle(color: accent, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 16),
        Text('Cricket starts here', style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white, fontSize: 28, height: 1.12, letterSpacing: -.8)),
        const SizedBox(height: 8),
        Text(MaterialLocalizations.of(context).formatFullDate(DateTime.now()),
          style: const TextStyle(color: Color(0xFFB3CDC3), fontSize: 12)),
        const SizedBox(height: 22),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 250 &&
              MediaQuery.textScalerOf(context).scale(12) <= 17 ? 3 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
          return Wrap(spacing: 8, runSpacing: 8, children: [
            SizedBox(width: width, child: _stat(context, Icons.bolt_rounded,
              loading ? '—' : '$live', stale ? 'Saved live' : 'Live now', 'Live')),
            SizedBox(width: width, child: _stat(context, Icons.calendar_today_rounded,
              loading ? '—' : '$upcoming', 'Upcoming', 'Upcoming')),
            SizedBox(width: width, child: _stat(context, Icons.star_rounded,
              '$following', 'Following', 'Following')),
          ]);
        }),
      ]),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label, String filter) {
    return Material(color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(16), clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: () => onFilter(filter),
        child: Padding(padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: filter == 'Following'
                ? const Color(0xFFFFD180) : const Color(0xFF8CE6C3)),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white,
              fontSize: 24, height: 1, fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Color(0xFFC5DBD2),
              fontSize: 11, fontWeight: FontWeight.w600)),
          ])),
      ),
    );
  }
}

class MatchFeedNotice extends StatelessWidget {
  const MatchFeedNotice({super.key, required this.stale, this.updatedAt, required this.refreshing,
    required this.onRefresh, this.error});
  final bool stale, refreshing;
  final DateTime? updatedAt;
  final VoidCallback onRefresh;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stamp = updatedAt == null ? null : '${MaterialLocalizations.of(context).formatShortDate(updatedAt!.toLocal())} '
        '${TimeOfDay.fromDateTime(updatedAt!.toLocal()).format(context)}';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant)),
      child: Row(children: [
        Icon(stale ? Icons.history_rounded : Icons.sync_rounded, size: 17,
          color: stale ? scheme.secondary : scheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(stale ? 'Saved scores • updates delayed' : 'Automatic score updates',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurface)),
          if (stamp != null) Text('Last received $stamp', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
          if (error != null && stale) Text('Reconnecting automatically when online.',
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
        ])),
        IconButton(tooltip: 'Refresh scores', onPressed: refreshing ? null : onRefresh,
          icon: refreshing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.refresh_rounded, size: 20)),
      ]),
    );
  }
}

class MatchLoadingCards extends StatelessWidget {
  const MatchLoadingCards({super.key});
  @override
  Widget build(BuildContext context) => Semantics(label: 'Loading cricket scores', child: Column(children: [
    for (var i = 0; i < 2; i++) Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        _bar(context, 90, 10), const SizedBox(height: 20),
        _bar(context, 220, 14), const SizedBox(height: 16),
        _bar(context, 180, 14), const SizedBox(height: 18),
        _bar(context, 140, 9),
      ]))),
  ]));
  Widget _bar(BuildContext context, double width, double height) => Container(width: width, height: height,
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(8)));
}

