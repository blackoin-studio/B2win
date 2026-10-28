import 'package:b2win/common_widgets/loaders/empty_state_widget.dart';
import 'package:b2win/common_widgets/loaders/match_card_shimmer.dart';
import 'package:b2win/constants/api_config.dart';
import 'package:b2win/data/models/prediction_model.dart';
import 'package:b2win/features/core/controllers/prediction_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key});

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
        return const Icon(Icons.access_time_filled, color: Colors.orange, size: 20);
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
        // Search & Filter Bar
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
                    children: filters.map((f) {
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
                    }).toList(),
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
              onRefresh: () => controller.fetchGameData(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: visibleGames.length,
                itemBuilder: (context, index) {
                  final PredictionModel game = visibleGames[index];

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
                                    _buildNetworkImage(game.leagueLogo, size: 24),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                                '${game.time} • ${game.status.toUpperCase()}',
                                style: const TextStyle(fontSize: 13),
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
                              Text(
                                'Odds: ${game.odds}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
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
      ],
    );
  }
}
