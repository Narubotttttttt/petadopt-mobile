import 'package:mobile_petadopt/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

class ExplorationModeDialog extends StatelessWidget {
  final VoidCallback onRecommendationSelected;
  final VoidCallback? onDismiss;

  const ExplorationModeDialog({
    super.key,
    required this.onRecommendationSelected,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onRecommendationSelected,
    VoidCallback? onManualSelected,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ExplorationModeDialog(
        onRecommendationSelected: onRecommendationSelected,
        onDismiss: onManualSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 20,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Badge Icon
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A6B72), AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Smart Pet Matching',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Our shelter pairs adoptable pets through Machine Learning compatibility, matching your lifestyle, routine, and living environment.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),

            // Start Assessment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final user = await ApiService.getProfile();
                  if (!context.mounted) return;
                  if (user != null && (user['status'] == 'blacklisted' || user['status'] == 'restricted')) {
                    Navigator.pop(context);
                    final isBlacklisted = user['status'] == 'blacklisted';
                    final rawNotes = user['admin_notes']?.toString().trim();
                    final String officialReason = (rawNotes != null && rawNotes.isNotEmpty)
                        ? rawNotes
                        : (isBlacklisted
                            ? 'Non-compliance with CAWS adoption terms and animal welfare standards.'
                            : 'Account under shelter administrative review.');

                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isBlacklisted ? const Color(0xFFFFEAEA) : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.block_rounded,
                                color: isBlacklisted ? AppTheme.errorColor : AppTheme.warningColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isBlacklisted ? 'Account Banned' : 'Account Restricted',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBlacklisted
                                  ? 'Your account has been banned from submitting adoption applications.'
                                  : 'Your account is currently restricted from taking recommendation quizzes.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isBlacklisted ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isBlacklisted ? const Color(0xFFFECDD3) : const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OFFICIAL REASON',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isBlacklisted ? AppTheme.errorColor : const Color(0xFFB45309),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    officialReason,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBlacklisted ? AppTheme.errorColor : AppTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                'Understood',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  onRecommendationSelected();
                },
                icon: const Icon(Icons.quiz_outlined, size: 18),
                label: Text(
                  'Take Compatibility Assessment',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Dismiss Button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (onDismiss != null) onDismiss!();
              },
              child: Text(
                'Maybe Later',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
