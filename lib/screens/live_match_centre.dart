import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cricket_match_centre.dart';

class LiveMatchCentre extends StatefulWidget {
  const LiveMatchCentre({super.key, required this.matchId});
  final String matchId;
  @override
  State<LiveMatchCentre> createState() => _LiveMatchCentreState();
}

class _LiveMatchCentreState extends State<LiveMatchCentre> with WidgetsBindingObserver {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) _refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (baseUrl.isEmpty) throw StateError('API_BASE_URL is not configured');
      final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r"/+$"), "")}/match')
          .replace(queryParameters: {'id': widget.matchId});
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw StateError('Match details unavailable (HTTP ${response.statusCode})');
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['data'] is! Map) throw const FormatException('Match details not supplied by provider');
      if (!mounted) return;
      setState(() { _data = Map<String, dynamic>.from(decoded['data'] as Map); _error = null; });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Centre')),
        body: Center(child: _loading ? const CircularProgressIndicator() : Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 44),
            const SizedBox(height: 12),
            Text(_error ?? 'Match unavailable', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _refresh, child: const Text('Retry')),
          ]),
        )),
      );
    }
    final rawScores = data['score'];
    final scores = <Map<String, String>>[];
    if (rawScores is List) {
      for (final raw in rawScores.whereType<Map>()) {
        scores.add({
          'team': (raw['inning'] ?? 'Innings').toString(),
          'score': raw['r'] == null || raw['w'] == null ? '—' :
            '${raw['r']}/${raw['w']}${raw['o'] == null ? '' : ' (${raw['o']} ov)'}',
        });
      }
    }
    return CricketMatchCentre(
      title: (data['name'] ?? 'Match Centre').toString(),
      status: data['status']?.toString(),
      scores: scores,
      onRefresh: _refresh,
      refreshing: _loading,
      refreshError: _error,
      venue: data['venue']?.toString(),
      toss: data['tossWinner'] == null ? null : '${data['tossWinner']} • ${data['tossChoice'] ?? ''}',
    );
  }
}
