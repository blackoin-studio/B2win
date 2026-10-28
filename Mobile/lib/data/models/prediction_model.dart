class PredictionModel {
  final String? id;
  final String league;
  final String? leagueLogo;
  final String date;
  final String awayTeam;
  final String? awayLogo;
  final String homeTeam;
  final String? homeLogo;
  final String score;
  final String time;
  final String tip;
  final String odds;
  final String status;

  const PredictionModel({
    this.id,
    required this.league,
    this.leagueLogo,
    required this.date,
    required this.awayTeam,
    this.awayLogo,
    required this.homeTeam,
    this.homeLogo,
    required this.score,
    required this.time,
    required this.tip,
    required this.odds,
    required this.status,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      id: json['_id'] ?? json['id'],
      league: json['league'] ?? 'Unknown League',
      leagueLogo: json['leagueLogo'],
      date: json['date'] ?? '',
      awayTeam: json['awayTeam'] ?? 'Away Team',
      awayLogo: json['awayLogo'],
      homeTeam: json['homeTeam'] ?? 'Home Team',
      homeLogo: json['homeLogo'],
      score: json['score'] ?? '-',
      time: json['time'] ?? 'Unknown Time',
      tip: json['tip'] ?? 'No Tip',
      odds: json['odds']?.toString() ?? '0.0',
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'league': league,
      'leagueLogo': leagueLogo,
      'date': date,
      'awayTeam': awayTeam,
      'awayLogo': awayLogo,
      'homeTeam': homeTeam,
      'homeLogo': homeLogo,
      'score': score,
      'time': time,
      'tip': tip,
      'odds': odds,
      'status': status,
    };
  }
}
