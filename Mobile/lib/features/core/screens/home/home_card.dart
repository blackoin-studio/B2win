import 'package:b2win/constants/api_config.dart';
import 'package:intl/intl.dart';
import 'package:b2win/features/core/controllers/prediction_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:core';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key});

  @override
  Widget build(BuildContext context) {
    final GameController controller = Get.put(GameController());
    
    final format = DateFormat('yyyy-MM-dd');

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.games.isEmpty) {
        return const Center(child: Text('No available Predictions'));
      }

      return ListView.builder(
        itemCount: controller.games.length,
        itemBuilder: (context, index) {
          final game = controller.games[index];

          return Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.network(
                            '$imageUrl/${game['leagueLogo']}',
                            width: 24,
                            height: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.image_not_supported,
                              size: 24,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            game['league'] ?? 'Unknown League',
                            style: const TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(

                        format.parse(game['date']).toString().substring(0,10),
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Image.network(
                            '$imageUrl/${game['awayLogo']}',
                            width: 30,
                            height: 30,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.image_not_supported,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                          Text(game['awayTeam'] ?? 'Away Team'),
                        ],
                      ),
                      Text(
                        game['score'] ?? '-',
                        style: const TextStyle(fontSize: 24.0),
                      ),
                      Column(
                        children: [
                          Image.network(
                            '$imageUrl/${game['homeLogo']}',
                            width: 30,
                            height: 30,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.image_not_supported,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                          Text(game['homeTeam'] ?? 'Home Team'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      statusFinder(game),
                      const SizedBox(width: 4),
                      Text(game['time'] ?? 'Unknown Time'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      game['tip'] ?? 'No Tip',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    game['odds'] ?? '0.0',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18.0),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  statusFinder(game) {
    return game['status'].toString() == 'won'
        ? const Icon(Icons.check, color: Colors.green)
        : game['status'].toString() == 'lost'
            ? const Icon(Icons.close, color: Colors.red)
            : const Icon(Icons.access_time, color: Colors.orange);
  }
}
