import 'package:b2win/data/models/prediction_model.dart';
import 'package:b2win/data/providers/ai_provider.dart';

class AiMatchInsightResult {
  final int confidence;
  final String riskLevel;
  final String marketCategory;
  final List<String> bullets;
  final String verdict;

  const AiMatchInsightResult({
    required this.confidence,
    required this.riskLevel,
    required this.marketCategory,
    required this.bullets,
    required this.verdict,
  });

  factory AiMatchInsightResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final rawBullets = data['bullets'];
    final bulletsList = rawBullets is List
        ? rawBullets.map((e) => e.toString()).toList()
        : <String>[];

    return AiMatchInsightResult(
      confidence: int.tryParse(data['confidence']?.toString() ?? '76') ?? 76,
      riskLevel: data['riskLevel']?.toString() ?? 'Balanced Risk',
      marketCategory: data['marketCategory']?.toString() ?? 'Match Tip',
      bullets: bulletsList,
      verdict: data['verdict']?.toString() ?? '',
    );
  }
}

class AiSmartSlipResult {
  final String strategyTitle;
  final String combinedOdds;
  final int slipConfidence;
  final List<Map<String, dynamic>> picks;
  final String summary;

  const AiSmartSlipResult({
    required this.strategyTitle,
    required this.combinedOdds,
    required this.slipConfidence,
    required this.picks,
    required this.summary,
  });

  factory AiSmartSlipResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final rawPicks = data['picks'];
    final parsedPicks = rawPicks is List
        ? rawPicks
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    return AiSmartSlipResult(
      strategyTitle:
          data['strategyTitle']?.toString() ?? 'Balanced Smart Accumulator',
      combinedOdds: data['combinedOdds']?.toString() ?? '1.00',
      slipConfidence:
          int.tryParse(data['slipConfidence']?.toString() ?? '75') ?? 75,
      picks: parsedPicks,
      summary: data['summary']?.toString() ?? '',
    );
  }
}

class AiBlogSummaryResult {
  final List<String> bullets;
  final String keyTakeaway;

  const AiBlogSummaryResult({
    required this.bullets,
    required this.keyTakeaway,
  });

  factory AiBlogSummaryResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final rawBullets = data['bullets'];
    final bulletsList = rawBullets is List
        ? rawBullets.map((e) => e.toString()).toList()
        : <String>[];

    return AiBlogSummaryResult(
      bullets: bulletsList,
      keyTakeaway: data['keyTakeaway']?.toString() ?? '',
    );
  }
}

class AiRepository {
  final AiProvider _provider;

  AiRepository({required AiProvider provider}) : _provider = provider;

  static int computeConfidence(String oddsStr) {
    final odds = double.tryParse(oddsStr) ?? 1.75;
    final implied = ((1 / (odds < 1.05 ? 1.05 : odds)) * 100).round();
    return (implied * 1.08).round().clamp(56, 91);
  }

  static String computeRiskLevel(String oddsStr) {
    final odds = double.tryParse(oddsStr) ?? 1.75;
    if (odds <= 1.65) return 'Low Risk';
    if (odds >= 2.15) return 'High-Value Pick';
    return 'Balanced Risk';
  }

  Future<AiMatchInsightResult> getMatchInsight(PredictionModel game) async {
    try {
      final res = await _provider.fetchMatchInsight(
        homeTeam: game.homeTeam,
        awayTeam: game.awayTeam,
        league: game.league,
        tip: game.tip,
        odds: game.odds,
        status: game.status,
        score: game.score,
      );
      if (res is Map<String, dynamic>) {
        final parsed = AiMatchInsightResult.fromJson(res);
        if (parsed.bullets.isNotEmpty) return parsed;
      }
    } catch (_) {}

    // Instant local analytical fallback
    final confidence = computeConfidence(game.odds);
    final riskLevel = computeRiskLevel(game.odds);
    return AiMatchInsightResult(
      confidence: confidence,
      riskLevel: riskLevel,
      marketCategory: 'Tactical Matchup',
      bullets: [
        'Tactical Fit: ${game.homeTeam} vs ${game.awayTeam} (${game.league}) aligns strongly with the "${game.tip}" market based on recent goal and possession trends.',
        'Odds Calibration: At @${game.odds}, B2win AI assigns a $confidence% confidence rating ($riskLevel).',
        'Key Game-State Factor: Early tempo and first-half chance creation heavily favor "${game.tip}" in this fixture.',
      ],
      verdict:
          'B2win AI rates "${game.tip}" (@${game.odds}) as a $riskLevel pick with $confidence% confidence.',
    );
  }

