import 'package:flutter/material.dart';
import '../widgets/animated_score.dart';
import '../widgets/scorex_ads.dart';
import '../models/ball_event.dart';
import '../models/innings_summary.dart';
import '../models/win_estimate.dart';
import '../widgets/live_score_dashboard.dart';
import 'advanced_analytics.dart';

/// A reusable match-centre view. All values are supplied by a data source;
/// missing data is shown explicitly instead of fabricated.
class CricketMatchCentre extends StatelessWidget {
  const CricketMatchCentre({
    super.key,
    this.innings,
    this.title = 'Match Centre',
    this.status,
    this.completed = false,
    this.scores = const [],
    this.onRefresh,
    this.refreshing = false,
    this.refreshError,
    this.deliveries = const [],
    this.batting = const [],
    this.bowling = const [],
    this.squad = const [],
    this.venue,
    this.toss,
    this.pitchReport,
    this.weather,
    this.battingTeam, this.bowlingTeam, this.estimate,
    this.deliveryUpdatedAt, this.deliverySource, this.deliveryStale = false, this.deliveryMessage,
  });

  final String title;
  final String? status;
  final bool completed;
  final List<Map<String, String>> scores;
  final VoidCallback? onRefresh;
  final bool refreshing;
  final String? refreshError;
  final InningsSummary? innings;
  final List<BallEvent> deliveries;
  final List<Map<String, String>> batting;
  final List<Map<String, String>> bowling;
  final List<String> squad;
  final String? venue;
  final String? toss;
  final String? pitchReport;
  final String? weather;
  final String? battingTeam;
  final String? bowlingTeam;
  final WinEstimate? estimate;
  final DateTime? deliveryUpdatedAt;
  final String? deliverySource;
  final bool deliveryStale;
  final String? deliveryMessage;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: const [
            Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Center(child: Text('● LIVE SYNC',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF22C982))))),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: completed ? 'Result' : 'Live'),
              const Tab(text: 'Commentary'),
              Tab(text: 'Scorecard'),
              Tab(text: 'Squads'),
              Tab(text: 'Stats'),
              Tab(text: 'Info'),
            ],
          ),
        ),
        bottomNavigationBar: const SafeArea(
          top: false, child: Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: ScoreXAdSlot())),
        body: Column(children: [
          _scoreHeader(context),
          Expanded(child: TabBarView(children: [
          LiveScoreDashboard(innings: innings, deliveries: deliveries, batting: batting, bowling: bowling,
            estimate: estimate, battingTeam: battingTeam, bowlingTeam: bowlingTeam,
            updatedAt: deliveryUpdatedAt, source: deliverySource, stale: deliveryStale,
            deliveryMessage: deliveryMessage, completed: completed, status: status, venue: venue),
          _live(),
          _scorecard(context),
          _squads(),
          _stats(),
          _info(),
        ])),
        ]),
      ),
    );
  }

  Widget _scoreHeader(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final score in scores)
        Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
          Expanded(child: Text(score['team'] ?? 'Innings', maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Flexible(child: AnimatedScore(score['score'] ?? '—', textAlign: TextAlign.right,
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20, fontWeight: FontWeight.w900))),
        ])),
      if (status?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 10),
        child: Text(status!, style: const TextStyle(color: Color(0xFFFFC857), fontWeight: FontWeight.w700))),
      // Background polling keeps the received score visible without a loading flash.
      if (refreshError != null) Text('Refresh failed • showing last loaded data',
        style: const TextStyle(color: Color(0xFFFFC857), fontSize: 11)),
    ]),
  );

  Widget _panel(String title, Widget child) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: child)),
    ],
  );

  Widget _empty(String name) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.cloud_off_outlined, size: 38, color: Color(0xFFFFC857)),
      const SizedBox(height: 12),
      Text('No verified $name available yet', textAlign: TextAlign.center),
      const SizedBox(height: 6),
      const Text('The current feed does not supply this information.',
        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
    ],
  );

  Widget _live() {
    if (deliveries.isEmpty) return _panel(completed ? 'Match result' : 'Match overview',
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (status?.isNotEmpty == true) ...[
          Text(status!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
        ],
        if (venue?.isNotEmpty == true) ...[
          Text('Venue: $venue'),
          const SizedBox(height: 12),
        ],
        const Row(children: [
          Icon(Icons.info_outline, size: 20, color: Color(0xFFFFC857)),
          SizedBox(width: 8),
          Expanded(child: Text('Ball-by-ball commentary unavailable')),
        ]),
        const SizedBox(height: 6),
        const Text('This feed returned innings totals but no delivery commentary for this match.',
          style: TextStyle(color: Colors.grey)),
      ]));
    final ordered = deliveries.reversed.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ordered.length,
      itemBuilder: (context, index) {
        final ball = ordered[index];
        return Card(child: ListTile(
          leading: CircleAvatar(child: Text(ball.marker)),
          title: Text('${ball.over}.${ball.ball}  •  ${ball.runs} runs'),
          subtitle: Text(ball.commentary ?? 'Delivery update'),
          trailing: ball.isWicket ? const Icon(Icons.sports_cricket, color: Colors.red) : null,
        ));
      },
    );
  }

  Widget _scorecard(BuildContext context) {
    final hasPlayers = batting.isNotEmpty || bowling.isNotEmpty;
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (innings != null) ...[
        _scorecardSummary(context),
        const SizedBox(height: 14),
      ],
      _partnershipPanel(context),
      const SizedBox(height: 14),
      if (batting.isNotEmpty) ...[
        _scorecardSection(context, 'Batting', Icons.sports_cricket,
          _dataTable(batting, const ['name', 'runs', 'balls', 'fours', 'sixes', 'strikeRate'],
            const ['Batter', 'R', 'B', '4s', '6s', 'SR'])),
        const SizedBox(height: 14),
      ],
      if (bowling.isNotEmpty) ...[
        _scorecardSection(context, 'Bowling', Icons.sports,
          _dataTable(bowling, const ['name', 'overs', 'maidens', 'runs', 'wickets', 'economy'],
            const ['Bowler', 'O', 'M', 'R', 'W', 'Econ'])),
      ],
      if (!hasPlayers) ...[
        const SizedBox(height: 8),
        _panel('Player scorecard', _empty('batting and bowling figures')),
      ],
      const SizedBox(height: 8),
      const Text('Figures appear only when supplied by the verified match feed.',
        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11)),
    ]);
  }

  Widget _scorecardSummary(BuildContext context) {
    final data = innings!;
    final scheme = Theme.of(context).colorScheme;
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(battingTeam ?? 'Current innings',
          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${data.runs}/${data.wickets}',
            style: TextStyle(fontSize: 34, height: 1, fontWeight: FontWeight.w900, color: scheme.onSurface)),
          const SizedBox(width: 10),
          Padding(padding: const EdgeInsets.only(bottom: 3),
            child: Text('(${data.overs} ov)', style: TextStyle(color: scheme.onSurfaceVariant))),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 24, runSpacing: 12, children: [
          _scorecardMetric(context, 'CRR', data.currentRunRate?.toStringAsFixed(2) ?? '—'),
          if (data.target != null) _scorecardMetric(context, 'TARGET', '${data.target}'),
          if (data.requiredRunRate != null) _scorecardMetric(context, 'REQ. RATE', data.requiredRunRate!.toStringAsFixed(2)),
          if (data.runsNeeded != null) _scorecardMetric(context, 'NEEDED', '${data.runsNeeded} runs'),
        ]),
      ],
    )));
  }

  Widget _scorecardMetric(BuildContext context, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 10, letterSpacing: .7,
        color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.onSurface)),
    ],
  );

  Widget _partnershipPanel(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(
    children: [
      const Icon(Icons.handshake_outlined, size: 26, color: Color(0xFFFFC857)),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Current partnership', style: TextStyle(fontWeight: FontWeight.w800)),
        SizedBox(height: 4),
        Text('Waiting for verified partnership figures from the live provider.',
          style: TextStyle(fontSize: 12, color: Colors.grey)),
      ])),
      Icon(Icons.lock_clock_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
    ],
  )));

  Widget _scorecardSection(BuildContext context, String title, IconData icon, Widget table) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Row(children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        ])),
      table,
    ]),
  );

  Widget _dataTable(List<Map<String, String>> rows, List<String> keys, List<String> headings) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 16,
          headingRowHeight: 42,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 54,
          columns: headings.asMap().entries.map((entry) => DataColumn(
            numeric: entry.key > 0,
            label: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          )).toList(),
          rows: rows.map((row) => DataRow(
            cells: keys.map((key) => DataCell(Text(row[key] ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
          )).toList(),
        ),
      );

  Widget _squads() => _panel('Playing XI & Squads',
    squad.isEmpty ? _empty('squad') :
      Column(children: squad.map((name) => ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(name),
      )).toList()));

  Widget _stats() {
    return ScoreXAdvancedAnalytics(
      deliveries: deliveries,
      chasingProbability: completed ? null : estimate?.chasingPercent.toDouble(),
    );
  }


  Widget _info() {
    final fields = <String, String?>{
      'Venue': venue, 'Toss': toss, 'Pitch report': pitchReport, 'Weather': weather,
    };
    return _panel('Match information', Column(children: fields.entries.map((entry) =>
      ListTile(
        title: Text(entry.key),
        subtitle: Text(entry.value?.trim().isNotEmpty == true ? entry.value! : 'Not available'),
      ),
    ).toList()));
  }
}


