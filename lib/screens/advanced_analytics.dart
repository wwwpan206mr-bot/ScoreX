import 'package:flutter/material.dart';
import '../models/ball_event.dart';

/// Visual analytics for provider-supplied deliveries; never estimates win odds.
class ScoreXAdvancedAnalytics extends StatelessWidget {
  const ScoreXAdvancedAnalytics({
    super.key,
    this.deliveries = const [],
    this.winProbability,
    this.partnershipRuns,
    this.partnershipBalls,
  });

  final List<BallEvent> deliveries;
  final double? winProbability;
  final int? partnershipRuns;
  final int? partnershipBalls;

  @override
  Widget build(BuildContext context) {
    final grouped = <int, int>{};
    for (final ball in deliveries) {
      grouped.update(ball.over, (runs) => runs + ball.runs, ifAbsent: () => ball.runs);
    }
    final overs = grouped.keys.toList()..sort();
    final maxRuns = grouped.values.fold<int>(1, (max, runs) => runs > max ? runs : max);
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Match Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Win probability', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (winProbability == null)
            const Text('Unavailable — requires a verified analytics provider.')
          else ...[
            Text('${winProbability!.clamp(0, 100).toStringAsFixed(1)}%'),
            LinearProgressIndicator(value: winProbability!.clamp(0, 100) / 100),
          ],
        ],
      ))),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Manhattan — runs per over',
            style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (overs.isEmpty) const Text('No ball-by-ball data available.')
          else SizedBox(height: 180, child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: overs.map((over) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${grouped[over]}', style: const TextStyle(fontSize: 10)),
                Container(
                  height: 125.0 * grouped[over]! / maxRuns,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC857),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Text('${over + 1}', style: const TextStyle(fontSize: 10)),
              ]),
            ))).toList(),
          )),
        ],
      ))),
      const SizedBox(height: 12),
      Card(child: ListTile(
        title: const Text('Current partnership'),
        subtitle: Text(partnershipRuns == null || partnershipBalls == null
            ? 'Not available from the provider'
            : '$partnershipRuns runs • $partnershipBalls balls'),
      )),
      const Card(child: ListTile(
        title: Text('Wagon wheel'),
        subtitle: Text('Requires verified shot-direction coordinates; no synthetic shots are plotted.'),
        leading: Icon(Icons.radar),
      )),
    ]);
  }
}
