import 'package:flutter/material.dart';
import '../models/cricket_match.dart';
import '../theme/scorex_theme.dart';
import 'animated_score.dart';

class PremiumMatchCard extends StatelessWidget {
  const PremiumMatchCard({super.key, required this.match, required this.favorite,
    required this.onFavorite, required this.onTap, this.stale = false, this.showFavorite = true});
  final CricketMatch match;
  final bool favorite, stale, showFavorite;
  final VoidCallback onFavorite, onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final live = match.status == MatchStatus.live && !stale;
    final status = stale ? 'SAVED' : switch (match.status) {
      MatchStatus.live => 'LIVE', MatchStatus.upcoming => 'UPCOMING',
      MatchStatus.completed => 'RESULT', MatchStatus.abandoned => 'ABANDONED', MatchStatus.unknown => 'MATCH',
    };
    final accent = live ? (Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8CE6C3) : const Color(0xFF137B58)) : scheme.primary;
    final title = match.title.split(',');
    final subtitle = [if (title.length > 1) title[1].trim(), if (match.venue != null) match.venue!].join(' • ');
    Widget badge() => Row(mainAxisSize: MainAxisSize.min, children: [
      if (live) ...[
        Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: accent)),
        const SizedBox(width: 6),
      ],
      Text(status, style: TextStyle(color: stale ? scheme.secondary : accent, fontSize: 11, fontWeight: FontWeight.w800)),
    ]);
    return Semantics(button: true, label: 'Open ${match.title}', child: Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: live ? accent.withValues(alpha: .4) : scheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.fromLTRB(18, 10, 14, 18),
        child: LayoutBuilder(builder: (context, constraints) {
          final sideBadge = constraints.maxWidth >= 340 && MediaQuery.textScalerOf(context).scale(14) <= 19;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(subtitle.isEmpty ? match.title : subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, height: 1.4, color: scheme.onSurfaceVariant))),
              if (showFavorite) IconButton(tooltip: favorite ? 'Remove favorite' : 'Add favorite', onPressed: onFavorite,
                icon: Icon(favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: favorite ? scheme.secondary : scheme.onSurfaceVariant, size: 21))
              else const SizedBox(height: 40),
            ]),
            if (!sideBadge) ...[Align(alignment: Alignment.centerRight, child: badge()), const SizedBox(height: 8)],
            Row(children: [
              Expanded(child: Column(children: [
                _team(context, match.teamA ?? 'Team 1', match.teamAScore, match.teamAImage),
                const SizedBox(height: 14),
                _team(context, match.teamB ?? 'Team 2', match.teamBScore, match.teamBImage),
              ])),
              if (sideBadge) ...[
                const SizedBox(width: 14),
                Container(height: 68, width: 1, color: scheme.outlineVariant),
                const SizedBox(width: 14), badge(), const SizedBox(width: 4),
              ],
            ]),
            const SizedBox(height: 16),
            Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: .65)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text(match.result?.trim().isNotEmpty == true ? match.result! : 'View match details',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, height: 1.4, color: live ? accent : scheme.secondary, fontWeight: FontWeight.w600))),
              Icon(Icons.chevron_right_rounded, size: 19, color: scheme.onSurfaceVariant),
            ]),
            if (match.status == MatchStatus.upcoming && match.startTime != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(
                '${MaterialLocalizations.of(context).formatShortDate(match.startTime!.toLocal())} • '
                '${TimeOfDay.fromDateTime(match.startTime!.toLocal()).format(context)}',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))),
          ]);
        })),
      ),
    ));
  }

  Widget _team(BuildContext context, String name, String? score, String? image) {
    final scheme = Theme.of(context).colorScheme;
    final short = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(3)
        .map((s) => s.characters.first).join().toUpperCase();
    final parts = score?.split(' (');
    final total = parts?.first ?? '—';
    final overs = parts != null && parts.length > 1 ? '(${parts.skip(1).join(' (')}' : null;
    final fallback = Center(child: Text(short.isEmpty ? '—' : short,
      style: TextStyle(fontSize: 9, color: scheme.primary, fontWeight: FontWeight.w900)));
    final badge = Container(width: 34, height: 34, decoration: BoxDecoration(
      color: scheme.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(10)),
      child: image == null ? fallback : Image.network(image, width: 34, height: 34,
        cacheWidth: 80, cacheHeight: 80, fit: BoxFit.contain, excludeFromSemantics: true,
        errorBuilder: (_, error, stack) => fallback));
    final teamName = Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13, height: 1.25, fontWeight: FontWeight.w600, color: scheme.onSurface));
    final figures = Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      AnimatedScore(total, textAlign: TextAlign.right,
        style: ScoreXTheme.scoreStyle.copyWith(fontSize: 25,
          color: score == null ? scheme.onSurfaceVariant : scheme.onSurface)),
      if (overs != null) Text(overs, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right,
        style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
    ]);
    return LayoutBuilder(builder: (context, constraints) {
      final stacked = constraints.maxWidth < 250 || MediaQuery.textScalerOf(context).scale(13) > 18;
      if (stacked) {
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [badge, const SizedBox(width: 10), Expanded(child: teamName)]),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: figures),
        ]);
      }
      return Row(children: [
        badge, const SizedBox(width: 10),
        Expanded(flex: 5, child: teamName), const SizedBox(width: 8),
        Flexible(flex: 4, child: figures),
      ]);
    });
  }
}
