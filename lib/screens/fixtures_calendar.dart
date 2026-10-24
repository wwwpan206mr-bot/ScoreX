import 'package:flutter/material.dart';
import '../models/cricket_match.dart';

/// Filterable schedule that accepts verified fixtures from a repository.
class FixturesCalendarPage extends StatefulWidget {
  const FixturesCalendarPage({super.key, this.matches = const []});
  final List<CricketMatch> matches;

  @override
  State<FixturesCalendarPage> createState() => _FixturesCalendarPageState();
}

class _FixturesCalendarPageState extends State<FixturesCalendarPage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  MatchStatus? _status;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.matches.where((match) {
      final date = match.startTime;
      return date != null &&
          DateUtils.isSameDay(date.toLocal(), _selectedDate) &&
          (_status == null || match.status == _status);
    }).toList()
      ..sort((a, b) => a.startTime!.compareTo(b.startTime!));

    return Scaffold(
      appBar: AppBar(title: const Text('Fixtures & Series')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: CalendarDatePicker(
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          onDateChanged: (value) => setState(() => _selectedDate = value),
        )),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          _chip('All', null),
          _chip('Live', MatchStatus.live),
          _chip('Upcoming', MatchStatus.upcoming),
          _chip('Finished', MatchStatus.completed),
        ]),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Card(child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(children: [
              Icon(Icons.event_busy_outlined, size: 42),
              SizedBox(height: 12),
              Text('No verified fixtures for this date', textAlign: TextAlign.center),
              SizedBox(height: 8),
              Text('Schedules will appear when the cricket provider is connected.',
                textAlign: TextAlign.center),
            ]),
          ))
        else
          ...filtered.map((match) => Card(child: ListTile(
            leading: const Icon(Icons.sports_cricket),
            title: Text(match.title),
            subtitle: Text([
              if (match.series != null) match.series!,
              if (match.venue != null) match.venue!,
              match.startTime!.toLocal().toString().substring(11, 16),
            ].join(' • ')),
            trailing: Text(match.status.name.toUpperCase()),
          ))),
      ]),
    );
  }

  Widget _chip(String label, MatchStatus? status) => ChoiceChip(
    label: Text(label),
    selected: _status == status,
    onSelected: (_) => setState(() => _status = status),
  );
}
