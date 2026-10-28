import 'dart:convert';
import 'package:http/http.dart' as http;

/// Reads Bangladesh's public Google Calendar holiday feed (ICS).
class FestivalEvent {
  const FestivalEvent({required this.title, required this.date});
  final String title;
  final DateTime date;
}

class FestivalCalendarService {
  static const _calendarUrl =
      'https://calendar.google.com/calendar/ical/en.bd%23holiday%40group.v.calendar.google.com/public/basic.ics';

  Future<List<FestivalEvent>> fetchEvents({DateTime? now}) async {
    final today = _dateOnly(now ?? DateTime.now());
    final response = await http.get(Uri.parse(_calendarUrl))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Google Calendar feed unavailable (' + response.statusCode.toString() + ')');
    }
    final lines = const LineSplitter().convert(response.body.replaceAll('\r\n ', ''));
    final events = <FestivalEvent>[];
    String? title;
    DateTime? date;
    for (final line in lines) {
      if (line == 'BEGIN:VEVENT') {
        title = null;
        date = null;
      } else if (line.startsWith('SUMMARY')) {
        final colon = line.indexOf(':');
        if (colon >= 0) title = _unescape(line.substring(colon + 1));
      } else if (line.startsWith('DTSTART')) {
        final colon = line.indexOf(':');
        if (colon >= 0) {
          final value = line.substring(colon + 1).trim();
          final match = RegExp(r'^(\d{4})(\d{2})(\d{2})').firstMatch(value);
          if (match != null) {
            date = DateTime(int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
          }
        }
      } else if (line == 'END:VEVENT' && title != null && date != null) {
        final normalized = _dateOnly(date);
        if (!normalized.isBefore(today.subtract(const Duration(days: 1)))) {
          events.add(FestivalEvent(title: title, date: normalized));
        }
      }
    }
    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  static String _unescape(String value) => value
      .replaceAll(r'\n', ' ')
      .replaceAll(r'\,', ',')
      .replaceAll(r'\;', ';')
      .replaceAll(r'\\', r'\')
      .trim();
}
