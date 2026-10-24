import 'package:flutter/material.dart';
import '../models/ball_event.dart';
import '../models/innings_summary.dart';

/// A reusable match-centre view. All values are supplied by a data source;
/// missing data is shown explicitly instead of fabricated.
class CricketMatchCentre extends StatelessWidget {
  const CricketMatchCentre({
    super.key,
    this.innings,
    this.deliveries = const [],
    this.batting = const [],
    this.bowling = const [],
    this.squad = const [],
    this.venue,
    this.toss,
    this.pitchReport,
    this.weather,
  });

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
          title: const Text('Match Centre'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Live'),
              Tab(text: 'Scorecard'),
              Tab(text: 'Squads'),
              Tab(text: 'Stats'),
              Tab(text: 'Info'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _live(),
          _scorecard(),
          _squads(),
          _stats(),
          _info(),
        ]),
      ),
    );
  }

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
      const Text('Connect the cricket data provider to populate this screen.',
        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
    ],
  );

  Widget _live() {
    if (deliveries.isEmpty) return _panel('Ball-by-ball', _empty('commentary'));
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
