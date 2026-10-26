import 'package:flutter/material.dart';

/// Ultra-smooth pure-Flutter shimmer animation wrapper
class ShimmerAnimation extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerAnimation({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE2E8F0),
    this.highlightColor = const Color(0xFFF8FAFC),
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            if (bounds.width == 0 || bounds.height == 0) {
              return const LinearGradient(
                colors: [Colors.transparent, Colors.transparent],
              ).createShader(bounds);
            }
            final offset = -2.0 + (_controller.value * 4.0);
            return LinearGradient(
              begin: Alignment(offset - 1.0, -0.3),
              end: Alignment(offset + 1.0, 0.3),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Generic rounded skeleton box
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
      ),
    );
  }
}

/// Skeleton loading layout tailored for the Home Screen
/// Matches modern Phone B skeleton architecture
class HomeSkeletonLoader extends StatelessWidget {
  final double heroImageHeight;
  final double cardVerticalPadding;
  final double cardGap;
  final double sectionGap;

  const HomeSkeletonLoader({
    super.key,
    this.heroImageHeight = 200,
    this.cardVerticalPadding = 16,
    this.cardGap = 10,
    this.sectionGap = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerAnimation(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // 1. Companion Hero Section Skeleton
            SkeletonBox(
              width: double.infinity,
              height: heroImageHeight,
              borderRadius: 20,
            ),
            const SizedBox(height: 10),

            // Pagination Dots Indicator Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SkeletonBox(width: 18, height: 5, borderRadius: 3),
                SizedBox(width: 5),
                SkeletonBox(width: 6, height: 5, borderRadius: 3),
                SizedBox(width: 5),
                SkeletonBox(width: 6, height: 5, borderRadius: 3),
              ],
            ),
            const SizedBox(height: 12),

            // Title Line Skeleton
            const SkeletonBox(
              width: 220,
              height: 18,
              borderRadius: 6,
            ),
            const SizedBox(height: 8),

            // Description Lines Skeleton
            const SkeletonBox(
              width: double.infinity,
              height: 12,
              borderRadius: 4,
            ),
            const SizedBox(height: 6),
            const SkeletonBox(
              width: 240,
              height: 12,
              borderRadius: 4,
            ),
            const SizedBox(height: 14),

            // Hero CTA Button Skeleton
            const SkeletonBox(
              width: double.infinity,
              height: 52,
              borderRadius: 16,
            ),
            SizedBox(height: sectionGap),

            // 2. Journey Section Title Skeleton
            const SkeletonBox(
              width: 170,
              height: 17,
              borderRadius: 6,
            ),
            const SizedBox(height: 12),

            // 3. Journey Action Card 1 Skeleton
            _buildJourneyCardSkeleton(),
            SizedBox(height: cardGap),

            // 4. Journey Action Card 2 Skeleton
            _buildJourneyCardSkeleton(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyCardSkeleton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: cardVerticalPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icon Container Placeholder
          const SkeletonBox(
            width: 42,
            height: 42,
            borderRadius: 12,
          ),
          const SizedBox(width: 14),
          // Text Lines Placeholder
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                SkeletonBox(
                  width: 130,
                  height: 14,
                  borderRadius: 4,
                ),
                SizedBox(height: 6),
                SkeletonBox(
                  width: double.infinity,
                  height: 11,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Chevron Placeholder
          const SkeletonBox(
            width: 18,
            height: 18,
            shape: BoxShape.circle,
          ),
        ],
      ),
    );
  }
}
