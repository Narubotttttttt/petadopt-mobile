import 'package:flutter/material.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

/// Ultra-smooth pure-Flutter shimmer animation wrapper
class ShimmerAnimation extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerAnimation({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
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
    final isDark = AppTheme.isDark(context);
    final effectiveBase = widget.baseColor ??
        (isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0));
    final effectiveHighlight = widget.highlightColor ??
        (isDark ? const Color(0xFF38475C) : const Color(0xFFF8FAFC));

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
                effectiveBase,
                effectiveHighlight,
                effectiveBase,
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
  final Color? color;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? (isDark ? const Color(0xFF222F43) : const Color(0xFFE2E8F0)),
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
            _buildJourneyCardSkeleton(context),
            SizedBox(height: cardGap),

            // 4. Journey Action Card 2 Skeleton
            _buildJourneyCardSkeleton(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyCardSkeleton(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: cardVerticalPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
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

/// Skeleton loading layout tailored for the My Applications screen
class ApplicationsSkeletonLoader extends StatelessWidget {
  final int itemCount;

  const ApplicationsSkeletonLoader({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = AppTheme.getBackgroundColor(context);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Filter Tabs Skeleton
          Container(
            width: double.infinity,
            color: bgColor,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: ShimmerAnimation(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: const [
                    SkeletonBox(width: 52, height: 28, borderRadius: 20),
                    SizedBox(width: 8),
                    SkeletonBox(width: 86, height: 28, borderRadius: 20),
                    SizedBox(width: 8),
                    SkeletonBox(width: 114, height: 28, borderRadius: 20),
                    SizedBox(width: 8),
                    SkeletonBox(width: 80, height: 28, borderRadius: 20),
                  ],
                ),
              ),
            ),
          ),

          // Application Cards Skeleton List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 105),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildApplicationCardSkeleton(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCardSkeleton(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getCardBorder(context)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      padding: const EdgeInsets.all(14),
      child: ShimmerAnimation(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Pet Image, Info, and Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(
                  width: 58,
                  height: 58,
                  borderRadius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          SkeletonBox(width: 105, height: 16, borderRadius: 4),
                          SkeletonBox(width: 68, height: 20, borderRadius: 20),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: const [
                          SkeletonBox(width: 72, height: 12, borderRadius: 4),
                          SizedBox(width: 8),
                          SkeletonBox(width: 90, height: 16, borderRadius: 6),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const SkeletonBox(width: 110, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Stepper / Tracker Section Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 0.9,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SkeletonBox(width: 120, height: 10, borderRadius: 3),
                      SkeletonBox(width: 55, height: 10, borderRadius: 3),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4-Step Tracker Stepper
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SkeletonBox(width: 18, height: 18, shape: BoxShape.circle),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: SkeletonBox(height: 2, borderRadius: 1),
                        ),
                      ),
                      SkeletonBox(width: 18, height: 18, shape: BoxShape.circle),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: SkeletonBox(height: 2, borderRadius: 1),
                        ),
                      ),
                      SkeletonBox(width: 18, height: 18, shape: BoxShape.circle),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: SkeletonBox(height: 2, borderRadius: 1),
                        ),
                      ),
                      SkeletonBox(width: 18, height: 18, shape: BoxShape.circle),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Step Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SkeletonBox(width: 44, height: 8, borderRadius: 2),
                      SkeletonBox(width: 38, height: 8, borderRadius: 2),
                      SkeletonBox(width: 44, height: 8, borderRadius: 2),
                      SkeletonBox(width: 40, height: 8, borderRadius: 2),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status Message Banner Placeholder
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFFDE68A).withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: const [
                        SkeletonBox(width: 14, height: 14, shape: BoxShape.circle),
                        SizedBox(width: 8),
                        Expanded(
                          child: SkeletonBox(height: 10, borderRadius: 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading layout tailored for the Application Notifications Modal
class NotificationsModalSkeletonLoader extends StatelessWidget {
  final int itemCount;

  const NotificationsModalSkeletonLoader({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: ShimmerAnimation(
            child: Row(
              children: [
                const SkeletonBox(
                  width: 38,
                  height: 38,
                  borderRadius: 10,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 140, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      SkeletonBox(width: double.infinity, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const SkeletonBox(
                  width: 62,
                  height: 20,
                  borderRadius: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
