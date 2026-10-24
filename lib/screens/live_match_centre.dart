import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cricket_match_centre.dart';

/// Loads real match details. Unsupported provider fields stay unavailable.
class LiveMatchCentre extends StatefulWidget {
  const LiveMatchCentre({super.key, required this.matchId});
  final String matchId;
  @override
  State<LiveMatchCentre> createState() => _LiveMatchCentreState();
}

class _LiveMatchCentreState extends State<LiveMatchCentre> {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');
  late Future<Map<String, dynamic>> details = _load();

  Future<Map<String, dynamic>> _load() async {
    if (baseUrl.isEmpty) throw StateError('API_BASE_URL is not configured');
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r"/+$"), "")}/match')
        .replace(queryParameters: {'id': widget.matchId});
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('Match details unavailable (HTTP ${response.statusCode})');
    }
    final json = jsonDecode(response.body);
    if (json is! Map || json['data'] is! Map) {
      throw const FormatException('Match details not supplied by provider');
    }
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: details,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(
          appBar: null,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Match Centre')),
          body: Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('${snapshot.error}', textAlign: TextAlign.center),
              ),
              FilledButton(
                onPressed: () => setState(() => details = _load()),
                child: const Text('Retry'),
              ),
            ],
          )),
        );
      }
      final data = snapshot.data!;
      final info = data['teamInfo'];
      final teamNames = info is List
          ? info.whereType<Map>().map((e) => (e['name'] ?? '').toString())
              .where((name) => name.isNotEmpty).toList()
          : <String>[];
      return CricketMatchCentre(
        venue: data['venue']?.toString(),
        toss: data['tossWinner'] == null ? null :
            '${data['tossWinner']} • ${data['tossChoice'] ?? ''}',
        squad: teamNames,
      );
    },
  );
}
