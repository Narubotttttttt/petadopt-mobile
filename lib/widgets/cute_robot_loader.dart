import 'package:flutter/material.dart';
import 'package:mobile_petadopt/widgets/pet_recommendation_loader.dart';

export 'package:mobile_petadopt/widgets/pet_recommendation_loader.dart';

/// Backward-compatibility alias for PetRecommendationLoader
class CuteRobotLoader extends StatelessWidget {
  final double size;
  final Color headColor;
  final Color eyeColor;
  final bool withShadow;
  final bool onlyBlink;

  const CuteRobotLoader({
    super.key,
    this.size = 130,
    this.headColor = const Color(0xFF1E293B),
    this.eyeColor = const Color(0xFF1E293B),
    this.withShadow = true,
    this.onlyBlink = false,
  });

  @override
  Widget build(BuildContext context) {
    return PetRecommendationLoader(
      size: size,
      color: headColor == const Color(0xFF199CA4) ? const Color(0xFF1E293B) : headColor,
      withShadow: withShadow,
      onlyBlink: onlyBlink,
    );
  }
}

/// Backward-compatibility alias for PetRecommendationIcon
class CuteRobotIcon extends StatelessWidget {
  final double size;
  final Color headColor;
  final Color eyeColor;

  const CuteRobotIcon({
    super.key,
    this.size = 38,
    this.headColor = const Color(0xFF1E293B),
    this.eyeColor = const Color(0xFF1E293B),
  });

  @override
  Widget build(BuildContext context) {
    return PetRecommendationIcon(
      size: size,
      color: headColor == const Color(0xFF199CA4) ? const Color(0xFF1E293B) : headColor,
    );
  }
}
