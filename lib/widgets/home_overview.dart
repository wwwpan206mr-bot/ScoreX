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
    const mint = Color(0xFF8CE6C3);
    const gold = Color(0xFFFFD180);
    final date = MaterialLocalizations.of(context).formatFullDate(DateTime.now());

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF103F32), Color(0xFF0A241E), Color(0xFF071A17)],
        ),
        border: Border.all(color: mint.withValues(alpha: .25)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0B6B4B).withValues(alpha: dark ? .18 : .12),
            blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(children: [
        Positioned(right: -34, top: -42, child: Container(
          width: 178, height: 178,
          decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: mint.withValues(alpha: .10), width: 1.2)),
        )),
        Positioned(right: 8, top: 20, child: Transform.rotate(
          angle: -.42,
          child: Container(
            width: 74, height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFFFE3A0), Color(0xFFC7832E), Color(0xFF7A3D1C)]),
              border: Border.all(color: Colors.white.withValues(alpha: .45), width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Center(child: Container(
              width: 42, height: 58,
              decoration: BoxDecoration(border: Border(
                left: BorderSide(color: Colors.white.withValues(alpha: .8), width: 1.5),
                right: BorderSide(color: Colors.white.withValues(alpha: .8), width: 1.5),
              )),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < 5; i++)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Container(width: 5, height: 1.5, color: Colors.white.withValues(alpha: .9))),
              ])),
            )),
          ),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LayoutBuilder(builder: (context, constraints) {
              final brand = Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(
                  color: mint, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Flexible(child: Text('SCOREX  •  MATCHDAY', maxLines: 1,
                  overflow: TextOverflow.ellipsis, style: TextStyle(
                    color: mint, fontSize: 10, letterSpacing: 1.7, fontWeight: FontWeight.w900))),
              ]);
              final status = Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: .12))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(stale ? Icons.history_rounded : Icons.bolt_rounded,
                    size: 13, color: stale ? gold : mint),
                  const SizedBox(width: 4),
                  Text(stale ? 'SAVED' : 'LIVE CENTRE', style: const TextStyle(
                    color: Colors.white, fontSize: 9, letterSpacing: .7, fontWeight: FontWeight.w800)),
                ]),
              );
              if (constraints.maxWidth < 290) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [brand, const SizedBox(height: 8), status]);
              }
              return Row(children: [brand, const Spacer(), status]);
            }),
            const SizedBox(height: 22),
            const Text('Every moment.\nEvery run.', style: TextStyle(
              color: Colors.white, fontSize: 29, height: 1.06,
              letterSpacing: -1.1, fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            Text(date, style: const TextStyle(color: Color(0xFFB8D3C8), fontSize: 11)),
            const SizedBox(height: 5),
            const Text('Cricket starts here', style: TextStyle(color: Color(0xFF8CE6C3), fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 22),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 250 &&
                  MediaQuery.textScalerOf(context).scale(12) <= 17 ? 3 : 1;
              final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(spacing: 8, runSpacing: 8, children: [
                SizedBox(width: width, child: _stat(context, Icons.sensors_rounded,
                  loading ? '—' : '$live', 'Live matches', 'Live', mint)),
                SizedBox(width: width, child: _stat(context, Icons.calendar_month_rounded,
                  loading ? '—' : '$upcoming', 'Coming up', 'Upcoming', Colors.white)),
                SizedBox(width: width, child: _stat(context, Icons.star_rounded,
                  '$following', 'Following', 'Following', gold)),
              ]);
            }),
          ]),
        ),
      ]),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label,
      String filter, Color accent) {
    return Material(
      color: Colors.white.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onFilter(filter),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 17, color: accent),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 23,
              height: 1, fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFC5DBD2), fontSize: 10,
                fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

class MatchFeedNotice extends StatelessWidget {
  const MatchFeedNotice({super.key, required this.stale, this.updatedAt, required this.refreshing, this.error});
  final bool stale, refreshing;
  final DateTime? updatedAt;
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
        if (refreshing) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        else Text(stale ? 'SAVED' : 'LIVE', style: TextStyle(color: stale ? scheme.secondary : const Color(0xFF20C982), fontWeight: FontWeight.w900, fontSize: 11)),
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
