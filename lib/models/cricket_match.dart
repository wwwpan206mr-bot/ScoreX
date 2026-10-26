/// API-neutral domain model for cricket fixtures and live matches.
/// The app intentionally does not ship fabricated match data.
enum MatchStatus { live, upcoming, completed, abandoned, unknown }

class CricketMatch {
  const CricketMatch({
    required this.id,
    required this.title,
    required this.status,
    this.series,
    this.venue,
    this.startTime,
    this.teamA,
    this.teamB,
    this.teamAImage,
    this.teamBImage,
    this.teamAScore,
    this.teamBScore,
    this.overs,
    this.result,
  });

  final String id;
  final String title;
  final MatchStatus status;
  final String? series;
  final String? venue;
  final DateTime? startTime;
  final String? teamA;
  final String? teamB;
  final String? teamAImage;
  final String? teamBImage;
  final String? teamAScore;
  final String? teamBScore;
  final String? overs;
  final String? result;

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'status': status.name, 'series': series,
    'venue': venue, 'startTime': startTime?.toUtc().toIso8601String(),
    'teamA': teamA, 'teamB': teamB, 'teamAImage': teamAImage, 'teamBImage': teamBImage, 'teamAScore': teamAScore,
    'teamBScore': teamBScore, 'overs': overs, 'result': result,
  };

  factory CricketMatch.fromJson(Map<String, dynamic> json) {
    MatchStatus parseStatus(Object? value) {
      switch (value?.toString().toLowerCase()) {
        case 'live':
        case 'in progress':
          return MatchStatus.live;
        case 'upcoming':
        case 'scheduled':
          return MatchStatus.upcoming;
        case 'completed':
        case 'finished':
        case 'result':
          return MatchStatus.completed;
        case 'abandoned':
          return MatchStatus.abandoned;
        default:
          return MatchStatus.unknown;
      }
    }

    return CricketMatch(
      id: (json['id'] ?? json['matchId'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? 'Cricket match').toString(),
      status: parseStatus(json['status']),
      series: json['series']?.toString(),
      venue: json['venue']?.toString(),
      startTime: DateTime.tryParse((json['startTime'] ?? json['date'] ?? '').toString()),
      teamA: json['teamA']?.toString(),
      teamB: json['teamB']?.toString(),
      teamAImage: json['teamAImage']?.toString(),
      teamBImage: json['teamBImage']?.toString(),
      teamAScore: json['teamAScore']?.toString(),
      teamBScore: json['teamBScore']?.toString(),
      overs: json['overs']?.toString(),
      result: json['result']?.toString(),
    );
  }
}

