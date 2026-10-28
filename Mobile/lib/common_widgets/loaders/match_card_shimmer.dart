import 'package:b2win/common_widgets/loaders/shimmer_effect.dart';
import 'package:flutter/material.dart';

class MatchCardShimmer extends StatelessWidget {
  final int itemCount;

  const MatchCardShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // League & Date Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        TShimmerEffect(width: 24, height: 24, radius: 12),
                        SizedBox(width: 8),
                        TShimmerEffect(width: 110, height: 16),
                      ],
                    ),
                    TShimmerEffect(width: 70, height: 16),
                  ],
                ),
                SizedBox(height: 16),
                // Teams & Score Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        TShimmerEffect(width: 32, height: 32, radius: 16),
                        SizedBox(height: 6),
                        TShimmerEffect(width: 60, height: 14),
                      ],
                    ),
                    TShimmerEffect(width: 40, height: 24),
                    Column(
                      children: [
                        TShimmerEffect(width: 32, height: 32, radius: 16),
                        SizedBox(height: 6),
                        TShimmerEffect(width: 60, height: 14),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 14),
                // Time & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TShimmerEffect(width: 16, height: 16, radius: 8),
                    SizedBox(width: 6),
                    TShimmerEffect(width: 50, height: 14),
                  ],
                ),
                SizedBox(height: 10),
                // Tip pill
                TShimmerEffect(width: 80, height: 26, radius: 20),
                SizedBox(height: 10),
                // Odds
                TShimmerEffect(width: 45, height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
