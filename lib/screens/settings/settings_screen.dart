import 'package:mobile_petadopt/services/notification_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/app_confirmation_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _notificationsEnabled = prefs.getBool('settings_notifications') ?? true;
          _darkModeEnabled = prefs.getBool('settings_dark_mode') ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('settings_notifications', value);

      if (value) {
        await NotificationService.enableNotifications();
      } else {
        await NotificationService.disableNotifications();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Push notifications enabled.' : 'Push notifications muted.',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _darkModeEnabled = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('settings_dark_mode', value);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Dark mode enabled.' : 'Dark mode disabled.',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {}
  }

  void _showRateAppDialog() {
    int selectedRating = 5;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppConfirmationDialog(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFD97706),
              iconBackgroundColor: const Color(0xFFFEF3C7),
              title: 'Rate Our App',
              message: 'How was your experience using CAWS Pet Adoption?',
              cancelText: 'Cancel',
              confirmText: 'Submit',
              onConfirm: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Thank you for your rating and feedback.',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNum = index + 1;
                      return IconButton(
                        onPressed: () {
                          setDialogState(() => selectedRating = starNum);
                        },
                        icon: Icon(
                          starNum <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFEAB308),
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      selectedRating == 5
                          ? 'Excellent!'
                          : selectedRating == 4
                              ? 'Very Good!'
                              : selectedRating == 3
                                  ? 'Good'
                                  : 'Fair',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showShareAppDialog() {
    const shareUrl = 'https://petadopt.caws-cdowelfare.org';
    AppConfirmationDialog.show(
      context,
      icon: Icons.share_rounded,
      iconColor: const Color(0xFF0284C7),
      iconBackgroundColor: const Color(0xFFE0F2FE),
      title: 'Share CAWS App',
      message: 'Help rescue animals in Cagayan de Oro City find loving homes by sharing our platform with friends and family.',
      confirmText: 'Close',
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                shareUrl,
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF0F172A), fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: shareUrl));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Link copied to clipboard.', style: GoogleFonts.poppins(fontSize: 12)),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18, color: AppTheme.primary),
              tooltip: 'Copy Link',
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    AppConfirmationDialog.show(
      context,
      icon: Icons.shield_outlined,
      iconColor: const Color(0xFF059669),
      iconBackgroundColor: const Color(0xFFECFDF5),
      title: 'Privacy Policy',
      confirmText: 'Understood',
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CDO Animal Welfare Society Inc. (CAWS)',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                'CAWS is committed to protecting your personal information pursuant to the Philippine Data Privacy Act of 2012 (Republic Act No. 10173).\n\n'
                '1. Information Collected: We collect your name, contact details, residence verification (Barangay Certificate), government ID, and digital signature exclusively for animal adoption processing and legal accountability.\n\n'
                '2. Usage: Collected information is utilized to evaluate pet compatibility, process adoption agreements, and conduct scheduled health check-ins.\n\n'
                '3. Confidentiality: Your uploaded identification documents and digital signature are encrypted and will never be sold or disclosed to third parties without your prior explicit consent.',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTermsDialog() {
    AppConfirmationDialog.show(
      context,
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF2563EB),
      iconBackgroundColor: const Color(0xFFEFF6FF),
      title: 'Terms & Conditions',
      confirmText: 'Understood',
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adoption Agreement Terms',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                'By applying to adopt an animal through CAWS PetAdopt, you agree to:\n\n'
                '1. Responsible Care: Provide adequate shelter, nutritious food, clean water, and regular veterinary care to the adopted pet.\n\n'
                '2. Non-Breeding & Spay/Neuter: Keep the animal as a companion pet and honor mandatory spay/neuter guidelines.\n\n'
                '3. Post-Adoption Follow-ups: Cooperate with CAWS post-adoption monthly health check-ins and submit necessary health updates.\n\n'
                '4. Non-Abandonment: Under no circumstance shall the pet be abandoned, sold, or surrendered without prior written notice to CAWS.',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDialog() {
    AppConfirmationDialog.show(
      context,
      icon: Icons.headset_mic_rounded,
      iconColor: const Color(0xFF9333EA),
      iconBackgroundColor: const Color(0xFFF3E8FF),
      title: 'Contact CAWS',
      confirmText: 'Close',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CDO Animal Welfare Society Inc.',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          _buildContactRow(Icons.location_on_outlined, 'Cagayan de Oro City, Misamis Oriental, Philippines'),
          const SizedBox(height: 8),
          _buildContactRow(Icons.email_outlined, 'support@caws.org'),
          const SizedBox(height: 8),
          _buildContactRow(Icons.phone_outlined, '+63 912 345 6789'),
          const SizedBox(height: 8),
          _buildContactRow(Icons.access_time_rounded, 'Meet & Greet Events: Sundays 1:00 PM - 5:00 PM'),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    AppConfirmationDialog.show(
      context,
      icon: Icons.logout_rounded,
      isDestructive: true,
      title: 'Log Out',
      message: 'Are you sure you want to log out of your account?',
      cancelText: 'Cancel',
      confirmText: 'Logout',
      onConfirm: () async {
        await ApiService.clearSession();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF0F172A),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Setting',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: General
            _buildSectionHeader('General'),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.notifications_none_rounded,
              title: 'Notification',
              value: _notificationsEnabled,
              onChanged: _setNotifications,
            ),
            const SizedBox(height: 12),
            _buildToggleCard(
              icon: Icons.wb_sunny_outlined,
              title: 'Dark Mode',
              value: _darkModeEnabled,
              onChanged: _setDarkMode,
            ),

            const SizedBox(height: 24),

            // Section 2: Secure
            _buildSectionHeader('Secure'),
            const SizedBox(height: 10),
            Container(
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _buildNavigationRow(
                    icon: Icons.star_outline_rounded,
                    title: 'Rate App',
                    onTap: _showRateAppDialog,
                    isFirst: true,
                  ),
                  _buildDivider(),
                  _buildNavigationRow(
                    icon: Icons.share_outlined,
                    title: 'Share App',
                    onTap: _showShareAppDialog,
                  ),
                  _buildDivider(),
                  _buildNavigationRow(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    onTap: _showPrivacyPolicyDialog,
                  ),
                  _buildDivider(),
                  _buildNavigationRow(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: _showTermsDialog,
                  ),
                  _buildDivider(),
                  _buildNavigationRow(
                    icon: Icons.receipt_long_outlined,
                    title: 'Contact',
                    onTap: _showContactDialog,
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section 3: Account
            _buildSectionHeader('Account'),
            const SizedBox(height: 10),
            Container(
              decoration: _cardDecoration(),
              child: _buildNavigationRow(
                icon: Icons.logout_rounded,
                title: 'Logout',
                onTap: _showLogoutDialog,
                isFirst: true,
                isLast: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildIconBox(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: const Color(0xFF76C81D),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _buildIconBox(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 22,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.6,
      color: Color(0xFFF1F5F9),
      indent: 74,
      endIndent: 16,
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.7), width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
