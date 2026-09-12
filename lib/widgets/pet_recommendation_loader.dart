import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Vector Custom Painter for the Peeking Cat Icon / Loader
class PeekingCatPainter extends CustomPainter {
  final Color strokeColor;
  final Color? fillColor;
  final Color? boxBackgroundColor;
  final double strokeWidthRatio;
  final double eyeOffsetX; // -1.0 to 1.0
  final double eyeOffsetY; // -1.0 to 1.0
  final double eyeScaleY; // 0.08 to 1.0 (for blinking)
  final double earWiggle; // subtle ear offset
  final double peekOffsetY; // bobbing/peeking offset

  PeekingCatPainter({
    required this.strokeColor,
    this.fillColor,
    this.boxBackgroundColor,
    this.strokeWidthRatio = 0.085,
    this.eyeOffsetX = 0.0,
    this.eyeOffsetY = 0.0,
    this.eyeScaleY = 1.0,
    this.earWiggle = 0.0,
    this.peekOffsetY = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double sw = s * strokeWidthRatio;
    final double halfSw = sw / 2.0;

    // Box rectangle and rounded corners
    final Rect boxRect = Rect.fromLTWH(halfSw, halfSw, s - sw, s - sw);
    final double cornerRadius = (s - sw) * 0.22;
    final RRect rrect = RRect.fromRectAndRadius(boxRect, Radius.circular(cornerRadius));

    // Paints
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = boxBackgroundColor ?? (fillColor ?? Colors.transparent)
      ..style = PaintingStyle.fill;

    final featurePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    // 1. Draw box background if provided
    if (boxBackgroundColor != null && boxBackgroundColor != Colors.transparent) {
      canvas.drawRRect(rrect, fillPaint);
    }

    // 2. Draw Cat inside the clipped box
    canvas.save();
    canvas.clipRRect(rrect);

    // Apply peek offset
    final double dy = peekOffsetY * s * 0.06;

    // Cat Outline Path
    final catPath = Path();
    // Bottom start: near middle-bottom
    catPath.moveTo(s * 0.43, (s * 0.96) + dy);

    // Left chest/cheek curve rising up
    catPath.cubicTo(
      s * 0.27, (s * 0.88) + dy,
      s * 0.21, (s * 0.68) + dy,
      s * 0.21, (s * 0.50) + dy,
    );

    // Left Ear: tip points up-left
    catPath.cubicTo(
      s * 0.20, (s * 0.42) + dy,
      s * 0.23, (s * 0.36 + earWiggle) + dy,
      s * 0.27, (s * 0.36 + earWiggle) + dy,
    );

    // Left Ear slope down to forehead
    catPath.lineTo(s * 0.38, (s * 0.48) + dy);

    // Forehead curve between ears
    catPath.quadraticBezierTo(
      s * 0.48, (s * 0.47) + dy,
      s * 0.58, (s * 0.44) + dy,
    );

    // Right Ear: rising to upper-right corner
    catPath.cubicTo(
      s * 0.65, (s * 0.38) + dy,
      s * 0.72, (s * 0.31) + dy,
      s * 0.76, (s * 0.31) + dy,
    );

    // Connect right ear into the right wall
    catPath.lineTo(s * 0.98, (s * 0.37) + dy);

    // Stroke the cat outline
    canvas.drawPath(catPath, strokePaint);

    // Cat Face Features
    // Left Eye (oval)
    final double leftEyeCenterX = s * 0.42 + (eyeOffsetX * s * 0.04);
    final double leftEyeCenterY = s * 0.61 + (eyeOffsetY * s * 0.03) + dy;
    final double eyeW = s * 0.088;
    final double eyeH = s * 0.115 * math.max(0.08, eyeScaleY);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(leftEyeCenterX, leftEyeCenterY),
        width: eyeW,
        height: eyeH,
      ),
      featurePaint,
    );

