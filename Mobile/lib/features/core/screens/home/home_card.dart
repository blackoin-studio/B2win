import 'package:b2win/common_widgets/ads/dynamic_banner_ad_widget.dart';
import 'package:b2win/common_widgets/loaders/empty_state_widget.dart';
import 'package:b2win/common_widgets/loaders/match_card_shimmer.dart';
import 'package:b2win/constants/api_config.dart';
import 'package:b2win/core/network/api_client.dart';
import 'package:b2win/data/models/prediction_model.dart';
import 'package:b2win/data/providers/ai_provider.dart';
import 'package:b2win/data/repositories/ai_repository.dart';
import 'package:b2win/features/core/controllers/ad_controller.dart';
import 'package:b2win/features/core/controllers/prediction_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key});

  AiRepository _resolveAiRepo() {
    if (Get.isRegistered<AiRepository>()) {
      return Get.find<AiRepository>();
    }
    return AiRepository(provider: AiProvider(apiClient: ApiClient()));
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    }
  }

  Widget _buildStatusIndicator(String status) {
    switch (status.toLowerCase()) {
      case 'won':
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case 'lost':
        return const Icon(Icons.cancel, color: Colors.red, size: 20);
      default:
        return const Icon(
          Icons.access_time_filled,
          color: Colors.orange,
          size: 20,
        );
    }
  }

  Widget _buildNetworkImage(String? path, {double size = 30}) {
    final resolvedUrl = resolveMediaUrl(path);
    if (resolvedUrl.isEmpty) {
      return Icon(Icons.shield_outlined, size: size, color: Colors.grey);
    }
    return Image.network(
      resolvedUrl,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.shield_outlined,
        size: size,
        color: Colors.grey,
      ),
    );
  }

  void _showAiMatchInsightSheet(BuildContext context, PredictionModel game) {
    final aiRepo = _resolveAiRepo();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FutureBuilder<AiMatchInsightResult>(
          future: aiRepo.getMatchInsight(game),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.redAccent),
                    SizedBox(height: 16),
                    Text(
                      'B2win AI is analyzing tactical matchup & odds...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            }

            final insight = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.amberAccent,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'B2win AI Match Insight',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.greenAccent),
                          ),
                          child: Text(
                            '${insight.confidence}% Confidence',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${game.homeTeam} vs ${game.awayTeam} • ${game.league}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          backgroundColor: Colors.orange.withValues(alpha: 0.2),
                          label: Text(
                            'Tip: ${game.tip} (@${game.odds})',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Chip(
                          backgroundColor: Colors.blueGrey.withValues(alpha: 0.25),
                          label: Text(
                            insight.riskLevel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 22),
                    ...insight.bullets.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                b,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (insight.verdict.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          insight.verdict,
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAiSmartSlipSheet(
    BuildContext context,
    List<PredictionModel> allGames,
  ) {
    final aiRepo = _resolveAiRepo();
    final RxString selectedRisk = 'balanced'.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Obx(() {
            final risk = selectedRisk.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.amberAccent,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Smart Slip Builder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose your target risk profile and B2win AI will combine the best fixtures:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final item in const [
                      {'id': 'safe', 'label': 'Safe (2 Picks)'},
                      {'id': 'balanced', 'label': 'Balanced (3 Picks)'},
                      {'id': 'high', 'label': 'High Return'},
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(item['label']!),
                          selected: risk == item['id'],
                          onSelected: (_) => selectedRisk.value = item['id']!,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                FutureBuilder<AiSmartSlipResult>(
                  key: ValueKey(risk),
                  future: aiRepo.getSmartSlip(
                    riskProfile: risk,
                    availableGames: allGames,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(28.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.amberAccent,
                          ),
                        ),
                      );
                    }
                    final slip = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.amberAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slip.strategyTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${slip.slipConfidence}% Avg AI Confidence',
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '@${slip.combinedOdds}',
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...slip.picks.map(
                          (pick) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${pick['homeTeam']} vs ${pick['awayTeam']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${pick['league']} • Tip: ${pick['tip']}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '@${pick['odds']}',
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final GameController controller = Get.find<GameController>();
    const filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'pending', 'label': 'Pending'},
      {'id': 'won', 'label': 'Won'},
      {'id': 'lost', 'label': 'Lost'},
    ];

    return Column(
      children: [
        // Search & Filter Bar + AI Smart Slip Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                onChanged: controller.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search team, league, or tip...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...filters.map((f) {
                        final isSelected =
                            controller.selectedStatus.value == f['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(f['label']!),
                            selected: isSelected,
                            onSelected: (_) =>
                                controller.setStatusFilter(f['id']!),
                          ),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.amberAccent,
                        ),
                        backgroundColor: const Color(0xFF292938),
                        label: const Text(
                          'AI Smart Slip',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () =>
                            _showAiSmartSlipSheet(context, controller.games),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Predictions List
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const MatchCardShimmer();
            }

            final visibleGames = controller.filteredGames;

            if (visibleGames.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => controller.fetchGameData(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 40),
                    EmptyStateWidget(
                      icon: Icons.sports_soccer_outlined,
                      title: 'No Predictions Found',
                      subtitle:
                          'Try changing the status filter or pull to refresh.',
                      actionButtonText: 'Refresh',
                      onRetry: () => controller.fetchGameData(),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (Get.isRegistered<AdController>()) {
                  Get.find<AdController>().fetchAdSettings();
                }
                await controller.fetchGameData();
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                itemCount: visibleGames.length,
                itemBuilder: (context, index) {
                  final PredictionModel game = visibleGames[index];
                  final int aiConfidence =
                      AiRepository.computeConfidence(game.odds);

                  return Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    _buildNetworkImage(
                                      game.leagueLogo,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        game.league,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatDate(game.date),
                                style: const TextStyle(fontSize: 13.0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildNetworkImage(game.homeLogo, size: 34),
                                    const SizedBox(height: 6),
                                    Text(
                                      game.homeTeam,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  game.score,
                                  style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildNetworkImage(game.awayLogo, size: 34),
                                    const SizedBox(height: 6),
                                    Text(
                                      game.awayTeam,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStatusIndicator(game.status),
                              const SizedBox(width: 6),
                              Text(
                                '${game.time} • ${game.status.toUpperCase()} • $aiConfidence% AI Confidence',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                  horizontal: 12.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Text(
                                  'Tip: ${game.tip}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () =>
                                        _showAiMatchInsightSheet(context, game),
                                    icon: const Icon(
                                      Icons.auto_awesome,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                    label: const Text(
                                      'AI Insight',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Odds: ${game.odds}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ),
        const DynamicBannerAdWidget(placement: 'home'),
      ],
    );
  }
}
