import 'package:b2win/common_widgets/loaders/shimmer_effect.dart';
import 'package:flutter/material.dart';

class BlogCardShimmer extends StatelessWidget {
  final int itemCount;

  const BlogCardShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF292938),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: TShimmerEffect(
                  width: double.infinity,
                  height: 200,
                  radius: 0,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TShimmerEffect(width: 200, height: 18),
                    SizedBox(height: 10),
                    TShimmerEffect(width: 80, height: 14),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
