import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

class SignContractDialog extends StatefulWidget {
  final Map<String, dynamic> application;
  final VoidCallback onSigned;

  const SignContractDialog({
    super.key,
    required this.application,
    required this.onSigned,
  });

  @override
  State<SignContractDialog> createState() => _SignContractDialogState();
}

class _SignContractDialogState extends State<SignContractDialog> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isSubmitting = false;
  bool _isSigning = false;
  String? _savedSignatureUrl;
  bool _useSavedSignature = false;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadSavedSignature();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSignature() async {
    try {
      final user = await ApiService.getUser();
      final sig = user?['digital_signature_url']?.toString();
      if (mounted) {
        setState(() {
          _savedSignatureUrl = sig;
          if (sig != null && sig.isNotEmpty) {
            _useSavedSignature = true;
          }
          _isLoadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  Future<String?> _exportSignatureAsBase64() async {
    if (_strokes.isEmpty) return null;

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final stroke in _strokes) {
      for (final p in stroke) {
        if (p.dx < minX) minX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy > maxY) maxY = p.dy;
      }
    }

    const padding = 10.0;
    minX = (minX - padding).clamp(0.0, double.infinity);
    minY = (minY - padding).clamp(0.0, double.infinity);
    maxX = maxX + padding;
    maxY = maxY + padding;

    final width = (maxX - minX).clamp(60.0, 600.0);
    final height = (maxY - minY).clamp(30.0, 300.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final strokePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final dotPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.translate(-minX, -minY);

    for (final stroke in _strokes) {
      if (stroke.length > 2) {
        final path = Path();
        path.moveTo(stroke[0].dx, stroke[0].dy);
        for (int i = 1; i < stroke.length - 1; i++) {
          final p0 = stroke[i];
          final p1 = stroke[i + 1];
          path.quadraticBezierTo(
            p0.dx,
            p0.dy,
            (p0.dx + p1.dx) / 2,
            (p0.dy + p1.dy) / 2,
          );
        }
        path.lineTo(stroke.last.dx, stroke.last.dy);
        canvas.drawPath(path, strokePaint);
      } else if (stroke.length == 2) {
        canvas.drawLine(stroke[0], stroke[1], strokePaint);
      } else if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], 2.0, dotPaint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final bytes = byteData.buffer.asUint8List();
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  Future<void> _submitSignature() async {
    if (!_useSavedSignature && _strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw your digital signature above before submitting.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final appId = widget.application['id'] as int;

      if (_useSavedSignature) {
        await ApiService.signAdoptionContract(
          applicationId: appId,
          useSavedSignature: true,
        );
      } else {
        final base64Sig = await _exportSignatureAsBase64();
        if (base64Sig == null) throw Exception('Could not process signature image.');
        await ApiService.signAdoptionContract(
          applicationId: appId,
          signatureBase64: base64Sig,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSigned();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Adoption agreement signed successfully!',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.application['pet'] as Map<String, dynamic>?;
    final petName = pet != null ? (pet['name'] ?? 'Pet no. ') : 'Pet';
    final petBreed = pet?['breed'] ?? 'Aspin / Puspin';
    final scheduledAt = widget.application['scheduled_at']?.toString() ?? '';
    final eventLocation = widget.application['event_location']?.toString() ?? '';
    final hasSavedSignature = _savedSignatureUrl != null && _savedSignatureUrl!.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Top Progress Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentStep >= 1 ? AppTheme.primary : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dynamic Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  if (_currentStep == 1) ...[
                    IconButton(
                      onPressed: () => _goToStep(0),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.primary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Back to Commitments',
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.assignment_turned_in_outlined, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentStep == 0 ? 'Adopter Commitments' : 'Digital Signature',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _currentStep == 0
                              ? 'Step 1 of 2: Review terms and conditions'
                              : 'Step 2 of 2: Sign to finalize adoption',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Animated Slide Steps
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 0: Adopter Commitments
                  _buildCommitmentsStep(
                    petName: petName,
                    petBreed: petBreed,
                    scheduledAt: scheduledAt,
                    eventLocation: eventLocation,
                  ),

                  // Step 1: Digital Signature
                  _buildSignatureStep(
                    hasSavedSignature: hasSavedSignature,
                  ),
                ],
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: _currentStep == 0
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _goToStep(1),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                        label: Text(
                          'I Agree',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitSignature,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Icon(
                                _useSavedSignature ? Icons.verified_rounded : Icons.draw_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isSubmitting
                              ? 'Applying Signature...'
                              : (_useSavedSignature ? 'Confirm & Apply Saved Signature' : 'Sign & Finalize Agreement'),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _useSavedSignature ? const Color(0xFF059669) : AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitmentsStep({
    required String petName,
    required String petBreed,
    required String scheduledAt,
    required String eventLocation,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet & Pickup Summary Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pets_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        petName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        petBreed,
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                      if (scheduledAt.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Pickup: $scheduledAt${eventLocation.isNotEmpty ? ' - $eventLocation' : ''}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F766E),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Adopter Commitments Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adopter Commitments (RA 8485):',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTermItem('I will never abandon, hurt, or maltreat my adopted pet (sanctioned under Republic Act 8485).'),
                _buildTermItem('I agree to provide proper veterinary care, anti-rabies vaccination, and regular nourishment.'),
                _buildTermItem('I consent to mandatory Spay & Neuter (Kapon) to fight pet overpopulation.'),
                _buildTermItem('I agree to submit monthly pet health updates and photos through this mobile app.'),
                _buildTermItem('Adoption is a lifetime commitment for the entire life of the animal.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'By tapping \'I Agree\', you acknowledge your readiness to take on these responsibilities before signing.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureStep({
    required bool hasSavedSignature,
  }) {
    if (_isLoadingUser) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return SingleChildScrollView(
      physics: _isSigning ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_useSavedSignature && hasSavedSignature) ...[
            // Saved Signature View
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Digital Signature',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 11, color: Color(0xFF059669)),
                          const SizedBox(width: 3),
                          Text(
                            'On Record',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _useSavedSignature = false;
                      _strokes.clear();
                    });
                  },
                  icon: const Icon(Icons.edit_outlined, size: 14, color: AppTheme.primary),
                  label: Text(
                    'Draw New',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 140,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Image.network(
                _savedSignatureUrl!,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Center(
                  child: Text('Signature on file', style: TextStyle(color: Color(0xFF64748B))),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your verified on-record digital signature will be applied to this agreement.',
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
            ),
          ] else ...[
            // Drawing Canvas View
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Draw Digital Signature',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    if (hasSavedSignature)
                      TextButton(
                        onPressed: () {
                          setState(() => _useSavedSignature = true);
                        },
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: Text(
                          'Use Saved',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF059669)),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: _clearSignature,
                      icon: const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.primary),
                      label: Text(
                        'Clear',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isSigning ? AppTheme.primary : const Color(0xFFCBD5E1),
                  width: _isSigning ? 2.0 : 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    if (_strokes.isEmpty)
                      const IgnorePointer(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.draw_rounded, size: 26, color: Color(0xFF94A3B8)),
                              SizedBox(height: 6),
                              Text(
                                'Sign with your finger inside this box',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 24,
                      left: 16,
                      right: 16,
                      child: const IgnorePointer(
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                    RawGestureDetector(
                      gestures: <Type, GestureRecognizerFactory>{
                        EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                          (EagerGestureRecognizer instance) {},
                        ),
                      },
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (event) {
                          setState(() {
                            _isSigning = true;
                            _currentStroke = [event.localPosition];
                            _strokes.add(_currentStroke);
                          });
                        },
                        onPointerMove: (event) {
                          setState(() {
                            _currentStroke.add(event.localPosition);
                          });
                        },
                        onPointerUp: (_) {
                          setState(() {
                            _isSigning = false;
                            _currentStroke = [];
                          });
                        },
                        onPointerCancel: (_) {
                          setState(() {
                            _isSigning = false;
                            _currentStroke = [];
                          });
                        },
                        child: SizedBox.expand(
                          child: CustomPaint(
                            painter: _SignaturePainter(strokes: _strokes),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign inside the box to affix your legal digital signature.',
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final dotPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      if (stroke.length > 2) {
        final path = Path();
        path.moveTo(stroke[0].dx, stroke[0].dy);
        for (int i = 1; i < stroke.length - 1; i++) {
          final p0 = stroke[i];
          final p1 = stroke[i + 1];
          path.quadraticBezierTo(
            p0.dx,
            p0.dy,
            (p0.dx + p1.dx) / 2,
            (p0.dy + p1.dy) / 2,
          );
        }
        path.lineTo(stroke.last.dx, stroke.last.dy);
        canvas.drawPath(path, strokePaint);
      } else if (stroke.length == 2) {
        canvas.drawLine(stroke[0], stroke[1], strokePaint);
      } else if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], 2.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
