import 'dart:async';
import 'package:flutter/material.dart';
import '../services/festival_calendar_service.dart';
import '../services/festival_notification_service.dart';

class FestivalHeaderWidget extends StatefulWidget {
  const FestivalHeaderWidget({super.key});
  @override
  State<FestivalHeaderWidget> createState() => _FestivalHeaderWidgetState();
}

class _FestivalHeaderWidgetState extends State<FestivalHeaderWidget> {
  final _calendar = FestivalCalendarService();
  List<FestivalEvent> _events = const [];
  bool _loading = true;
  String? _error;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _load();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    try {
      final events = await _calendar.fetchEvents();
      if (!mounted) return;
      setState(() { _events = events; _loading = false; _error = null; });
      final next = events.where((event) => !event.date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))).firstOrNull;
      if (next != null) {
        final notifications = FestivalNotificationService.instance;
        await notifications.requestPermission();
        await notifications.scheduleNextFestival(next);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Calendar temporarily unavailable'; });
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  String _greeting(String title) {
    final text = title.toLowerCase();
    if (text.contains('eid') || text.contains('ঈদ')) return 'ঈদ মোবারক! আপনার জীবনে শান্তি ও আনন্দ আসুক।';
    if (text.contains('christmas') || text.contains('বড়দিন')) return 'Merry Christmas! Wishing you peace and joy.';
    if (text.contains('durga') || text.contains('দুর্গা')) return 'শুভ দুর্গাপূজা! সবার জীবনে আনন্দ ও সম্প্রীতি আসুক।';
    if (text.contains('buddha') || text.contains('বুদ্ধ')) return 'শুভ বুদ্ধ পূর্ণিমা! সবার জীবনে শান্তি বিরাজ করুক।';
    if (text.contains('pohela') || text.contains('boishakh') || text.contains('bengali new year') || text.contains('bangla new year') || text.contains('পহেলা বৈশাখ') || text.contains('বাংলা নববর্ষ')) return 'শুভ নববর্ষ! নতুন বছর আনন্দময় ও সমৃদ্ধ হোক।';
    if (text.contains('victory day') || text.contains('বিজয় দিবস') || text.contains('বিজয় দিবস')) return 'মহান বিজয় দিবসের শুভেচ্ছা।';
    if (text.contains('independence day') || text.contains('স্বাধীনতা দিবস')) return 'মহান স্বাধীনতা দিবসের শুভেচ্ছা।';
    if (text.contains('language martyrs') || text.contains('mother language') || text.contains('শহীদ দিবস') || text.contains('ভাষা শহীদ')) return 'আন্তর্জাতিক মাতৃভাষা দিবসের শ্রদ্ধা ও শুভেচ্ছা।';
    if (text.contains('new year') || text.contains('নববর্ষ')) return 'শুভ নববর্ষ! নতুন বছর আনন্দময় হোক।';
    return 'Warm wishes to everyone celebrating ' + title + '!';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    FestivalEvent? next;
    for (final event in _events) {
      if (!event.date.isBefore(todayDate)) { next = event; break; }
    }
    final isToday = next != null && next.date == todayDate;
    final remaining = next == null ? Duration.zero : next.date.difference(today);
    final countdown = remaining.isNegative ? 'Today'
        : remaining.inDays == 0 ? '${remaining.inHours} hours to go'
        : remaining.inDays == 1 ? '1 day ${remaining.inHours % 24} hours to go'
        : '${remaining.inDays} days ${remaining.inHours % 24} hours to go';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: LinearGradient(colors: [scheme.primary.withValues(alpha: .20), scheme.surface]),
        border: Border.all(color: scheme.primary.withValues(alpha: .35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Festivals & special days', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Dates are loaded from the public Bangladesh Google Calendar holiday feed. Not every religious festival is included in this calendar.'),
              const SizedBox(height: 12),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null) Text(_error!),
              for (final event in _events.take(8))
                ListTile(dense: true, contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.celebration_outlined),
                  title: Text(event.title),
                  subtitle: Text(MaterialLocalizations.of(context).formatMediumDate(event.date))),
              TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Refresh calendar')),
            ]),
          )),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            const Icon(Icons.celebration_rounded, color: Color(0xFFFFC857), size: 25),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isToday ? 'TODAY’S GREETINGS' : 'UPCOMING FESTIVAL',
                style: TextStyle(fontSize: 10, letterSpacing: 1.25, fontWeight: FontWeight.w900, color: scheme.primary)),
              const SizedBox(height: 3),
              Text(_loading ? 'Checking Google Calendar…'
                  : next?.title ?? 'No upcoming festival found',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(_error != null ? 'Tap to view details or retry'
                  : isToday ? _greeting(next.title)
                  : next == null ? 'Tap to check the calendar'
                  : countdown + ' • Tap for details',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ])),
            IconButton(tooltip: 'Refresh festival calendar', onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 20)),
          ]),
        ),
      ),
    );
  }
}
