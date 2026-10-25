import 'package:flutter/material.dart';
import 'live_match_centre.dart';
import '../models/cricket_match.dart';
import '../data/cricapi_match_repository.dart';
import '../widgets/premium_match_card.dart';

class FixturesCalendarPage extends StatefulWidget {
  const FixturesCalendarPage({super.key, this.matches = const []});
  final List<CricketMatch> matches;
  @override
  State<FixturesCalendarPage> createState() => _FixturesCalendarPageState();
}

class _FixturesCalendarPageState extends State<FixturesCalendarPage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  MatchStatus? _status;
  List<CricketMatch> _loaded = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loaded = widget.matches;
    _loading = _loaded.isEmpty;
    if (_loading) _load();
  }

  @override
  void didUpdateWidget(covariant FixturesCalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.matches != oldWidget.matches) _loaded = widget.matches;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await const CricApiMatchRepository().getMatches();
      if (mounted) setState(() { _loaded = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Could not refresh fixtures. Check your connection.'; _loading = false; });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(context: context, initialDate: _selectedDate,
      firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final filtered = _loaded.where((match) => match.startTime != null &&
      DateUtils.isSameDay(match.startTime!.toLocal(), _selectedDate) && (_status == null || match.status == _status)).toList()
      ..sort((a, b) => a.startTime!.compareTo(b.startTime!));
    return Scaffold(
      appBar: AppBar(title: const Text('Fixtures & Series'), actions: [
        IconButton(tooltip: 'Choose date', onPressed: _pickDate, icon: const Icon(Icons.calendar_month_outlined)),
      ]),
      body: RefreshIndicator(onRefresh: _load, child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(), slivers: [
          SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverToBoxAdapter(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('The cricket calendar', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Fixtures available from your cricket feed.', style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: Text(localizations.formatMonthYear(_selectedDate),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                TextButton(onPressed: () => setState(() => _selectedDate = DateUtils.dateOnly(DateTime.now())),
                  child: const Text('Today')),
              ]),
              const SizedBox(height: 8),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                for (var offset = -2; offset <= 4; offset++) _dateChip(_selectedDate.add(Duration(days: offset))),
              ])),
              const SizedBox(height: 20),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                _chip('All', null), _chip('Live', MatchStatus.live),
                _chip('Upcoming', MatchStatus.upcoming), _chip('Finished', MatchStatus.completed),
              ])),
              const SizedBox(height: 18),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              if (_error != null) Card(child: ListTile(leading: const Icon(Icons.wifi_off_rounded),
                title: Text(_error!), trailing: IconButton(tooltip: 'Retry fixtures', onPressed: _load, icon: const Icon(Icons.refresh)))),
              const SizedBox(height: 12),
              Text('${localizations.formatMediumDate(_selectedDate)} • ${filtered.length} matches',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            ],
          ))),
          if (!_loading && filtered.isEmpty) const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: Card(child: Padding(padding: EdgeInsets.all(28), child: Column(children: [
              Icon(Icons.event_available_outlined, size: 40), SizedBox(height: 16),
              Text('No verified fixtures for this date', textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 8),
              Text('Try another date or refresh. Coverage depends on the current provider.', textAlign: TextAlign.center),
            ]))))),
          SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), sliver: SliverList.builder(
            itemCount: filtered.length, itemBuilder: (context, index) => PremiumMatchCard(
              match: filtered[index], favorite: false, onFavorite: () {}, showFavorite: false,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiveMatchCentre(matchId: filtered[index].id))),
            ),
          )),
        ],
      )),
    );
  }

  Widget _dateChip(DateTime date) {
    final selected = DateUtils.isSameDay(date, _selectedDate);
    final scheme = Theme.of(context).colorScheme;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(padding: const EdgeInsets.only(right: 8), child: Material(
      color: selected ? scheme.primary : scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: scheme.outlineVariant)),
      child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () => setState(() => _selectedDate = date),
        child: SizedBox(width: 58, child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Column(children: [
          Text(days[date.weekday - 1], style: TextStyle(fontSize: 11, color: selected ? scheme.onPrimary : scheme.onSurfaceVariant)),
          const SizedBox(height: 8), Text('${date.day}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
            color: selected ? scheme.onPrimary : scheme.onSurface)),
        ]))),
      ),
    ));
  }

  Widget _chip(String label, MatchStatus? status) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
    label: Text(label), selected: _status == status, onSelected: (_) => setState(() => _status = status),
    labelStyle: TextStyle(color: _status == status ? (Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF17231C) : Colors.white) : Theme.of(context).colorScheme.onSurfaceVariant),
  ));
}
