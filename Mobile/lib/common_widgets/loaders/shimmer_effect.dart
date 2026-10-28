import 'package:flutter/material.dart';

class TShimmerEffect extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final Color? color;

  const TShimmerEffect({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8.0,
    this.color,
  });

  @override
  State<TShimmerEffect> createState() => _TShimmerEffectState();
}

class _TShimmerEffectState extends State<TShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.color ?? (isDark ? const Color(0xFF2C2C38) : Colors.grey.shade300);
    final highlightColor = isDark ? const Color(0xFF3E3E4E) : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}