    // Right Eye (peeking along right inner border)
    final double rightEyeCenterX = s * 0.78 + (eyeOffsetX * s * 0.03);
    final double rightEyeCenterY = s * 0.58 + (eyeOffsetY * s * 0.03) + dy;
    final double rightEyeW = s * 0.082;
    final double rightEyeH = s * 0.108 * math.max(0.08, eyeScaleY);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rightEyeCenterX, rightEyeCenterY),
        width: rightEyeW,
        height: rightEyeH,
      ),
      featurePaint,
    );

    // Nose (small oval)
    final double noseCenterX = s * 0.57 + (eyeOffsetX * s * 0.02);
    final double noseCenterY = s * 0.68 + (eyeOffsetY * s * 0.02) + dy;
    final double noseW = s * 0.062;
    final double noseH = s * 0.052;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(noseCenterX, noseCenterY),
        width: noseW,
        height: noseH,
      ),
      featurePaint,
    );

    canvas.restore();

    // 3. Draw outer rounded box stroke
    canvas.drawRRect(rrect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant PeekingCatPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.boxBackgroundColor != boxBackgroundColor ||
        oldDelegate.strokeWidthRatio != strokeWidthRatio ||
        oldDelegate.eyeOffsetX != eyeOffsetX ||
        oldDelegate.eyeOffsetY != eyeOffsetY ||
        oldDelegate.eyeScaleY != eyeScaleY ||
        oldDelegate.earWiggle != earWiggle ||
        oldDelegate.peekOffsetY != peekOffsetY;
  }
}

/// Peeking Cat Recommendation Loader with rich multi-stage search animations
class PetRecommendationLoader extends StatefulWidget {
  final double size;
  final Color color;
  final Color? boxBackgroundColor;
  final bool withShadow;
  final bool onlyBlink; // If true: stays in place and periodically blinks (icon mode)
  final bool withSparkles; // Ambient smart-match sparkles around the box

  const PetRecommendationLoader({
    super.key,
    this.size = 130,
    this.color = const Color(0xFF1E293B), // Premium dark slate / black stroke
    this.boxBackgroundColor,
    this.withShadow = true,
    this.onlyBlink = false,
    this.withSparkles = true,
  });

  @override
  State<PetRecommendationLoader> createState() => _PetRecommendationLoaderState();
}

