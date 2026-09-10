import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/services/notification_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/cute_robot_loader.dart';
import 'package:mobile_petadopt/widgets/pet_card.dart';
import 'package:mobile_petadopt/screens/pets/pet_list_screen.dart';
import 'package:mobile_petadopt/screens/adoption/my_applications_screen.dart';
import 'package:mobile_petadopt/screens/profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _hasUnreadApplications = false;

  @override
  void initState() {
    super.initState();
    _checkAccountBanStatus();
    _checkUnreadApplications();
  }

  Future<bool> _checkBanNoticeForAction({String actionDescription = 'take the pet recommendation quiz'}) async {
    try {
      final user = await ApiService.getProfile();
      if (user != null && (user['status'] == 'blacklisted' || user['status'] == 'restricted')) {
        final isBlacklisted = user['status'] == 'blacklisted';
        final rawNotes = user['admin_notes']?.toString().trim();
        final String officialReason = (rawNotes != null && rawNotes.isNotEmpty)
            ? rawNotes
            : (isBlacklisted
                ? 'Non-compliance with CAWS adoption terms and animal welfare standards.'
                : 'Account under shelter administrative review.');
        if (!mounted) return true;

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
                      ? 'Your account has been banned from submitting adoption applications and taking match quizzes. You can browse pets in view-only mode.'
                      : 'Your account is restricted from taking recommendation quizzes at this time.',
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
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SHELTER CONTACT & APPEALS',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.facebook, size: 16, color: Color(0xFF1877F2)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CDO Animal Welfare Society Inc.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 15, color: Color(0xFFEA4335)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'cdoanimalrescueorg@gmail.com',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '0936 556 6200',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
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
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _checkAccountBanStatus() async {
    try {
      final user = await ApiService.getProfile();
      if (user == null) {
        await ApiService.clearSession();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
        }
        return;
      }

      if (user['status'] == 'blacklisted' || user['status'] == 'restricted') {
        final isBlacklisted = user['status'] == 'blacklisted';
        final rawNotes = user['admin_notes']?.toString().trim();
        final String officialReason = (rawNotes != null && rawNotes.isNotEmpty)
            ? rawNotes
            : (isBlacklisted
                ? 'Non-compliance with CAWS adoption terms and animal welfare standards.'
                : 'Account under shelter administrative review.');
        if (!mounted) return;

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
                      ? 'Your account has been banned from submitting adoption applications. You can still browse pets in view-only mode.'
                      : 'Your account is restricted from new adoption applications. You can still browse pets.',
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
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SHELTER CONTACT & APPEALS',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.facebook, size: 16, color: Color(0xFF1877F2)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CDO Animal Welfare Society Inc.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 15, color: Color(0xFFEA4335)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'cdoanimalrescueorg@gmail.com',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '0936 556 6200',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ApiService.clearSession();
                        if (mounted) {
                          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppTheme.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Log Out',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Continue to Home',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _checkUnreadApplications() async {
    try {
      final user = await ApiService.getUser();
      if (user == null) return;
      final userId = user['id'];
      final prefs = await SharedPreferences.getInstance();
      final lastViewedStr = prefs.getString('user_${userId}_last_viewed_applications_time');

      final apps = await ApiService.getMyApplications();
      if (apps.isEmpty) {
        if (mounted) setState(() => _hasUnreadApplications = false);
        return;
      }

      if (lastViewedStr == null) {
        if (mounted) setState(() => _hasUnreadApplications = true);
        return;
      }

      final lastViewedTime = DateTime.parse(lastViewedStr);
      bool hasNew = false;
      for (final app in apps) {
        final updatedAtStr = app['updated_at']?.toString() ?? app['created_at']?.toString();
        if (updatedAtStr != null) {
          final appTime = DateTime.tryParse(updatedAtStr);
          if (appTime != null && appTime.isAfter(lastViewedTime)) {
            hasNew = true;
            break;
          }
        }
      }
      if (mounted) setState(() => _hasUnreadApplications = hasNew);
    } catch (_) {}
  }

  Future<void> _markApplicationsAsViewed() async {
    try {
      final user = await ApiService.getUser();
      if (user != null) {
        final userId = user['id'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_${userId}_last_viewed_applications_time', DateTime.now().toIso8601String());
      }
      if (mounted) {
        setState(() => _hasUnreadApplications = false);
      }
    } catch (_) {}
  }

  List<Widget> get _tabs => [
    _HomeTab(onSeeAllPressed: () => setState(() => _selectedIndex = 1)),
    const PetListScreen(),
    const MyApplicationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _tabs,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 2) {
              _markApplicationsAsViewed();
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.pets_outlined),
              activeIcon: Icon(Icons.pets_rounded),
              label: 'Pets',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.assignment_outlined),
                  if (_hasUnreadApplications)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4D4F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.assignment_rounded),
                  if (_hasUnreadApplications)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4D4F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Applications',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final VoidCallback? onSeeAllPressed;
  const _HomeTab({this.onSeeAllPressed});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _userName = 'Adopter';
  List<Map<String, dynamic>> _pets = [];
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  bool _hasUnreadNotifications = false;
  List<Map<String, dynamic>> _vaccineReminders = [];
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchPets();
    _fetchRecommendations();
    _checkUnreadNotifications();
    NotificationService.setupFirebaseFCM();
  }

  Future<bool> _checkBanNoticeForAction({String actionDescription = 'take the pet recommendation quiz'}) async {
    try {
      final user = await ApiService.getProfile();
      if (user != null && (user['status'] == 'blacklisted' || user['status'] == 'restricted')) {
        final isBlacklisted = user['status'] == 'blacklisted';
        final rawNotes = user['admin_notes']?.toString().trim();
        final String officialReason = (rawNotes != null && rawNotes.isNotEmpty)
            ? rawNotes
            : (isBlacklisted
                ? 'Non-compliance with CAWS adoption terms and animal welfare standards.'
                : 'Account under shelter administrative review.');
        if (!mounted) return true;

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
                      ? 'Your account has been banned from submitting adoption applications and taking match quizzes. You can browse pets in view-only mode.'
                      : 'Your account is restricted from taking recommendation quizzes at this time.',
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
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SHELTER CONTACT & APPEALS',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.facebook, size: 16, color: Color(0xFF1877F2)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'CDO Animal Welfare Society Inc.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 15, color: Color(0xFFEA4335)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'cdoanimalrescueorg@gmail.com',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '0936 556 6200',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
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
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _fetchRecommendations() async {
    try {
      final recs = await ApiService.getRecommendations();
      final availableRecs = recs.where((pet) {
        final status = pet['status']?.toString().toLowerCase();
        return status == null || status == 'available';
      }).toList();
      if (mounted) {
        setState(() {
          _recommendations = availableRecs;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final user = await ApiService.getUser();
      if (user == null) return;
      final userId = user['id'];
      final prefs = await SharedPreferences.getInstance();
      final lastReadStr = prefs.getString('user_${userId}_last_read_notif_time');

      final apps = await ApiService.getMyApplications();
      final reminders = await ApiService.getVaccineReminders();

      if (mounted) {
        setState(() {
          _vaccineReminders = reminders;
        });
      }

      final hasUpcomingReminders = reminders.any((r) {
        final days = r['days_until_due'] as int? ?? 999;
        return days <= 30;
      });

      if (hasUpcomingReminders) {
        if (mounted) setState(() => _hasUnreadNotifications = true);
        return;
      }

      if (apps.isEmpty) {
        if (mounted) setState(() => _hasUnreadNotifications = false);
        return;
      }

      if (lastReadStr == null) {
        if (mounted) setState(() => _hasUnreadNotifications = true);
        return;
      }

      final lastReadTime = DateTime.parse(lastReadStr);
      bool hasNewUpdate = false;
      for (final app in apps) {
        final updatedAtStr = app['updated_at']?.toString() ?? app['created_at']?.toString();
        if (updatedAtStr != null) {
          final appTime = DateTime.tryParse(updatedAtStr);
          if (appTime != null && appTime.isAfter(lastReadTime)) {
            hasNewUpdate = true;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _hasUnreadNotifications = hasNewUpdate;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUser() async {
    final user = await ApiService.getUser();
    if (mounted && user != null && user['name'] != null) {
      final rawName = (user['name'] as String).trim();
      final firstName = rawName.isNotEmpty ? rawName.split(RegExp(r'\s+')).first : 'Adopter';
      setState(() {
        _userName = firstName;
      });
      NotificationService.setupFirebaseFCM();
    }
  }

  Future<void> _fetchPets() async {
    try {
      final pets = await ApiService.getPets();
      final availablePets = pets.where((pet) {
        final status = pet['status']?.toString().toLowerCase();
        return status == null || status == 'available';
      }).toList();
      if (mounted) {
        setState(() {
          _pets = availablePets;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPets {
    if (_selectedCategory == 'all') return _pets;
    return _pets.where((pet) {
      final type = (pet['type'] ?? '').toString().toLowerCase();
      return type == _selectedCategory;
    }).toList();
  }

  Future<void> _showNotificationsBottomSheet() async {
    final user = await ApiService.getUser();
    if (user != null) {
      final userId = user['id'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_${userId}_last_read_notif_time', DateTime.now().toIso8601String());
    }
    if (!mounted) return;
    setState(() {
      _hasUnreadNotifications = false;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Notifications & Alerts',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: ApiService.getMyApplications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                    }
                    final apps = snapshot.data ?? [];
                    if (apps.isEmpty && _vaccineReminders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No notifications right now',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: [
                        // Vaccine Reminders
                        if (_vaccineReminders.isNotEmpty) ...
                          _vaccineReminders.map((reminder) {
                            final days = reminder['days_until_due'] as int? ?? 999;
                            final dueLabel = reminder['next_due_label'] as String? ?? '';
                            final petName = reminder['pet_name'] as String? ?? 'Your pet';
                            final category = reminder['category'] as String? ?? 'Checkup';

                            final urgencyColor = days == 0
                                ? const Color(0xFFDC2626)
                                : days <= 1
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFF7C3AED);
                            final urgencyBg = days == 0
                                ? const Color(0xFFFEF2F2)
                                : days <= 1
                                    ? const Color(0xFFFFF7ED)
                                    : const Color(0xFFF5F3FF);
                            final urgencyBorder = days == 0
                                ? const Color(0xFFFECACA)
                                : days <= 1
                                    ? const Color(0xFFFED7AA)
                                    : const Color(0xFFDDD6FE);
                            final dueText = days == 0
                                ? 'Due Today'
                                : days == 1
                                    ? 'Due Tomorrow'
                                    : 'Due in $days days ($dueLabel)';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: urgencyBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: urgencyBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.vaccines_rounded, color: urgencyColor, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$category Reminder - $petName',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: urgencyColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      dueText,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: urgencyColor,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Make sure your adopted pet is up to date with their $category schedule.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                        // Application Status Cards
                        ...apps.map((item) {
                          final isAdoptedByOther = (item['isAdoptedByOther'] as bool?) ?? false;
                          final isApproved = item['status'] == 'approved';

                          if (isAdoptedByOther) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4ED),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFFFD8BF)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.home_outlined, color: Color(0xFFD9363E), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${item['petName']} Has Found a Home',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFD9363E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'The pet you requested (${item['petName']}) has already found a forever home with another verified applicant.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else if (isApproved) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F8F1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline_rounded, color: AppTheme.successColor, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Adoption Approved for ${item['petName']}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.successColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Your request is approved! Event Date: ${item['scheduledAt'] ?? 'Sunday Adoption Event'}. Location: ${item['eventLocation'] ?? 'CAWS Sunday Event'}.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else if (item['status'] == 'rejected') {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Application Update - ${item['petName']}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Thank you for your interest in adopting ${item['petName']}. Your application was not approved at this time.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else if (item['status'] == 'under_review') {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.manage_search_rounded, color: Color(0xFF2563EB), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Application Under Review - ${item['petName']}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'CAWS staff is actively reviewing your verification documents and questionnaire.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.hourglass_top_rounded, color: AppTheme.warningColor, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Adoption Request Pending - ${item['petName']}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.warningColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Your application is awaiting review by CAWS staff.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedPets = _filteredPets;

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchPets();
        await _fetchRecommendations();
      },
      color: AppTheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildSliverHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Category Filters
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _buildCategoryChip('all', 'All Pets', Icons.grid_view_rounded),
                      const SizedBox(width: 8),
                      _buildCategoryChip('dog', 'Dogs', Icons.pets_rounded),
                      const SizedBox(width: 8),
                      _buildCategoryChip('cat', 'Cats', Icons.cruelty_free_rounded),
                    ],
                  ),

                  // Smart Pet Match Recommendation Banner
                  Container(
                    margin: const EdgeInsets.only(top: 18),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A6B72), AppTheme.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: CuteRobotLoader(
                              size: 38,
                              headColor: AppTheme.primary,
                              eyeColor: Colors.white,
                              withShadow: false,
                              onlyBlink: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Pet Recommendation',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Take our 1-minute quiz for personalized pet matches',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final isBanned = await _checkBanNoticeForAction(actionDescription: 'take the pet match quiz');
                            if (isBanned) return;
                            await Navigator.pushNamed(context, '/match-quiz');
                            _fetchRecommendations();
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                          label: Text(
                            'Take Quiz',
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryDark,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Recommendations Carousel (if available)
                  if (_recommendations.isNotEmpty || _pets.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionHeader(
                      context,
                      'Recommended for You',
                      'Personalized Match',
                      isPowered: true,
                      onTap: () async {
                        final isBanned = await _checkBanNoticeForAction(actionDescription: 'access personalized recommendations');
                        if (isBanned) return;
                        Navigator.pushNamed(context, '/match-quiz');
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 235,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recommendations.isNotEmpty ? _recommendations.length : _pets.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final isRec = _recommendations.isNotEmpty;
                          final raw = isRec ? _recommendations[index] : _pets[index];

                          final petData = isRec
                              ? {
                                  'id': raw['pet_id'] ?? raw['id'],
                                  'name': raw['name'] ?? 'Pet no. ${raw['pet_id']}',
                                  'breed': raw['breed'] ?? 'Mixed Breed',
                                  'age': raw['age'] ?? 'Adult',
                                  'gender': raw['gender'] ?? 'male',
                                  'type': raw['type'] ?? 'cat',
                                  'image': raw['photo_url'] ??
                                      (raw['photo_path'] != null
                                          ? 'http://10.0.2.2:8000/storage/${raw['photo_path']}'
                                          : 'https://images.unsplash.com/photo-1543466835-00a7907e9de1'),
                                  'match_percentage': raw['match_percentage'],
                                  'isRecommended': true,
                                  ...raw,
                                }
                              : raw;

                          return PetCard(
                            pet: petData,
                            isHorizontal: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/pet-detail',
                              arguments: petData,
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Available Pets Section
                  const SizedBox(height: 28),
                  _sectionHeader(
                    context,
                    'Available for Adoption',
                    'See All',
                    onTap: widget.onSeeAllPressed,
                  ),
                  const SizedBox(height: 14),
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          ),
                        )
                      : displayedPets.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.pets_rounded,
                                      size: 48,
                                      color: AppTheme.primary.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No available pets in this category',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Newly listed adoptable pets will appear here.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: displayedPets.length,
                              itemBuilder: (context, index) {
                                final pet = displayedPets[index];
                                return PetCard(
                                  pet: pet,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/pet-detail',
                                    arguments: pet,
                                  ),
                                );
                              },
                            ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String categoryKey, String label, IconData icon) {
    final isSelected = _selectedCategory == categoryKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = categoryKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A6B72), AppTheme.primary],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${_userName.trim().split(RegExp(r'\s+')).first}',
                          style: GoogleFonts.poppins(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Find your perfect companion',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showNotificationsBottomSheet(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            if (_hasUnreadNotifications)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF4D4F),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title,
    String actionLabel, {
    bool isPowered = false,
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        if (isPowered)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
