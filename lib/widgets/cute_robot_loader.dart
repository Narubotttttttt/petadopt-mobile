import 'dart:math' as math;
import 'package:flutter/material.dart';

class CuteRobotLoader extends StatefulWidget {
  final double size;
  final Color headColor;
  final Color eyeColor;
  final bool withShadow;
  final bool onlyBlink; // If true: eyes stay centered and only blink naturally

  const CuteRobotLoader({
    super.key,
    this.size = 130,
    this.headColor = const Color(0xFF199CA4), // CAWS Theme Primary Teal
    this.eyeColor = const Color(0xFFFFFFFF),
    this.withShadow = true,
    this.onlyBlink = false,
  });

  @override
  State<CuteRobotLoader> createState() => _CuteRobotLoaderState();
}

class _CuteRobotLoaderState extends State<CuteRobotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.onlyBlink ? 3200 : 4000),
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
        final t = _controller.value;

        // 1. Float animation (disabled in onlyBlink mode)
        final headFloat = widget.onlyBlink
            ? 0.0
            : math.sin(t * 2 * math.pi) * (widget.size * 0.035);

        // 2. Blink animation
        double eyeScaleY = 1.0;
        if (widget.onlyBlink) {
          // Clean, natural blink for icon
          if (t >= 0.88 && t < 0.92) {
            eyeScaleY = 1.0 - ((t - 0.88) / 0.04) * 0.92;
          } else if (t >= 0.92 && t < 0.96) {
            eyeScaleY = 0.08 + ((t - 0.92) / 0.04) * 0.92;
          }
        } else {
          // Full scanning mode blinking for loading screen
          if (t >= 0.10 && t < 0.12) {
            eyeScaleY = 1.0 - ((t - 0.10) / 0.02) * 0.92;
          } else if (t >= 0.12 && t < 0.14) {
            eyeScaleY = 0.08 + ((t - 0.12) / 0.02) * 0.92;
          } else if (t >= 0.82 && t < 0.84) {
            eyeScaleY = 1.0 - ((t - 0.82) / 0.02) * 0.92;
          } else if (t >= 0.84 && t < 0.86) {
            eyeScaleY = 0.08 + ((t - 0.84) / 0.02) * 0.92;
          }
        }

        // 3. Eye Movement (disabled in onlyBlink mode)
        double eyeOffsetX = 0.0;
        double eyeOffsetY = 0.0;

        if (!widget.onlyBlink) {
          final maxShiftX = widget.size * 0.13;
          final maxShiftY = widget.size * 0.085;

          if (t < 0.18) {
            eyeOffsetX = 0;
            eyeOffsetY = 0;
          } else if (t < 0.24) {
            final p = (t - 0.18) / 0.06;
            eyeOffsetX = -maxShiftX * Curves.easeInOut.transform(p);
          } else if (t < 0.34) {
            eyeOffsetX = -maxShiftX;
          } else if (t < 0.42) {
            final p = (t - 0.34) / 0.08;
            eyeOffsetX = -maxShiftX + (maxShiftX * 2) * Curves.easeInOut.transform(p);
          } else if (t < 0.52) {
            eyeOffsetX = maxShiftX;
          } else if (t < 0.60) {
            final p = (t - 0.52) / 0.08;
            eyeOffsetX = maxShiftX * (1 - Curves.easeInOut.transform(p));
            eyeOffsetY = -maxShiftY * Curves.easeInOut.transform(p);
          } else if (t < 0.70) {
            eyeOffsetY = -maxShiftY;
          } else if (t < 0.76) {
            final p = (t - 0.70) / 0.06;
            eyeOffsetY = -maxShiftY + (maxShiftY * 1.8) * Curves.easeInOut.transform(p);
          } else if (t < 0.82) {
            eyeOffsetY = maxShiftY * 0.8;
          } else if (t < 0.88) {
            final p = (t - 0.82) / 0.06;
            eyeOffsetY = (maxShiftY * 0.8) * (1 - Curves.easeInOut.transform(p));
          } else {
            eyeOffsetX = 0;
            eyeOffsetY = 0;
          }
        }

        final headWidth = widget.size;
        final headHeight = widget.size * 0.92;
        final eyeWidth = widget.size * 0.18;
        final eyeHeight = widget.size * 0.27;
        final eyeGap = widget.size * 0.14;

        return Transform.translate(
          offset: Offset(0, headFloat),
          child: Container(
            width: headWidth,
            height: headHeight,
            decoration: BoxDecoration(
              color: widget.headColor,
              borderRadius: BorderRadius.circular(widget.size * 0.28),
              boxShadow: widget.withShadow && widget.size > 40
                  ? [
                      BoxShadow(
                        color: widget.headColor.withValues(alpha: 0.35),
                        blurRadius: widget.size * 0.14,
                        offset: Offset(0, widget.size * 0.06),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated Eyes
                Transform.translate(
                  offset: Offset(eyeOffsetX, eyeOffsetY),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildEye(eyeWidth, eyeHeight, eyeScaleY),
                      SizedBox(width: eyeGap),
                      _buildEye(eyeWidth, eyeHeight, eyeScaleY),
                    ],
                  ),
                ),
                // Cute soft blush cheeks (subtle details for icon & loader)
                if (widget.size >= 36)
                  Positioned(
                    bottom: headHeight * 0.18,
                    left: headWidth * 0.12,
                    right: headWidth * 0.12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: widget.size * 0.12,
                          height: widget.size * 0.045,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: widget.size * 0.12,
                          height: widget.size * 0.045,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEye(double width, double height, double scaleY) {
    return Transform.scale(
      scaleY: scaleY,
      alignment: Alignment.center,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: widget.eyeColor,
          borderRadius: BorderRadius.circular(width * 0.5),
          boxShadow: [
            BoxShadow(
              color: widget.eyeColor.withValues(alpha: 0.6),
              blurRadius: math.max(2.0, width * 0.3),
            ),
          ],
        ),
        child: (scaleY > 0.4 && widget.size >= 28)
            ? Align(
                alignment: const Alignment(0.45, -0.55),
                child: Container(
                  width: width * 0.28,
                  height: width * 0.28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// Animated Cute Robot Icon for banners and buttons (Blinking only, Theme Teal by default)
class CuteRobotIcon extends StatelessWidget {
  final double size;
  final Color headColor;
  final Color eyeColor;

  const CuteRobotIcon({
    super.key,
    this.size = 38,
    this.headColor = const Color(0xFF199CA4), // Theme Teal
    this.eyeColor = const Color(0xFFFFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return CuteRobotLoader(
      size: size,
      headColor: headColor,
      eyeColor: eyeColor,
      withShadow: false,
      onlyBlink: true,
    );
  }
}
