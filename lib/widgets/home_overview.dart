import 'package:flutter/material.dart';

class HomeOverview extends StatelessWidget {
  const HomeOverview({super.key, required this.live, required this.upcoming,
    required this.following, required this.loading, required this.stale, required this.onFilter});
  final int live, upcoming, following;
  final bool loading, stale;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF205B43), Color(0xFF103627), Color(0xFF0A241C)]),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFF3A7155)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.sports_cricket_rounded, size: 17, color: Color(0xFFFFC857)),
        const SizedBox(width: 8),
        const Expanded(child: Text('YOUR CRICKET COMPANION', style: TextStyle(
          fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: Color(0xFFD5E7DA)))),
        if (!loading) Container(width: 7, height: 7, decoration: BoxDecoration(
          color: stale ? const Color(0xFFFFC857) : const Color(0xFF63E6BE), shape: BoxShape.circle)),
      ]),
      const SizedBox(height: 18),
      const Text('Cricket,\nin focus.', style: TextStyle(fontSize: 35, letterSpacing: -1.4,
        fontWeight: FontWeight.w900, color: Colors.white, height: 1.08)),
      const SizedBox(height: 12),
      Text(MaterialLocalizations.of(context).formatFullDate(DateTime.now()),
        style: const TextStyle(color: Color(0xFFD5E7DA), fontSize: 12)),
      const SizedBox(height: 22),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _stat(Icons.bolt_rounded, loading ? '— live' : stale ? '$live previously live' : '$live live', 'Live'),
        _stat(Icons.calendar_today_rounded, loading ? '— upcoming' : '$upcoming upcoming', 'Upcoming'),
        _stat(Icons.star_rounded, '$following following', 'Following'),
      ]),
    ]),
  );

  Widget _stat(IconData icon, String label, String filter) => Material(
    color: const Color(0x18FFFFFF), borderRadius: BorderRadius.circular(14),
    child: InkWell(borderRadius: BorderRadius.circular(14), onTap: () => onFilter(filter),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: const Color(0xFFFFC857)), const SizedBox(width: 7),
          Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
        ]),
      ),
    ),
  );
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
          Text(stale ? 'Saved scores • updates delayed' : 'Auto refresh every 30s',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurface)),
          if (stamp != null) Text('Last received $stamp', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
          if (error != null && stale) Text('Check your connection or try again.',
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
