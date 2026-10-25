import 'package:flutter/material.dart';
import '../models/cricket_match.dart';

class PremiumMatchCard extends StatelessWidget {
  const PremiumMatchCard({
    super.key,
    required this.match,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
  });

  final CricketMatch match;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  static const gold = Color(0xFFFFC857);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final status = switch (match.status) {
      MatchStatus.live => 'LIVE',
      MatchStatus.upcoming => 'UPCOMING',
      MatchStatus.completed => 'RESULT',
      MatchStatus.abandoned => 'ABANDONED',
      MatchStatus.unknown => 'MATCH',
    };
    final live = match.status == MatchStatus.live;
    final result = match.result?.trim() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: live ? const Color(0x33FF5252) : gold.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                      letterSpacing: 1.1, color: live ? const Color(0xFFFF6969) : gold)),
                ),
                const Spacer(),
                IconButton(
                  tooltip: favorite ? 'Remove favorite' : 'Add favorite',
                  onPressed: onFavorite,
                  icon: Icon(favorite ? Icons.star_rounded : Icons.star_border_rounded, color: gold),
                ),
              ]),
              Text(match.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 15),
              _team(context, match.teamA ?? 'Team 1', match.teamAScore),
              const SizedBox(height: 12),
              _team(context, match.teamB ?? 'Team 2', match.teamBScore),
              if (result.isNotEmpty) ...[
                const SizedBox(height: 14),
                Divider(color: dark ? Colors.white12 : Colors.black12),
                Text(result, style: TextStyle(fontSize: 12,
                  color: dark ? const Color(0xFFB5D8C6) : const Color(0xFF315A48))),
              ],
              const SizedBox(height: 8),
              const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('MATCH CENTRE', style: TextStyle(fontSize: 10,
                  color: gold, fontWeight: FontWeight.w800, letterSpacing: 1)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: gold),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _team(BuildContext context, String name, String? score) {
    return Row(children: [
      Container(
        width: 34, height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: gold.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.sports_cricket_rounded, color: gold, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
      const SizedBox(width: 8),
      Text(score ?? '—', style: const TextStyle(fontSize: 14,
        fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()])),
    ]);
  }
}
