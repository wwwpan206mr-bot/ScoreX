import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'festival_calendar_service.dart';

class FestivalNotificationService {
  FestivalNotificationService._();
  static final FestivalNotificationService instance = FestivalNotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  Future<void> scheduleNextFestival(FestivalEvent event) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, event.date.year, event.date.month, event.date.day, 9);
    if (!scheduled.isAfter(now)) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'scorex_festivals',
        'Festivals & special days',
        channelDescription: 'Festival greetings and upcoming special-day reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.zonedSchedule(
      72001,
      'ScoreX • ' + event.title,
      _greeting(event.title),
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'festival',
    );
  }

  String _greeting(String title) {
    final value = title.toLowerCase();
    if (value.contains('eid') || value.contains('ঈদ')) return 'ঈদ মোবারক! আপনার ও পরিবারের জন্য রইল শুভকামনা।';
    if (value.contains('christmas') || value.contains('বড়দিন')) return 'Merry Christmas! Wishing you peace and joy.';
    if (value.contains('durga') || value.contains('দুর্গা')) return 'শুভ দুর্গাপূজা! সবার জীবনে আনন্দ ও সম্প্রীতি আসুক।';
    if (value.contains('buddha') || value.contains('বুদ্ধ')) return 'শুভ বুদ্ধ পূর্ণিমা! সবার জীবনে শান্তি বিরাজ করুক।';
    if (value.contains('new year') || value.contains('নববর্ষ')) return 'শুভ নববর্ষ! নতুন বছর আনন্দময় হোক।';
    return 'Warm wishes to everyone celebrating ' + title + '!';
  }
}
