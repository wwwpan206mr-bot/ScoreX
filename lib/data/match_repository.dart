import '../models/cricket_match.dart';

/// Data boundary for future live API integration.
///
/// Keep the provider and API credentials outside the Flutter app. The future
/// implementation should call the Cloudflare Worker, not the provider directly.
abstract interface class MatchRepository {
  Future<List<CricketMatch>> getMatches({MatchStatus? status});
}

/// Honest UI-first implementation. It returns no sample scores, so the app
/// cannot accidentally present invented cricket data as live information.
class UnconfiguredMatchRepository implements MatchRepository {
  const UnconfiguredMatchRepository();

  @override
  Future<List<CricketMatch>> getMatches({MatchStatus? status}) async => const [];
}
