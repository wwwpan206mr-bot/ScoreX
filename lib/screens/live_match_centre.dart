import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cricket_match_centre.dart';
import '../data/cricapi_parser.dart';
import '../models/cricket_match.dart';
import '../data/live_match_data.dart';
import '../models/win_estimate.dart';

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
  DeliveryFeed _feed = const DeliveryFeed();
  bool _deliveryFailed = false;
  LiveSummary _summary = const LiveSummary();
  WinEstimate? _estimate;

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
  void didUpdateWidget(covariant LiveMatchCentre oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId) {
      _data = null;
      _feed = const DeliveryFeed();
      _deliveryFailed = false;
      _summary = const LiveSummary();
      _estimate = null;
      _error = null;
      _loading = false;
      _refresh();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    final requestedId = widget.matchId;
    setState(() => _loading = true);
    try {
      if (baseUrl.isEmpty) throw StateError('API_BASE_URL is not configured');
      final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r"/+$"), "")}/match')
          .replace(queryParameters: {'id': requestedId});
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw StateError('Match details unavailable (HTTP ${response.statusCode})');
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['data'] is! Map) throw const FormatException('Match details not supplied by provider');
      final match = Map<String, dynamic>.from(decoded['data'] as Map);
      if (match['id']?.toString() != requestedId) throw const FormatException('Wrong match returned');
      final summary = LiveSummary.fromMatch(match);
      final estimate = summary.innings != null && summary.battingTeam != null && summary.bowlingTeam != null &&
          cricApiStatus(match) == MatchStatus.live
          ? WinEstimate.calculate(summary.innings!, firstInningsRate: summary.firstInningsRate) : null;
      if (!mounted || widget.matchId != requestedId) return;
      setState(() { _data = match; _summary = summary; _estimate = estimate; _error = null; });
      // A separate endpoint keeps delivery access optional and avoids paid calls.
      try {
        final liveResponse = await http.get(uri.replace(path: uri.path.replaceFirst(RegExp(r'/match$'), '/live')))
            .timeout(const Duration(seconds: 10));
        DeliveryFeed feed;
        if (liveResponse.statusCode == 404) {
          feed = const DeliveryFeed(reason: 'Ball-by-ball is not available for this match.');
        } else {
          if (liveResponse.statusCode != 200) throw StateError('Delivery refresh failed');
          final envelope = jsonDecode(liveResponse.body);
          if (envelope is! Map) throw const FormatException('Invalid delivery feed');
          feed = DeliveryFeed.parse(Map<String, dynamic>.from(envelope), requestedId, DateTime.now());
        }
        if (!mounted || widget.matchId != requestedId) return;
        setState(() { _feed = feed; _deliveryFailed = false; });
      } catch (_) {
        if (mounted && widget.matchId == requestedId) setState(() => _deliveryFailed = true);
      }
    } catch (error) {
      if (mounted && widget.matchId == requestedId) setState(() => _error = error.toString());
    } finally {
      if (mounted && widget.matchId == requestedId) setState(() => _loading = false);
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
    final scores = cricApiScores(data);
    return CricketMatchCentre(
      title: (data['name'] ?? 'Match Centre').toString(),
      status: data['status']?.toString(),
      scores: scores,
      innings: _summary.innings,
      battingTeam: _summary.battingTeam, bowlingTeam: _summary.bowlingTeam,
      estimate: _error == null ? _estimate : null,
      deliveries: _feed.deliveries, batting: _feed.batting, bowling: _feed.bowling,
      deliveryUpdatedAt: _feed.updatedAt, deliverySource: _feed.source,
      deliveryStale: _feed.stale || _deliveryFailed || _error != null,
      deliveryMessage: _feed.reason,
      completed: {MatchStatus.completed, MatchStatus.abandoned}.contains(cricApiStatus(data)),
      onRefresh: _refresh,
      refreshing: _loading,
      refreshError: _error,
      venue: data['venue']?.toString(),
      toss: data['tossWinner'] == null ? null : '${data['tossWinner']} • ${data['tossChoice'] ?? ''}',
    );
  }
}