class _PetRecommendationLoaderState extends State<PetRecommendationLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.onlyBlink ? 3200 : 3800),
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

        // 1. Bobbing / peeking translation
        double peekOffsetY = 0.0;
        double floatY = 0.0;

        if (!widget.onlyBlink) {
          // Gentle floating motion
          floatY = math.sin(t * 2 * math.pi) * (widget.size * 0.025);
          // Inquisitive peek up around t = 0.3 to 0.7
          if (t >= 0.25 && t < 0.45) {
            final p = (t - 0.25) / 0.20;
            peekOffsetY = -math.sin(p * math.pi) * 0.15;
          }
        }

        // 2. Blinking animation
        double eyeScaleY = 1.0;
        if (widget.onlyBlink) {
          // Natural clean periodic blink
          if (t >= 0.88 && t < 0.92) {
            eyeScaleY = 1.0 - ((t - 0.88) / 0.04) * 0.92;
          } else if (t >= 0.92 && t < 0.96) {
            eyeScaleY = 0.08 + ((t - 0.92) / 0.04) * 0.92;
          }
        } else {
          // Multi-stage expressive blinking for loading screen
          if (t >= 0.08 && t < 0.11) {
            eyeScaleY = 1.0 - ((t - 0.08) / 0.03) * 0.92;
          } else if (t >= 0.11 && t < 0.14) {
            eyeScaleY = 0.08 + ((t - 0.11) / 0.03) * 0.92;
          } else if (t >= 0.78 && t < 0.81) {
            eyeScaleY = 1.0 - ((t - 0.78) / 0.03) * 0.92;
          } else if (t >= 0.81 && t < 0.84) {
            eyeScaleY = 0.08 + ((t - 0.81) / 0.03) * 0.92;
          }
        }

        // 3. Eye Movement (Scanning for pet matches)
        double eyeOffsetX = 0.0;
        double eyeOffsetY = 0.0;
        double earWiggle = 0.0;

        if (!widget.onlyBlink) {
          if (t < 0.18) {
            eyeOffsetX = 0.0;
            eyeOffsetY = 0.0;
          } else if (t < 0.26) {
            // Look left
            final p = (t - 0.18) / 0.08;
            eyeOffsetX = -1.0 * Curves.easeInOut.transform(p);
          } else if (t < 0.38) {
            eyeOffsetX = -1.0;
          } else if (t < 0.48) {
            // Pan smoothly across to look right
            final p = (t - 0.38) / 0.10;
            eyeOffsetX = -1.0 + 2.0 * Curves.easeInOut.transform(p);
          } else if (t < 0.58) {
            eyeOffsetX = 1.0;
            // Ear wiggle while looking right
            final wp = (t - 0.48) / 0.10;
            earWiggle = math.sin(wp * 4 * math.pi) * 0.02 * widget.size;
          } else if (t < 0.68) {
            // Look up
            final p = (t - 0.58) / 0.10;
            eyeOffsetX = 1.0 * (1.0 - Curves.easeInOut.transform(p));
            eyeOffsetY = -1.0 * Curves.easeInOut.transform(p);
          } else if (t < 0.78) {
            eyeOffsetY = -1.0;
          } else if (t < 0.86) {
            // Return to center
            final p = (t - 0.78) / 0.08;
            eyeOffsetY = -1.0 * (1.0 - Curves.easeInOut.transform(p));
          } else {
            eyeOffsetX = 0.0;
            eyeOffsetY = 0.0;
          }
        }

        Widget iconWidget = Transform.translate(
          offset: Offset(0, floatY),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.size * 0.22),
              boxShadow: widget.withShadow && widget.size > 40
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: widget.size * 0.16,
                        offset: Offset(0, widget.size * 0.08),
                      ),
                    ]
                  : null,
            ),
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: PeekingCatPainter(
                strokeColor: widget.color,
                boxBackgroundColor: widget.boxBackgroundColor,
                eyeOffsetX: eyeOffsetX,
                eyeOffsetY: eyeOffsetY,
                eyeScaleY: eyeScaleY,
                earWiggle: earWiggle,
                peekOffsetY: peekOffsetY,
              ),
            ),
          ),
        );

        if (!widget.withSparkles || widget.onlyBlink || widget.size < 60) {
          return iconWidget;
        }

        // Ambient AI Sparkles around loader
        return SizedBox(
          width: widget.size * 1.35,
          height: widget.size * 1.35,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Sparkle 1 (top-right)
              _buildSparkle(
                offset: Offset(widget.size * 0.50, -widget.size * 0.40),
                size: widget.size * 0.14,
                opacity: 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * 2 * math.pi)),
                scale: 0.8 + 0.4 * (0.5 + 0.5 * math.cos(t * 2 * math.pi)),
                color: const Color(0xFF0D9488),
              ),
              // Sparkle 2 (bottom-left)
              _buildSparkle(
                offset: Offset(-widget.size * 0.48, widget.size * 0.36),
                size: widget.size * 0.12,
                opacity: 0.3 + 0.7 * (0.5 + 0.5 * math.sin((t + 0.4) * 2 * math.pi)),
                scale: 0.7 + 0.4 * (0.5 + 0.5 * math.cos((t + 0.4) * 2 * math.pi)),
                color: const Color(0xFFF59E0B),
              ),
              // Sparkle 3 (top-left tiny)
              _buildSparkle(
                offset: Offset(-widget.size * 0.45, -widget.size * 0.32),
                size: widget.size * 0.09,
                opacity: 0.2 + 0.6 * (0.5 + 0.5 * math.sin((t + 0.7) * 2 * math.pi)),
                scale: 0.6 + 0.4 * (0.5 + 0.5 * math.cos((t + 0.7) * 2 * math.pi)),
                color: const Color(0xFF14B8A6),
              ),
              // Main Icon
              iconWidget,
            ],
          ),
        );
      },
    );
  }

  Widget _buildSparkle({
    required Offset offset,
    required double size,
    required double opacity,
    required double scale,
    required Color color,
  }) {
    return Transform.translate(
      offset: offset,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: size,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Compact Peeking Cat Recommendation Icon for banners, buttons, and app bars
class PetRecommendationIcon extends StatelessWidget {
  final double size;
  final Color color;
  final Color? boxBackgroundColor;

  const PetRecommendationIcon({
    super.key,
    this.size = 38,
    this.color = const Color(0xFF1E293B),
    this.boxBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return PetRecommendationLoader(
      size: size,
      color: color,
      boxBackgroundColor: boxBackgroundColor,
      withShadow: false,
      onlyBlink: true,
      withSparkles: false,
    );
  }
}
