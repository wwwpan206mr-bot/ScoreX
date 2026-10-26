import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'cricket_match_centre.dart';
import '../data/cricapi_parser.dart';
import '../models/cricket_match.dart';
import '../data/live_match_data.dart';
import '../models/win_estimate.dart';
import '../services/score_refresh_loop.dart';

// Monte Carlo work runs outside the UI isolate, and only for changed scores.
WinEstimate? estimateMatch(Map<String, dynamic> match) {
  final summary = LiveSummary.fromMatch(match);
  if (summary.innings == null || summary.battingTeam == null || summary.bowlingTeam == null ||
      cricApiStatus(match) != MatchStatus.live) return null;
  return WinEstimate.calculate(summary.innings!, firstInningsRate: summary.firstInningsRate);
}

class LiveMatchCentre extends StatefulWidget {
  const LiveMatchCentre({super.key, required this.matchId, this.initialMatch,
    this.initialStale = false, this.client, this.apiBaseUrl});
  final String matchId;
  final CricketMatch? initialMatch;
  final bool initialStale;
  final http.Client? client;
  final String? apiBaseUrl;
  @override
  State<LiveMatchCentre> createState() => _LiveMatchCentreState();
}

class _LiveMatchCentreState extends State<LiveMatchCentre> with WidgetsBindingObserver {
  late final http.Client _client;
  late final ScoreRefreshLoop _loop;
  Map<String, dynamic>? _data;
  String? _error, _dataSignature, _loadedId;
  bool _loading = false;
  DeliveryFeed _feed = const DeliveryFeed();
  bool _deliveryFailed = false;
  LiveSummary _summary = const LiveSummary();
  WinEstimate? _estimate;
  DateTime? _nextDeliveryAttempt;
  int _failures = 0;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? http.Client();
    _loop = ScoreRefreshLoop(load: _refresh, interval: () => Duration(
      seconds: _failures > 0 ? (_failures > 2 ? 60 : 20)
          : _data != null && cricApiStatus(_data!) != MatchStatus.live ? 30 : 8));
    WidgetsBinding.instance.addObserver(this);
    if (WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) _loop.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loop.start();
    } else {
      _loop.pause();
    }
  }

  @override
  void didUpdateWidget(covariant LiveMatchCentre oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId) {
      _generation++;
      _data = null;
      _dataSignature = null;
      _loadedId = null;
      _feed = const DeliveryFeed();
      _deliveryFailed = false;
      _summary = const LiveSummary();
      _estimate = null;
      _error = null;
      _nextDeliveryAttempt = null;
      _failures = 0;
      // An old match's response cannot overwrite this match. Reuse its in-flight
      // slot before fetching the newly selected match, without overlapping polls.
      unawaited(_loop.refreshNow().then((_) async {
        if (mounted && _loadedId != widget.matchId) await _loop.refreshNow();
      }));
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _generation++;
    if (widget.client == null) _client.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _current(String id, int generation) => mounted && widget.matchId == id && _generation == generation;

  Future<void> _refresh() async {
    final id = widget.matchId;
    final generation = _generation;
    _loading = true;
    if (_data == null && widget.initialMatch == null && mounted) setState(() {});
    final base = widget.apiBaseUrl ?? const String.fromEnvironment('API_BASE_URL');
    if (base.isEmpty) {
      if (_current(id, generation)) setState(() {
        _loading = false;
        _error = 'Live score connection is not configured.';
        _failures++;
      });
      return;
    }
    final uri = Uri.parse('${base.replaceAll(RegExp(r"/+$"), "")}/match')
        .replace(queryParameters: {'id': id});
    // Independent endpoints: an unavailable delivery feed never blocks totals.
    await Future.wait([_loadMatch(uri, id, generation), _loadDeliveries(uri, id, generation)]);
    if (_current(id, generation)) _loading = false;
  }

  Future<void> _loadMatch(Uri uri, String id, int generation) async {
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) throw StateError('Match details unavailable');
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['data'] is! Map) throw const FormatException('Invalid match');
      final match = Map<String, dynamic>.from(decoded['data'] as Map);
      if (match['id']?.toString() != id) throw const FormatException('Wrong match returned');
      if (!_current(id, generation)) return;
      final signature = jsonEncode(match);
      final changed = signature != _dataSignature;
      _loadedId = id;
      _failures = 0;
      if (changed || _error != null) {
        setState(() {
          _data = match;
          _summary = LiveSummary.fromMatch(match);
          _dataSignature = signature;
          _error = null;
          _loading = false;
          if (changed) _estimate = null;
        });
      }
      if (changed && _summary.innings?.target != null && cricApiStatus(match) == MatchStatus.live) {
        final estimate = await compute(estimateMatch, match);
        if (_current(id, generation) && _dataSignature == signature) setState(() => _estimate = estimate);
      }
    } catch (_) {
      if (_current(id, generation)) setState(() {
        _error = 'Connection delayed • reconnecting automatically';
        _loading = false;
        _failures++;
      });
    }
  }

  Future<void> _loadDeliveries(Uri uri, String id, int generation) async {
    if (_nextDeliveryAttempt?.isAfter(DateTime.now()) == true) return;
    try {
      final response = await _client.get(uri.replace(path: uri.path.replaceFirst(RegExp(r'/match$'), '/live')))
          .timeout(const Duration(seconds: 8));
      DeliveryFeed feed;
      if (response.statusCode == 404) {
        feed = const DeliveryFeed(reason: 'Ball-by-ball is not available for this match.');
      } else {
        if (response.statusCode != 200) throw StateError('Delivery refresh failed');
        final envelope = jsonDecode(response.body);
        if (envelope is! Map) throw const FormatException('Invalid delivery feed');
        feed = DeliveryFeed.parse(Map<String, dynamic>.from(envelope), id, DateTime.now());
      }
      if (!_current(id, generation)) return;
      final unchanged = _feed.updatedAt == feed.updatedAt && _feed.source == feed.source &&
          _feed.stale == feed.stale && _feed.reason == feed.reason &&
          listEquals(_feed.deliveries, feed.deliveries) && !_deliveryFailed;
      _nextDeliveryAttempt = feed.source == null ? DateTime.now().add(const Duration(seconds: 60)) : null;
      if (!unchanged) setState(() { _feed = feed; _deliveryFailed = false; });
    } catch (_) {
      if (_current(id, generation)) {
        _nextDeliveryAttempt = DateTime.now().add(const Duration(seconds: 20));
        if (!_deliveryFailed) setState(() => _deliveryFailed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final initial = widget.initialMatch?.id == widget.matchId ? widget.initialMatch : null;
    if (data == null && initial == null) {
      return Scaffold(appBar: AppBar(title: const Text('Match Centre')),
        body: Center(child: _loading ? const CircularProgressIndicator() : Padding(
          padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 44), const SizedBox(height: 12),
            Text(_error ?? 'Connecting to live scores…', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loop.refreshNow, child: const Text('Retry')),
          ]))));
    }
    final scores = data == null ? <Map<String, String>>[
      if (initial!.teamAScore != null) {'team': initial.teamA ?? 'Team 1', 'score': initial.teamAScore!},
      if (initial.teamBScore != null) {'team': initial.teamB ?? 'Team 2', 'score': initial.teamBScore!},
    ] : cricApiScores(data);
    final completed = {MatchStatus.completed, MatchStatus.abandoned}.contains(data == null ? initial!.status : cricApiStatus(data));
    return CricketMatchCentre(
      title: data?['name']?.toString() ?? initial?.title ?? 'Match Centre',
      status: data?['status']?.toString() ?? initial?.result,
      scores: scores, innings: _summary.innings,
      battingTeam: _summary.battingTeam, bowlingTeam: _summary.bowlingTeam,
      estimate: _error == null ? _estimate : null,
      deliveries: _feed.deliveries, batting: _feed.batting, bowling: _feed.bowling,
      deliveryUpdatedAt: _feed.updatedAt, deliverySource: _feed.source,
      deliveryStale: _feed.stale || _deliveryFailed || _error != null ||
          (_feed.updatedAt != null && DateTime.now().toUtc().difference(_feed.updatedAt!).inSeconds > 120) ||
          (data == null && widget.initialStale),
      deliveryMessage: _feed.reason, completed: completed,
      onRefresh: _loop.refreshNow, refreshing: _loading, refreshError: _error,
      venue: data?['venue']?.toString() ?? initial?.venue,
      toss: data?['tossWinner'] == null ? null : '${data!['tossWinner']} • ${data['tossChoice'] ?? ''}',
    );
  }
}
