import 'package:flutter/material.dart';
import '../models/ball_event.dart';
import '../models/innings_summary.dart';

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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [IconButton(onPressed: refreshing ? null : onRefresh, tooltip: 'Refresh match', icon: const Icon(Icons.refresh_rounded))],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: completed ? 'Result' : 'Overview'),
              Tab(text: 'Scorecard'),
              Tab(text: 'Squads'),
              Tab(text: 'Stats'),
              Tab(text: 'Info'),
            ],
          ),
        ),
        body: Column(children: [
          _scoreHeader(),
          Expanded(child: TabBarView(children: [
          _live(),
          _scorecard(),
          _squads(),
          _stats(),
          _info(),
        ])),
        ]),
      ),
    );
  }

  Widget _scoreHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF15533E), Color(0xFF09271D)])),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final score in scores)
        Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
          Expanded(child: Text(score['team'] ?? 'Innings', maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Flexible(child: Text(score['score'] ?? '—', textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))),
        ])),
      if (status?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 10),
        child: Text(status!, style: const TextStyle(color: Color(0xFFFFC857), fontWeight: FontWeight.w700))),
      if (refreshing) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator(minHeight: 2)),
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

  Widget _scorecard() {
    if (batting.isEmpty && bowling.isEmpty) return _panel('Scorecard', _empty('scorecard'));
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (batting.isNotEmpty) ...[
        const Text('Batting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        _dataTable(batting, const ['name', 'runs', 'balls', 'fours', 'sixes', 'strikeRate']),
      ],
      const SizedBox(height: 16),
      if (bowling.isNotEmpty) ...[
        const Text('Bowling', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        _dataTable(bowling, const ['name', 'overs', 'maidens', 'runs', 'wickets', 'economy']),
      ],
    ]);
  }

  Widget _dataTable(List<Map<String, String>> rows, List<String> keys) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: keys.map((key) => DataColumn(label: Text(key))).toList(),
          rows: rows.map((row) => DataRow(
            cells: keys.map((key) => DataCell(Text(row[key] ?? '—'))).toList(),
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
    final data = innings;
    if (data == null) return _panel('Match analytics', _empty('statistics'));
    String rate(double? value) => value?.toStringAsFixed(2) ?? '—';
    final recent = deliveries.length <= 6 ? deliveries : deliveries.sublist(deliveries.length - 6);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${data.runs}/${data.wickets} (${data.overs} ov)',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Wrap(spacing: 24, runSpacing: 12, children: [
            _metric('CRR', rate(data.currentRunRate)),
            _metric('RRR', rate(data.requiredRunRate)),
            _metric('Need', data.runsNeeded?.toString() ?? '—'),
            _metric('Balls left', data.ballsRemaining?.toString() ?? '—'),
          ]),
          const SizedBox(height: 20),
          const Text('Recent deliveries'),
          const SizedBox(height: 8),
          if (recent.isEmpty) const Text('No delivery data')
          else Wrap(spacing: 8, children: recent.map((b) =>
            Chip(label: Text(b.marker))).toList()),
        ],
      ))),
    ]);
  }

  Widget _metric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ],
  );

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

