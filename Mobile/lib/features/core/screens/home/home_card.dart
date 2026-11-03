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
import 'package:b2win/features/core/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

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

  bool _isVipPrediction(PredictionModel game) =>
      game.tip.trim().toUpperCase().startsWith('[VIP]');

  String _cleanVipTip(String tip) =>
      tip.replaceFirst(RegExp(r'^\[VIP\]\s*', caseSensitive: false), '').trim();

  void _showVipUnlockDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.workspace_premium, color: Colors.amberAccent, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Unlock VIP Predictions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'This pick is reserved for B2WIN VIP Pass holders. Activate your free 24-hour Ad-Supported VIP Pass now to unlock all VIP picks!',
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    if (Get.isRegistered<AdController>()) {
                      Get.find<AdController>()
                          .recordInteractionAndMaybeShowInterstitial();
                    }
                    if (Get.isRegistered<ProfileController>()) {
                      await Get.find<ProfileController>().unlockVipPass();
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.lock_open_rounded),
                  label: const Text(
                    'Activate 24h VIP Pass (Free)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final GameController controller = Get.find<GameController>();
    final ProfileController? profileController =
        Get.isRegistered<ProfileController>()
            ? Get.find<ProfileController>()
            : null;
    const filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'pending', 'label': 'Pending'},
      {'id': 'won', 'label': 'Won'},
      {'id': 'lost', 'label': 'Lost'},
      {'id': 'saved', 'label': 'Saved'},
    ];

    return Column(
      children: [
        // Live Win-Rate & Tipster Accuracy Analytics Banner
        Obx(() {
          if (controller.games.isEmpty) return const SizedBox.shrink();
          final settled = controller.wonCount + controller.lostCount;
          final winRate = controller.winRatePercent;
          final form = controller.recentSettledForm;

          return Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF292938),
                  Colors.orange.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: Text(
                        settled > 0 ? '$winRate% WIN' : 'LIVE TIPS',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Won: ${controller.wonCount} • Pending: ${controller.pendingCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        Text(
                          '${controller.games.length} Total Tracked Picks',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (form.isNotEmpty)
                  Row(
                    children: form
                        .map(
                          (f) => Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: f == 'W'
                                  ? Colors.green
                                  : Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              f,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          );
        }),

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
                        final label = f['id'] == 'saved'
                            ? 'Saved (${controller.savedIds.length})'
                            : f['label']!;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(label),
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

        // Saved Slip Summary Banner when 'saved' filter is selected
        Obx(() {
          if (controller.selectedStatus.value != 'saved' ||
              controller.savedIds.isEmpty) {
            return const SizedBox.shrink();
          }
          final combinedOdds = controller.savedCombinedOdds;
          final savedGames = controller.games
              .where((g) => controller.savedIds.contains(GameController.gameKey(g)))
              .toList();
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Saved Slip (${savedGames.length} Picks)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      'Combined Odds: @$combinedOdds',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    final lines = savedGames
                        .map(
                          (g) =>
                              '⚽ ${g.homeTeam} vs ${g.awayTeam} (${g.league}) — Tip: ${_cleanVipTip(g.tip)} @${g.odds}',
                        )
                        .join('\n');
                    Share.share(
                      '🔥 My B2WIN Accumulator Slip (@$combinedOdds):\n$lines\n\nDownload B2WIN on Google Play!',
                    );
                  },
                  icon: const Icon(Icons.share, size: 16, color: Colors.amberAccent),
                  label: const Text(
                    'Share Slip',
                    style: TextStyle(color: Colors.amberAccent),
                  ),
                ),
              ],
            ),
          );
        }),

        // Predictions List
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const MatchCardShimmer();
            }

            final visibleGames = controller.filteredGames;
            final isVipUnlocked = (profileController?.isVipActive.value ?? false) ||
                (profileController?.currentUser.value?.isAdmin ?? false);

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
                  final String gameKey = GameController.gameKey(game);
                  final int aiConfidence =
                      AiRepository.computeConfidence(game.odds);
                  final bool isVip = _isVipPrediction(game);
                  final bool isLockedVip = isVip && !isVipUnlocked;
                  final bool isSaved = controller.savedIds.contains(gameKey);

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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatDate(game.date),
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => controller.toggleSaved(gameKey),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Icon(
                                        isSaved
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        size: 20,
                                        color: isSaved
                                            ? Colors.amberAccent
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      final tipText = isLockedVip
                                          ? 'VIP Pick'
                                          : _cleanVipTip(game.tip);
                                      Share.share(
                                        '⚽ ${game.homeTeam} vs ${game.awayTeam} (${game.league})\n🎯 B2WIN Tip: $tipText (@${game.odds}) • $aiConfidence% AI Confidence\n📲 Get more tips on B2WIN!',
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(
                                        Icons.share_outlined,
                                        size: 19,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
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
                              if (isLockedVip)
                                GestureDetector(
                                  onTap: () => _showVipUnlockDialog(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6.0,
                                      horizontal: 12.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.lock,
                                          size: 14,
                                          color: Colors.black,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'VIP Tip — Tap to Unlock',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                    horizontal: 12.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isVip ? Colors.amber : Colors.orange,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Text(
                                    isVip
                                        ? '👑 VIP: ${_cleanVipTip(game.tip)}'
                                        : 'Tip: ${game.tip}',
                                    style: TextStyle(
                                      color: isVip ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => isLockedVip
                                        ? _showVipUnlockDialog(context)
                                        : _showAiMatchInsightSheet(
                                            context,
                                            game,
                                          ),
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
