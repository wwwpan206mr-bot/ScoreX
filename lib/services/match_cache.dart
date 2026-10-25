import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cricket_match.dart';

class MatchSnapshot {
  const MatchSnapshot(this.matches, this.savedAt);
  final List<CricketMatch> matches;
  final DateTime savedAt;
}

/// Public match totals only. Cached data is never presented as a fresh live feed.
abstract final class MatchCache {
  static const key = 'scorex_match_snapshot_v1';

  static Future<MatchSnapshot?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(key);
      if (encoded == null) return null;
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      final savedAt = DateTime.parse(json['savedAt'] as String);
      final matches = (json['matches'] as List).map((m) => CricketMatch.fromJson(Map<String, dynamic>.from(m as Map)))
          .where((m) => m.id.isNotEmpty).toList();
      if (matches.isEmpty) return null;
      return MatchSnapshot(matches, savedAt);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(List<CricketMatch> matches, DateTime savedAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode({
        'savedAt': savedAt.toUtc().toIso8601String(),
        'matches': matches.take(250).map((match) => match.toJson()).toList(),
      }));
    } catch (_) {
      // Device storage availability must not turn a successful score refresh into an error.
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
