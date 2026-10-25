import 'package:flutter/material.dart';
import '../models/cricket_match.dart';
import '../theme/scorex_theme.dart';

class PremiumMatchCard extends StatelessWidget {
  const PremiumMatchCard({super.key, required this.match, required this.favorite,
    required this.onFavorite, required this.onTap, this.stale = false, this.showFavorite = true});
  final CricketMatch match;
  final bool favorite, stale, showFavorite;
  final VoidCallback onFavorite, onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final live = match.status == MatchStatus.live;
    final status = stale ? 'SAVED' : switch (match.status) {
      MatchStatus.live => 'LIVE', MatchStatus.upcoming => 'UPCOMING',
      MatchStatus.completed => 'RESULT', MatchStatus.abandoned => 'ABANDONED', MatchStatus.unknown => 'MATCH',
    };
    final accent = stale ? scheme.secondary : live ? (dark ? const Color(0xFFFF9693) : const Color(0xFFB42336)) : scheme.primary;
    final result = match.result?.trim() ?? '';
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: live && !stale ? scheme.primary.withValues(alpha: .5) : scheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(18, 10, 8, 0), child: Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: accent.withValues(alpha: .1), borderRadius: BorderRadius.circular(7)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (live && !stale) ...[
                Container(width: 5, height: 5, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                const SizedBox(width: 5),
              ],
              Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1, color: accent)),
            ])),
          const SizedBox(width: 10),
          Expanded(child: Text(match.series ?? _formatLabel,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600))),
          if (showFavorite) IconButton(
            tooltip: favorite ? 'Remove favorite' : 'Add favorite', onPressed: onFavorite,
            isSelected: favorite,
            icon: Icon(favorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: favorite ? scheme.secondary : scheme.onSurfaceVariant, size: 22),
          ) else const SizedBox(height: 44, width: 8),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(18, 2, 18, 18), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(match.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, height: 1.4)),
            const SizedBox(height: 18),
            _team(context, match.teamA ?? 'Team 1', match.teamAScore, false),
            const SizedBox(height: 16),
            _team(context, match.teamB ?? 'Team 2', match.teamBScore, true),
            if (match.status == MatchStatus.upcoming && match.startTime != null) ...[
              const SizedBox(height: 18),
              Row(children: [
                Icon(Icons.schedule_rounded, size: 14, color: scheme.primary), const SizedBox(width: 6),
                Expanded(child: Text('${MaterialLocalizations.of(context).formatShortDate(match.startTime!.toLocal())} • '
                  '${TimeOfDay.fromDateTime(match.startTime!.toLocal()).format(context)}',
                  style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w700))),
              ]),
            ],
          ])),
        Container(padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
          decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .04),
            border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: .65)))),
          child: Row(children: [
            Expanded(child: Text(result.isNotEmpty ? result : match.venue ?? 'View match details',
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, height: 1.4, color: scheme.onSurfaceVariant))),
            const SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 17, color: scheme.primary),
          ]),
        ),
      ])),
    );
  }

  String get _formatLabel {
    final title = match.title.toUpperCase();
    if (title.contains('T20')) return 'T20 CRICKET';
    if (title.contains('ODI')) return 'ONE DAY';
    if (title.contains('TEST')) return 'TEST CRICKET';
    return 'CRICKET';
  }

  Widget _team(BuildContext context, String name, String? score, bool alternate) {
    final scheme = Theme.of(context).colorScheme;
    final accent = alternate ? scheme.secondary : scheme.primary;
    final words = name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final short = words.take(3).map((word) => word.characters.first).join().toUpperCase();
    final parts = score?.split(' (');
    final total = parts?.first ?? '—';
    final overs = parts != null && parts.length > 1 ? '(${parts.skip(1).join(' (')}' : null;
    return Row(children: [
      Container(width: 38, height: 40, alignment: Alignment.center,
        decoration: BoxDecoration(color: accent.withValues(alpha: .1),
          border: Border.all(color: accent.withValues(alpha: .17)), borderRadius: BorderRadius.circular(12)),
        child: Text(short.isEmpty ? '—' : short, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: accent))),
      const SizedBox(width: 10),
      Expanded(flex: 5, child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.2, color: scheme.onSurface))),
      const SizedBox(width: 10),
      Flexible(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(total, textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: ScoreXTheme.scoreStyle.copyWith(fontSize: 23, color: scheme.onSurface)),
        if (overs != null) Text(overs, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right,
          style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
      ])),
    ]);
  }
}
