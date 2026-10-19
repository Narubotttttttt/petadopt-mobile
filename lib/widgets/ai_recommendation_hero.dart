import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuminousAiOrb extends StatefulWidget {
  final double size;
  const LuminousAiOrb({super.key, this.size = 82});

  @override
  State<LuminousAiOrb> createState() => _LuminousAiOrbState();
}

class _LuminousAiOrbState extends State<LuminousAiOrb>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _eyeController;
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

    _eyeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5400),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _eyeController.dispose();
    super.dispose();
  }

  void _triggerHappyReaction() {
    if (_isHappy) return;
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

    return GestureDetector(
      onTap: _triggerHappyReaction,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatAnimation, _eyeController]),
        builder: (context, child) {
          final t = _eyeController.value;

          // 1. Natural Blinking logic
          double eyeScaleY = 1.0;
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
          double eyeOffsetX = 0.0;
          double eyeOffsetY = 0.0;

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

          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: SizedBox(
              width: s + 28,
              height: s + 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft bottom floor shadow
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: s * 0.76,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.elliptical(s * 0.76, 12)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.38),
                            blurRadius: 18,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Soft glowing aura surrounding the circle model
                  Container(
                    width: s + 8,
                    height: s + 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.42),
                          blurRadius: 22,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  // Main circle sphere body with 3D gradient
                  Container(
                    width: s,
                    height: s,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(-0.35, -0.35),
                        radius: 0.95,
                        colors: [
                          Color(0xFFBAE6FD),
                          Color(0xFF60A5FA),
                          Color(0xFF0284C7),
                          Color(0xFF0369A1),
                          Color(0xFF0B192E),
                        ],
                        stops: [0.0, 0.30, 0.60, 0.82, 1.0],
                      ),
                    ),
                  ),

                  // Animated Glowing Cyan Robot Eyes (directly on the circular sphere)
                  Transform.translate(
                    offset: Offset(eyeOffsetX, eyeOffsetY),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSingleEye(
                          width: eyeWidth,
                          height: eyeHeight,
                          radius: eyeRadius,
                          scaleY: eyeScaleY,
                          isHappy: _isHappy,
                        ),
                        SizedBox(width: eyeGap),
                        _buildSingleEye(
                          width: eyeWidth,
                          height: eyeHeight,
                          radius: eyeRadius,
                          scaleY: eyeScaleY,
                          isHappy: _isHappy,
                        ),
                      ],
                    ),
                  ),

                  // Primary specular glass sphere highlight
                  Positioned(
                    top: s * 0.10,
                    left: s * 0.20,
                    child: IgnorePointer(
                      child: Container(
                        width: s * 0.28,
                        height: s * 0.16,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.all(
                            Radius.elliptical(s * 0.28, s * 0.16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Secondary specular highlight dot
                  Positioned(
                    top: s * 0.08,
                    left: s * 0.48,
                    child: IgnorePointer(
                      child: Container(
                        width: s * 0.07,
                        height: s * 0.07,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
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
              color: const Color(0xFF00F0FF),
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
          color: const Color(0xFF00F0FF),
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF67E8F9), // Luminous bright cyan top
              Color(0xFF00F0FF), // Electric cyan core
              Color(0xFF00D2EF), // Deep neon cyan base
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF075985).withValues(alpha: 0.35),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.95),
              blurRadius: 10,
              spreadRadius: 1.5,
            ),
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 3,
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
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2.2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

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

class AiRecommendationHero extends StatelessWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback onQuizPressed;
  final ValueChanged<String> onFilterSelected;
  final String activeLifestyleFilter;
  final bool isCompact;

  const AiRecommendationHero({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    required this.onQuizPressed,
    required this.onFilterSelected,
    this.activeLifestyleFilter = 'none',
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFBAE6FD),
            Color(0xFFE0F2FE),
            Color(0xFFF8FAFC),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFBAE6FD).withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Column(
        children: [
          // Assistant Badge & Headline
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF0284C7), size: 13),
                const SizedBox(width: 5),
                Text(
                  'AI PET MATCHMAKER',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: const Color(0xFF0369A1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'How Can I Help You Today?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),

          // Central 3D Glowing Orb
          const LuminousAiOrb(size: 82),
          const SizedBox(height: 18),

          // Prompt & Search Bar
          Container(
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
                    controller: searchController,
                    onChanged: onSearchChanged,
                    onSubmitted: onSearchSubmitted,
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
                    if (onSearchSubmitted != null && searchController != null) {
                      onSearchSubmitted!(searchController!.text);
                    }
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
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
          const SizedBox(height: 18),

          // 2x2 Quick Lifestyle Helper Cards
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
                  onTap: onQuizPressed,
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
                  isSelected: activeLifestyleFilter == 'apartment',
                  onTap: () => onFilterSelected(activeLifestyleFilter == 'apartment' ? 'none' : 'apartment'),
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
                  isSelected: activeLifestyleFilter == 'active',
                  onTap: () => onFilterSelected(activeLifestyleFilter == 'active' ? 'none' : 'active'),
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
                  isSelected: activeLifestyleFilter == 'family',
                  onTap: () => onFilterSelected(activeLifestyleFilter == 'family' ? 'none' : 'family'),
                ),
              ),
            ],
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
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0284C7).withValues(alpha: 0.1)
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
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7), size: 16),
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