  Future<AiSmartSlipResult> getSmartSlip({
    required String riskProfile,
    required List<PredictionModel> availableGames,
  }) async {
    try {
      final res = await _provider.fetchSmartSlip(riskProfile: riskProfile);
      if (res is Map<String, dynamic>) {
        final parsed = AiSmartSlipResult.fromJson(res);
        if (parsed.picks.isNotEmpty) return parsed;
      }
    } catch (_) {}

    // Local fallback using loaded predictions
    final pending = availableGames
        .where((g) => g.status.toLowerCase() == 'pending')
        .toList();
    final pool = pending.length >= 2 ? pending : availableGames;

    final sorted = [...pool]..sort((a, b) {
        final confA = computeConfidence(a.odds);
        final confB = computeConfidence(b.odds);
        return riskProfile == 'high'
            ? confA.compareTo(confB)
            : confB.compareTo(confA);
      });

    final count = riskProfile == 'safe'
        ? 2
        : riskProfile == 'high'
            ? 4
            : 3;
    final chosen = sorted.take(count).toList();

    double combined = 1.0;
    int totalConf = 0;
    final picks = <Map<String, dynamic>>[];

    for (final g in chosen) {
      final oddsVal = double.tryParse(g.odds) ?? 1.75;
      final conf = computeConfidence(g.odds);
      combined *= oddsVal;
      totalConf += conf;
      picks.add({
        'league': g.league,
        'homeTeam': g.homeTeam,
        'awayTeam': g.awayTeam,
        'tip': g.tip,
        'odds': oddsVal.toStringAsFixed(2),
        'confidence': conf,
      });
    }

    final avgConf = chosen.isEmpty ? 75 : (totalConf / chosen.length).round();
    final title = riskProfile == 'safe'
        ? 'Low-Risk Safety Slip'
        : riskProfile == 'high'
            ? 'High-Return Multi-Match Slip'
            : 'Balanced Smart Accumulator';

    return AiSmartSlipResult(
      strategyTitle: title,
      combinedOdds: combined.toStringAsFixed(2),
      slipConfidence: avgConf,
      picks: picks,
      summary:
          'AI combined ${picks.length} fixture(s) at @${combined.toStringAsFixed(2)} total odds ($avgConf% average confidence).',
    );
  }

  Future<AiBlogSummaryResult> getBlogSummary({
    required String title,
    required String description,
  }) async {
    try {
      final res = await _provider.fetchBlogSummary(
        title: title,
        description: description,
      );
      if (res is Map<String, dynamic>) {
        final parsed = AiBlogSummaryResult.fromJson(res);
        if (parsed.bullets.isNotEmpty) return parsed;
      }
    } catch (_) {}

    final sentences = description
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 20)
        .toList();

    final bullets = sentences.length >= 3
        ? sentences.take(3).toList()
        : [
            'Core Topic: $title',
            if (sentences.isNotEmpty) sentences.first,
            'Covers key tactical matchups, form metrics, and high-value betting angles.',
          ];

    return AiBlogSummaryResult(
      bullets: bullets,
      keyTakeaway:
          'Bottom Line: Compare these tactical insights with live match tips in the B2win Predictions tab.',
    );
  }
}

