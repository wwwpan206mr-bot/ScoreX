import 'package:flutter/material.dart';
import 'scorex_ads.dart';
import 'animated_score.dart';
import '../theme/scorex_theme.dart';
import '../models/ball_event.dart';
import '../models/innings_summary.dart';
import '../models/win_estimate.dart';

class LiveScoreDashboard extends StatelessWidget {
  const LiveScoreDashboard({super.key, this.innings, this.deliveries = const [],
    this.batting = const [], this.bowling = const [], this.estimate,
    this.battingTeam, this.bowlingTeam, this.updatedAt, this.source,
    this.stale = false, this.deliveryMessage, this.completed = false,
    this.status, this.venue});

  final InningsSummary? innings;
  final List<BallEvent> deliveries;
  final List<Map<String, String>> batting;
  final List<Map<String, String>> bowling;
  final WinEstimate? estimate;
  final String? battingTeam;
  final String? bowlingTeam;
  final DateTime? updatedAt;
  final String? source;
  final bool stale;
  final String? deliveryMessage;
  final bool completed;
  final String? status;
  final String? venue;

  Widget _card(Widget child) => Card(child: Padding(padding: const EdgeInsets.all(16), child: child));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gold = scheme.secondary;
    final mint = scheme.primary;
    final data = innings;
    final recent = deliveries.length > 12 ? deliveries.sublist(deliveries.length - 12) : deliveries;
    final prediction = stale || completed ? null : estimate;
    return ListView(key: const PageStorageKey('live-dashboard'), padding: const EdgeInsets.all(12), children: [
      if (stale) _card(Row(children: [
        Icon(Icons.schedule, color: gold), SizedBox(width: 10),
        Expanded(child: Text('Updates delayed • showing the last received deliveries')),
      ])),
      Text(completed ? 'Match result' : 'Live match centre',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      if (completed && status != null) _card(Text(status!, style: const TextStyle(fontWeight: FontWeight.bold))),
      if (data != null) Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withValues(alpha: .35)),
          // A flat score surface avoids expensive decorative layers while updating.
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(battingTeam ?? 'Current innings', style: TextStyle(color: mint, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(spacing: 24, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedScore('${data.runs}/${data.wickets}', style: ScoreXTheme.scoreStyle.copyWith(fontSize: 44, color: mint)),
            Text('${data.overs} overs', style: TextStyle(color: scheme.onSurfaceVariant)),
          ]),
          if (recent.isNotEmpty && !stale && !completed)
            Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Text('LAST BALL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                AnimatedScore(recent.last.marker, style: ScoreXTheme.scoreStyle.copyWith(fontSize: 32,
                  color: recent.last.isWicket ? const Color(0xFFDA4555) : scheme.primary)),
              ])),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 24, runSpacing: 12, children: [
          _metric('CRR', data.currentRunRate?.toStringAsFixed(2) ?? '—'),
          if (data.target != null) _metric('Target', '${data.target}'),
          if (data.requiredRunRate != null) _metric('RRR', data.requiredRunRate!.toStringAsFixed(2)),
        ]),
        if (!completed && data.runsNeeded != null && data.ballsRemaining != null) ...[
          const SizedBox(height: 12),
          Text('${data.runsNeeded} runs needed in ${data.ballsRemaining} balls',
            style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
        ],
        if (!completed && data.target == null && data.legalBalls > 0 &&
            data.wickets < 10 && data.scheduledOvers != null) ...[
          const SizedBox(height: 12),
          Text('At current run rate: ${(data.currentRunRate! * data.scheduledOvers!).round()} projected',
            style: const TextStyle(color: Colors.grey)),
        ],
      ])),
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recent deliveries', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (recent.isEmpty) ...[
          const Text('Ball-by-ball commentary unavailable'),
          const SizedBox(height: 6),
          Text(deliveryMessage ?? 'A delivery feed is needed to show each ball.',
            style: const TextStyle(color: Colors.grey)),
        ] else SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (var index = 0; index < recent.length; index++) ...[
            if (index == 0 || recent[index].over != recent[index - 1].over)
              Padding(padding: const EdgeInsets.only(right: 8),
                child: Text('Over ${recent[index].over + 1}', style: const TextStyle(fontSize: 11))),
            Padding(padding: const EdgeInsets.only(right: 6), child: _ball(context, recent[index])),
          ],
        ])),
        if (source != null && updatedAt != null) ...[
          const SizedBox(height: 12),
          Text('$source • source update ${TimeOfDay.fromDateTime(updatedAt!.toLocal()).format(context)}',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ])),
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.insights, size: 18, color: gold), SizedBox(width: 8),
          Expanded(child: Text('Estimated win probability', style: TextStyle(fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 14),
        if (prediction == null || battingTeam == null || bowlingTeam == null)
          Text(completed ? 'Match finished • see the official result above.'
            : stale ? 'Estimate paused while delivery updates are delayed.'
            : 'Available during a supported T20/ODI chase after 12 legal balls, with verified teams and target.',
            style: const TextStyle(color: Colors.grey))
        else ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text('$battingTeam\n${prediction.chasingPercent}%',
              style: TextStyle(color: mint, fontWeight: FontWeight.w800))),
            const SizedBox(width: 12),
            Expanded(child: Text('$bowlingTeam\n${prediction.defendingPercent}%', textAlign: TextAlign.right,
              style: TextStyle(color: gold, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(height: 10, child: Row(children: [
            if (prediction.chasingPercent > 0) Expanded(flex: prediction.chasingPercent, child: Container(color: mint)),
            if (prediction.tiePercent > 0) Expanded(flex: prediction.tiePercent, child: Container(color: Colors.grey)),
            if (prediction.defendingPercent > 0) Expanded(flex: prediction.defendingPercent, child: Container(color: gold)),
          ]))),
          const SizedBox(height: 8),
          Text('Tie: ${prediction.tiePercent}% • before any super over', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Experimental statistical model • not trained AI. Assumes current scoring and wicket rates continue. Historical accuracy has not been calibrated.',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ])),
      _players('Batters', batting, const ['name', 'runs', 'balls', 'fours', 'sixes', 'strikeRate'],
        const ['Batter', 'R', 'B', '4s', '6s', 'SR']),
      _players('Bowlers', bowling, const ['name', 'wickets', 'runs', 'overs', 'economy'],
        const ['Bowler', 'W', 'R', 'Overs', 'Econ']),
      const ScoreXAdSlot(format: ScoreXAdFormat.native),
      if (venue != null) Padding(padding: const EdgeInsets.all(8), child: Text(venue!,
        style: const TextStyle(color: Colors.grey, fontSize: 12))),
    ]);
  }

  Widget _metric(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
  ]);

  Widget _ball(BuildContext context, BallEvent ball) {
    final gold = Theme.of(context).colorScheme.secondary;
    final mint = Theme.of(context).colorScheme.primary;
    final color = ball.isWicket ? const Color(0xFFFF6B6B)
      : ball.batterRuns >= 4 ? mint : gold;
    return Semantics(label: '${ball.over}.${ball.ball}: ${ball.marker}', child: Container(
      width: 38, height: 38, alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: ball.isWicket || ball.batterRuns >= 4 ? color : color.withValues(alpha: .1),
        border: Border.all(color: color.withValues(alpha: .4))),
      child: Text(ball.marker, style: TextStyle(color: ball.isWicket || ball.batterRuns >= 4 ? Theme.of(context).colorScheme.surface : color, fontWeight: FontWeight.w900)),
    ));
  }

  Widget _players(String title, List<Map<String, String>> rows, List<String> keys, List<String> headings) =>
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      if (rows.isEmpty) const Text('Player figures are not supplied for this match.', style: TextStyle(color: Colors.grey))
      else SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(
        columnSpacing: 18, horizontalMargin: 0,
        columns: headings.map((text) => DataColumn(label: Text(text))).toList(),
        rows: rows.map((row) => DataRow(cells: keys.map((key) => DataCell(Text(row[key] ?? '—'))).toList())).toList(),
      )),
    ]));
}

