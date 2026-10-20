import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

class LuminousAiOrb extends StatefulWidget {
  final double size;
  final Animation<double>? turnAnimation;
  const LuminousAiOrb({super.key, this.size = 82, this.turnAnimation});

  @override
  State<LuminousAiOrb> createState() => _LuminousAiOrbState();
}

class _LuminousAiOrbState extends State<LuminousAiOrb>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;
  late AnimationController _eyeController;
  late AnimationController _tapTurnController;
  late Animation<double> _tapTurnAnimation;
  bool _isHappy = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.88, end: 1.15).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _eyeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5400),
    )..repeat();

    _tapTurnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _tapTurnAnimation = CurvedAnimation(
      parent: _tapTurnController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _eyeController.dispose();
    _tapTurnController.dispose();
    super.dispose();
  }

  void _triggerHappyReaction() {
    if (_tapTurnController.isAnimating) return;
    _tapTurnController.forward(from: 0.0);
    setState(() => _isHappy = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _isHappy = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    // Eye Proportions (proportional to sphere size s)
    final eyeWidth = s * 0.185;
    final eyeHeight = s * 0.205;
    final eyeRadius = s * 0.052;
    final eyeGap = s * 0.082;
    final maxShiftX = s * 0.045;
    final maxShiftY = s * 0.024;

    final listenables = <Listenable>[_floatAnimation, _eyeController, _tapTurnAnimation];
    if (widget.turnAnimation != null) {
      listenables.add(widget.turnAnimation!);
    }

    return GestureDetector(
      onTap: _triggerHappyReaction,
      child: AnimatedBuilder(
        animation: Listenable.merge(listenables),
        builder: (context, child) {
          final t = _eyeController.value;
          final glowFactor = _isHappy ? 1.35 : _glowAnimation.value;

          // 3D Turn Progress (0.0 to 1.0)
          double turnProgress = 0.0;
          if (_tapTurnController.isAnimating) {
            turnProgress = _tapTurnAnimation.value;
          } else if (widget.turnAnimation != null) {
            turnProgress = widget.turnAnimation!.value;
          }

          final bool isTurning = turnProgress > 0.001 && turnProgress < 0.999;
          final double angle = turnProgress * 2 * math.pi;
          final double cosAngle = math.cos(angle);
          final double sinAngle = math.sin(angle);

          // 1. Natural Blinking & Glance logic with Suggestion 1 (Blink-Through Spin + Happy Landing)
          double eyeScaleY = 1.0;
          double eyeScaleX = 1.0;
          double eyeOffsetX = 0.0;
          double eyeOffsetY = 0.0;
          double eyesOpacity = 1.0;
          bool isHappyLanding = false;
          double hopY = 0.0;

          if (isTurning) {
            // Phase A: 0.00 - 0.16 -> Eyes smoothly blink closed in anticipation of turn
            if (turnProgress <= 0.16) {
              final p = turnProgress / 0.16;
              eyeScaleY = (1.0 - p * 0.92).clamp(0.08, 1.0);
              eyesOpacity = 1.0;
            }
            // Phase B: 0.16 - 0.78 -> Eyes stay closed while glossy sphere spins 360° with light sweep
            else if (turnProgress < 0.78) {
              eyeScaleY = 0.08;
              final fadeP = ((turnProgress - 0.16) / 0.12).clamp(0.0, 1.0);
              eyesOpacity = (1.0 - fadeP * 0.82).clamp(0.18, 1.0);
            }
            // Phase C: 0.78 - 0.93 -> Sphere faces front; eyes pop open into happy smiling arcs (^ ^) with playful hop!
            else if (turnProgress < 0.93) {
              final p = (turnProgress - 0.78) / 0.15;
              isHappyLanding = true;
              eyesOpacity = 1.0;
              eyeScaleY = (0.2 + 0.8 * Curves.easeOutBack.transform(p)).clamp(0.2, 1.2);
              hopY = -4.5 * math.sin(p * math.pi);
            }
            // Phase D: 0.93 - 1.00 -> Gracefully settles from happy smile into alert, curious eyes
            else {
              final p = (turnProgress - 0.93) / 0.07;
              isHappyLanding = p < 0.35;
              eyesOpacity = 1.0;
              eyeScaleY = 1.15 - p * 0.15;
            }
          } else {
            if (!_isHappy) {
              // First single blink at t = 0.20 to 0.25
              if (t >= 0.20 && t < 0.225) {
                eyeScaleY = 1.0 - ((t - 0.20) / 0.025) * 0.92;
              } else if (t >= 0.225 && t < 0.25) {
                eyeScaleY = 0.08 + ((t - 0.225) / 0.025) * 0.92;
              }
              // Double-blink sequence at t = 0.68 to 0.77
              else if (t >= 0.68 && t < 0.70) {
                eyeScaleY = 1.0 - ((t - 0.68) / 0.02) * 0.92;
              } else if (t >= 0.70 && t < 0.72) {
                eyeScaleY = 0.08 + ((t - 0.70) / 0.02) * 0.92;
              } else if (t >= 0.73 && t < 0.75) {
                eyeScaleY = 1.0 - ((t - 0.73) / 0.02) * 0.92;
              } else if (t >= 0.75 && t < 0.77) {
                eyeScaleY = 0.08 + ((t - 0.75) / 0.02) * 0.92;
              }
            }

            // 2. Curious eye glance shifts
            if (!_isHappy) {
              if (t >= 0.27 && t < 0.33) {
                final p = (t - 0.27) / 0.06;
                eyeOffsetX = -maxShiftX * Curves.easeInOut.transform(p);
              } else if (t >= 0.33 && t < 0.46) {
                eyeOffsetX = -maxShiftX;
                eyeOffsetY = -maxShiftY * 0.4;
              } else if (t >= 0.46 && t < 0.52) {
                final p = (t - 0.46) / 0.06;
                eyeOffsetX = -maxShiftX * (1.0 - Curves.easeInOut.transform(p));
                eyeOffsetY = -maxShiftY * 0.4 * (1.0 - Curves.easeInOut.transform(p));
              } else if (t >= 0.80 && t < 0.86) {
                final p = (t - 0.80) / 0.06;
                eyeOffsetX = maxShiftX * Curves.easeInOut.transform(p);
                eyeOffsetY = -maxShiftY * Curves.easeInOut.transform(p);
              } else if (t >= 0.86 && t < 0.94) {
                eyeOffsetX = maxShiftX;
                eyeOffsetY = -maxShiftY;
              } else if (t >= 0.94 && t < 1.00) {
                final p = (t - 0.94) / 0.06;
                eyeOffsetX = maxShiftX * (1.0 - Curves.easeInOut.transform(p));
                eyeOffsetY = -maxShiftY * (1.0 - Curves.easeInOut.transform(p));
              }
            }
          }

          // 3D Specular Highlight & Radial Lighting sweep
          final double lightAngle = -math.pi * 0.75 + angle;
          final double lightCenterX = isTurning ? (0.42 * math.cos(lightAngle)) : -0.35;
          final double lightCenterY = isTurning ? (0.38 * math.sin(lightAngle)) : -0.35;

          final double hlLeft = isTurning
              ? (s * 0.44 + (s * 0.26) * math.cos(lightAngle) - (s * 0.16))
              : s * 0.18;
          final double hlTop = isTurning
              ? (s * 0.44 + (s * 0.22) * math.sin(lightAngle) - (s * 0.09))
              : s * 0.10;
          final double hlOpacity = isTurning
              ? (0.28 + 0.42 * cosAngle).clamp(0.12, 0.72)
              : 0.70;

          final double hlLeft2 = isTurning
              ? (s * 0.48 + (s * 0.28) * math.cos(lightAngle + 0.4) - (s * 0.04))
              : s * 0.52;
          final double hlTop2 = isTurning
              ? (s * 0.48 + (s * 0.24) * math.sin(lightAngle + 0.4) - (s * 0.04))
              : s * 0.08;
          final double hlOpacity2 = isTurning
              ? (0.20 + 0.35 * cosAngle).clamp(0.08, 0.55)
              : 0.50;

          return Transform.translate(
            offset: Offset(0, _floatAnimation.value + hopY),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateZ(sinAngle * 0.09)
                ..rotateX(sinAngle * 0.06),
              child: SizedBox(
                width: s * 1.35,
                height: s * 1.25,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft bottom floor reflection & contact shadow in vibrant online green
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: s * 0.78,
                        height: s * 0.14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.elliptical(s * 0.78, s * 0.14),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(
                                alpha: (0.45 * glowFactor).clamp(0.0, 1.0),
                              ),
                              blurRadius: s * 0.25,
                              spreadRadius: s * 0.04,
                            ),
                            BoxShadow(
                              color: const Color(0xFF15803D).withValues(alpha: 0.22),
                              blurRadius: s * 0.12,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Multi-tier luminous breathing glowing aura (radiates like an active online beacon)
                    Container(
                      width: s * 1.12,
                      height: s * 1.12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          // Core bright neon halo
                          BoxShadow(
                            color: const Color(0xFF22C55E).withValues(
                              alpha: (0.62 * glowFactor).clamp(0.0, 1.0),
                            ),
                            blurRadius: s * 0.25,
                            spreadRadius: s * 0.05,
                          ),
                          // Mid-range radiant aura
                          BoxShadow(
                            color: const Color(0xFF4ADE80).withValues(
                              alpha: (0.42 * glowFactor).clamp(0.0, 1.0),
                            ),
                            blurRadius: s * 0.42,
                            spreadRadius: s * 0.10,
                          ),
                          // Soft wide ambient neon glow
                          BoxShadow(
                            color: const Color(0xFF86EFAC).withValues(
                              alpha: (0.28 * glowFactor).clamp(0.0, 1.0),
                            ),
                            blurRadius: s * 0.58,
                            spreadRadius: s * 0.16,
                          ),
                        ],
                      ),
                    ),

                    // Main circle sphere body with social media "online active green" 3D spherical gradient
                    Container(
                      width: s,
                      height: s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF86EFAC).withValues(alpha: 0.65),
                          width: s > 40 ? 1.5 : 1.0,
                        ),
                        gradient: RadialGradient(
                          center: Alignment(lightCenterX, lightCenterY),
                          radius: 0.94,
                          colors: const [
                            Color(0xFFDCFCE7), // Soft luminous lime-white light origin
                            Color(0xFF86EFAC), // Bright luminous lime
                            Color(0xFF4ADE80), // Vibrant neon green
                            Color(0xFF22C55E), // Iconic social media "online" active green
                            Color(0xFF16A34A), // Rich active green depth
                            Color(0xFF15803D), // Deep saturated active emerald base
                          ],
                          stops: const [0.0, 0.20, 0.44, 0.70, 0.88, 1.0],
                        ),
                        boxShadow: [
                          // Inner edge glow
                          BoxShadow(
                            color: const Color(0xFF22C55E).withValues(alpha: 0.50),
                            blurRadius: s * 0.12,
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                    ),

                    // Animated Crisp White Eyes (distinct high-contrast against online green body)
                    Opacity(
                      opacity: eyesOpacity,
                      child: Transform.translate(
                        offset: Offset(eyeOffsetX, eyeOffsetY),
                        child: Transform.scale(
                          scaleX: eyeScaleX,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildSingleEye(
                                width: eyeWidth,
                                height: eyeHeight,
                                radius: eyeRadius,
                                scaleY: eyeScaleY,
                                isHappy: _isHappy || isHappyLanding,
                              ),
                              SizedBox(width: eyeGap),
                              _buildSingleEye(
                                width: eyeWidth,
                                height: eyeHeight,
                                radius: eyeRadius,
                                scaleY: eyeScaleY,
                                isHappy: _isHappy || isHappyLanding,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Primary specular glass sphere highlight (orbits in 3D during turn)
                    Positioned(
                      top: hlTop,
                      left: hlLeft,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: hlOpacity,
                          child: Container(
                            width: s * 0.32,
                            height: s * 0.18,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.70),
                                  Colors.white.withValues(alpha: 0.20),
                                ],
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.elliptical(s * 0.32, s * 0.18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Secondary pinpoint specular highlight dot (orbits in 3D during turn)
                    Positioned(
                      top: hlTop2,
                      left: hlLeft2,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: hlOpacity2,
                          child: Container(
                            width: s * 0.08,
                            height: s * 0.08,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.50),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSingleEye({
    required double width,
    required double height,
    required double radius,
    required double scaleY,
    required bool isHappy,
  }) {
    if (isHappy) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: CustomPaint(
            size: Size(width, height * 0.62),
            painter: _HappyEyePainter(
              color: Colors.white,
              strokeWidth: width * 0.22,
            ),
          ),
        ),
      );
    }

    return Transform.scale(
      scaleY: scaleY.clamp(0.08, 1.0),
      alignment: Alignment.center,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.85),
              blurRadius: 4,
              spreadRadius: 0.5,
            ),
          ],
        ),
      ),
    );
  }
}

class _HappyEyePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const _HappyEyePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final path = Path()
      ..moveTo(1.5, size.height * 0.85)
      ..quadraticBezierTo(size.width / 2, 0, size.width - 1.5, size.height * 0.85);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HappyEyePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class AiRecommendationHero extends StatefulWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback onQuizPressed;
  final ValueChanged<String> onFilterSelected;
  final String activeLifestyleFilter;
  final bool isCompact;
  final int entranceTrigger;

  const AiRecommendationHero({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    required this.onQuizPressed,
    required this.onFilterSelected,
    this.activeLifestyleFilter = 'none',
    this.isCompact = false,
    this.entranceTrigger = 0,
  });

  @override
  State<AiRecommendationHero> createState() => _AiRecommendationHeroState();
}

class _AiRecommendationHeroState extends State<AiRecommendationHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _headlineFade;
  late Animation<Offset> _headlineSlide;
  late Animation<int> _typewriterAnimation;
  late Animation<double> _orbFade;
  late Animation<double> _orbScale;
  late Animation<Offset> _orbSlide;
  late Animation<double> _orbTurn;
  late Animation<double> _searchFade;
  late Animation<Offset> _searchSlide;
  late Animation<double> _cardsFade;
  late Animation<Offset> _cardsSlide;

  static const String _fullHeadline = 'How Can I Help You Today?';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 1. Badge glide & Typewriter text (0ms - 900ms)
    _headlineFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.18, curve: Curves.easeOutCubic),
    );
    _headlineSlide = Tween<Offset>(
      begin: const Offset(0, -0.20),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.20, curve: Curves.easeOutCubic),
    ));

    _typewriterAnimation = StepTween(
      begin: 0,
      end: _fullHeadline.length,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.05, 0.36, curve: Curves.linear),
    ));

    // 2. 3D Mascot Orb floats up & blooms in center (300ms - 900ms)
    _orbFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.12, 0.36, curve: Curves.easeOutCubic),
    );
    _orbScale = Tween<double>(begin: 0.25, end: 1.0).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 0.40, curve: Curves.easeOutBack),
    ));
    _orbSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 0.38, curve: Curves.easeOutCubic),
    ));

    // 3. The 3D Mascot Orb TURN Motion — right after "How Can I Help You Today?" typewriter completes! (900ms - 1700ms)
    _orbTurn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.36, 0.68, curve: Curves.easeInOutCubic),
    );

    // 4. Search / Prompt Bar glides in (1550ms - 2100ms)
    _searchFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.62, 0.84, curve: Curves.easeOutCubic),
    );
    _searchSlide = Tween<Offset>(
      begin: const Offset(0, 0.30),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.62, 0.85, curve: Curves.easeOutCubic),
    ));

    // 5. 2x2 Lifestyle cards cascade into place (1950ms - 2500ms)
    _cardsFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.78, 1.0, curve: Curves.easeOutCubic),
    );
    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.30),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.78, 1.0, curve: Curves.easeOutCubic),
    ));

    _animController.forward();
  }

  @override
  void didUpdateWidget(AiRecommendationHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entranceTrigger != oldWidget.entranceTrigger) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD1FAE5),
            Color(0xFFECFDF5),
            Color(0xFFF8FAFC),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFA7F3D0).withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Column(
        children: [
          // 1. Assistant Badge & Headline (Phase 1)
          FadeTransition(
            opacity: _headlineFade,
            child: SlideTransition(
              position: _headlineSlide,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'PET FINDER',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: const Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _typewriterAnimation,
                    builder: (context, _) {
                      final count = _typewriterAnimation.value;
                      final text = _fullHeadline.substring(0, count);
                      final isTyping = count < _fullHeadline.length;
                      return RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: text.isEmpty ? ' ' : text,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                          children: [
                            if (isTyping)
                              TextSpan(
                                text: ' |',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF22C55E),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Central 3D Glowing Mascot Orb (Phase 2 - Blooms & Performs 3D Turn!)
          FadeTransition(
            opacity: _orbFade,
            child: SlideTransition(
              position: _orbSlide,
              child: ScaleTransition(
                scale: _orbScale,
                child: LuminousAiOrb(
                  size: 82,
                  turnAnimation: _orbTurn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 3. Prompt & Search Bar (Phase 3)
          FadeTransition(
            opacity: _searchFade,
            child: SlideTransition(
              position: _searchSlide,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, color: Color(0xFF64748B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: widget.searchController,
                        onChanged: widget.onSearchChanged,
                        onSubmitted: widget.onSearchSubmitted,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'What kind of pet are you looking for?',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (widget.onSearchSubmitted != null && widget.searchController != null) {
                          widget.onSearchSubmitted!(widget.searchController!.text);
                        }
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF199CA4), Color(0xFF0E7A80)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 4. 2x2 Quick Lifestyle Helper Cards (Phase 4)
          FadeTransition(
            opacity: _cardsFade,
            child: SlideTransition(
              position: _cardsSlide,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildHelperCard(
                          icon: Icons.psychology_rounded,
                          iconColor: const Color(0xFF7C3AED),
                          iconBg: const Color(0xFFF5F3FF),
                          title: 'Take Match Quiz',
                          subtitle: '1-Min AI Match',
                          isSelected: false,
                          onTap: widget.onQuizPressed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildHelperCard(
                          icon: Icons.apartment_rounded,
                          iconColor: const Color(0xFF0D9488),
                          iconBg: const Color(0xFFF0FDFA),
                          title: 'Apartment Friendly',
                          subtitle: 'Calm & Quiet',
                          isSelected: widget.activeLifestyleFilter == 'apartment',
                          onTap: () => widget.onFilterSelected(widget.activeLifestyleFilter == 'apartment' ? 'none' : 'apartment'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHelperCard(
                          icon: Icons.directions_run_rounded,
                          iconColor: const Color(0xFFEA580C),
                          iconBg: const Color(0xFFFFF7ED),
                          title: 'Active & Playful',
                          subtitle: 'High Energy',
                          isSelected: widget.activeLifestyleFilter == 'active',
                          onTap: () => widget.onFilterSelected(widget.activeLifestyleFilter == 'active' ? 'none' : 'active'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildHelperCard(
                          icon: Icons.family_restroom_rounded,
                          iconColor: const Color(0xFFE11D48),
                          iconBg: const Color(0xFFFFF1F2),
                          title: 'Gentle & Family',
                          subtitle: 'Kids & Pets',
                          isSelected: widget.activeLifestyleFilter == 'family',
                          onTap: () => widget.onFilterSelected(widget.activeLifestyleFilter == 'family' ? 'none' : 'family'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelperCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF199CA4).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 16),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                height: 1.25,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
