import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/services/notification_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/screens/pets/pet_list_screen.dart';
import 'package:mobile_petadopt/screens/adoption/my_applications_screen.dart';
import 'package:mobile_petadopt/screens/adoption/adopted_pet_hub_screen.dart';
import 'package:mobile_petadopt/screens/adoption/my_adopted_pets_screen.dart';
import 'package:mobile_petadopt/screens/adoption/pet_medical_card_screen.dart';
import 'package:mobile_petadopt/screens/profile/profile_screen.dart';
import 'package:mobile_petadopt/screens/recommendation/match_quiz_screen.dart';
import 'package:mobile_petadopt/widgets/skeleton_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _hasUnreadApplications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAccountBanStatus();
    _checkUnreadApplications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAccountBanStatus();
      _checkUnreadApplications();
      _homeTabKey.currentState?.reload();
    }
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
          builder: (ctx) {
            final isDark = AppTheme.isDark(ctx);
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
              actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              title: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isBlacklisted
                          ? (isDark ? const Color(0xFF450A0A) : const Color(0xFFFFEAEA))
                          : (isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB)),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.block_rounded,
                        color: isBlacklisted ? AppTheme.errorColor : (isDark ? const Color(0xFFF59E0B) : AppTheme.warningColor),
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isBlacklisted ? 'Account Banned' : 'Account Restricted',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimary(ctx),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      isBlacklisted
                          ? 'Your account has been banned from submitting adoption applications. You can still view pet compatibility matches in read-only mode.'
                          : 'Your account is restricted from new adoption applications. You can still view pet matches.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.getTextSecondary(ctx),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isBlacklisted
                          ? (isDark ? const Color(0xFF450A0A).withValues(alpha: 0.3) : const Color(0xFFFFF1F2))
                          : (isDark ? const Color(0xFF451A03).withValues(alpha: 0.3) : const Color(0xFFFFFBEB)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isBlacklisted
                            ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFFECDD3))
                            : (isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A)),
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
                            color: isBlacklisted ? AppTheme.errorColor : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          officialReason,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextPrimary(ctx),
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
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.getCardBorder(ctx)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SHELTER CONTACT & APPEALS',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF5EEAD4) : AppTheme.primaryDark,
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
                                  color: AppTheme.getTextPrimary(ctx),
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
                                  color: AppTheme.getTextPrimary(ctx),
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
                                  color: AppTheme.getTextPrimary(ctx),
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
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ApiService.clearSession();
                          if (mounted) {
                            Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          foregroundColor: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF475569),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Log Out',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Continue',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
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

  int _petListEntranceTrigger = 0;
  int _applicationsEntranceTrigger = 0;
  final GlobalKey<_HomeTabState> _homeTabKey = GlobalKey<_HomeTabState>();

  List<Widget> get _tabs => [
    _HomeTab(
      key: _homeTabKey,
      onSeeAllPressed: () {
        setState(() {
          _petListEntranceTrigger++;
          _selectedIndex = 1;
        });
      },
      onPetFinderPressed: () {
        setState(() {
          _petListEntranceTrigger++;
          _selectedIndex = 1;
        });
      },
      onViewApplicationsPressed: () {
        setState(() {
          _applicationsEntranceTrigger++;
          _selectedIndex = 2;
        });
      },
      onViewProfilePressed: () => setState(() => _selectedIndex = 3),
      onLifestyleFilter: (_) {
        setState(() {
          _petListEntranceTrigger++;
          _selectedIndex = 1;
        });
      },
      onSearchSubmitted: (_) {
        setState(() {
          _petListEntranceTrigger++;
          _selectedIndex = 1;
        });
      },
    ),
    PetListScreen(
      key: ValueKey('pet_list_$_petListEntranceTrigger'),
      entranceTrigger: _petListEntranceTrigger,
    ),
    MyApplicationsScreen(
      key: ValueKey('my_applications_$_applicationsEntranceTrigger'),
      initialFilter: 'all',
    ),
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
        backgroundColor: AppTheme.getBackgroundColor(context),
        extendBody: true,
        body: IndexedStack(
          index: _selectedIndex,
          children: _tabs,
        ),
        bottomNavigationBar: _buildFloatingBottomNav(context),
      ),
    );
  }

  Widget _buildFloatingBottomNav(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomMargin = bottomInset > 0 ? bottomInset + 4.0 : 16.0;
    final isDark = AppTheme.isDark(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: bottomMargin,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.94)
                    : Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.85),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFloatingNavItem(
                    index: 0,
                    label: 'Home',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                  ),
                  _buildFloatingNavItem(
                    index: 1,
                    label: 'Pet Match',
                    icon: Icons.auto_awesome_outlined,
                    activeIcon: Icons.auto_awesome_rounded,
                  ),
                  _buildFloatingNavItem(
                    index: 2,
                    label: 'Applications',
                    icon: Icons.assignment_outlined,
                    activeIcon: Icons.assignment_rounded,
                    hasBadge: _hasUnreadApplications,
                  ),
                  _buildFloatingNavItem(
                    index: 3,
                    label: 'Profile',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    bool hasBadge = false,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          final wasNotHome = _selectedIndex != 0;
          setState(() {
            if (index == 1) {
              _petListEntranceTrigger++;
            }
            if (index == 2) {
              _applicationsEntranceTrigger++;
            }
            _selectedIndex = index;
          });
          if (index == 0 && wasNotHome) {
            _homeTabKey.currentState?.reload();
          } else if (index == 2) {
            _markApplicationsAsViewed();
          } else if (index == 3) {
            ApiService.getProfile();
          }
        },
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12 : 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isSelected ? activeIcon : icon,
                      size: 21,
                      color: isSelected ? AppTheme.primary : AppTheme.getTextSecondary(context),
                    ),
                    if (hasBadge)
                      Positioned(
                        top: -2,
                        right: -3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4D4F),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primary : AppTheme.getTextSecondary(context),
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final VoidCallback? onSeeAllPressed;
  final VoidCallback? onPetFinderPressed;
  final VoidCallback? onViewApplicationsPressed;
  final VoidCallback? onViewProfilePressed;
  final ValueChanged<String>? onLifestyleFilter;
  final ValueChanged<String>? onSearchSubmitted;

  const _HomeTab({
    super.key,
    this.onSeeAllPressed,
    this.onPetFinderPressed,
    this.onViewApplicationsPressed,
    this.onViewProfilePressed,
    this.onLifestyleFilter,
    this.onSearchSubmitted,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _userName = 'Adopter';
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _vaccineReminders = [];
  bool _isLoading = true;
  bool _hasUnreadNotifications = false;
  bool _hasCompletedQuiz = false;

  void reload() {
    _loadDashboardData();
  }

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _loadDashboardData();
    NotificationService.setupFirebaseFCM();
  }

  Future<void> _loadCachedData() async {
    await _loadCachedUser();
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAppsStr = prefs.getString('cached_home_applications');
      final cachedRemindersStr = prefs.getString('cached_home_reminders');
      final cachedQuizLocked = prefs.getBool('cached_quiz_locked') ?? false;

      List<Map<String, dynamic>> cachedApps = [];
      List<Map<String, dynamic>> cachedReminders = [];

      if (cachedAppsStr != null && cachedAppsStr.isNotEmpty) {
        final decoded = jsonDecode(cachedAppsStr);
        if (decoded is List) {
          cachedApps = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }

      if (cachedRemindersStr != null && cachedRemindersStr.isNotEmpty) {
        final decoded = jsonDecode(cachedRemindersStr);
        if (decoded is List) {
          cachedReminders = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }

      if (mounted && (cachedApps.isNotEmpty || cachedReminders.isNotEmpty || cachedQuizLocked)) {
        setState(() {
          if (cachedApps.isNotEmpty) _applications = cachedApps;
          if (cachedReminders.isNotEmpty) _vaccineReminders = cachedReminders;
          if (cachedQuizLocked) _hasCompletedQuiz = true;
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  String _formatGreetingName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'adopter') return 'Adopter';
    final parts = trimmed.split(RegExp(r'\s+'));
    final first = parts.first;
    if (first.isEmpty) return 'Adopter';
    return '${first[0].toUpperCase()}${first.substring(1)}';
  }

  Future<void> _loadCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Try ApiService.getUser()
      final cached = await ApiService.getUser();
      if (cached != null) {
        final name = _extractNameFromMap(cached);
        if (name != null && name.isNotEmpty && mounted) {
          setState(() {
            _userName = _formatGreetingName(name);
            _userProfile = cached;
          });
          return;
        }
      }

      // 2. Direct string JSON keys in SharedPreferences
      for (final key in ['auth_user', 'user', 'user_profile', 'profile']) {
        final str = prefs.getString(key);
        if (str != null && str.isNotEmpty) {
          try {
            final decoded = jsonDecode(str);
            if (decoded is Map<String, dynamic>) {
              final name = _extractNameFromMap(decoded);
              if (name != null && name.isNotEmpty && mounted) {
                setState(() {
                  _userName = _formatGreetingName(name);
                  _userProfile = decoded;
                });
                return;
              }
            }
          } catch (_) {}
        }
      }

      // 3. Direct plaintext name keys in SharedPreferences
      for (final key in ['user_name', 'name', 'adopter_name', 'full_name', 'first_name']) {
        final val = prefs.getString(key)?.trim();
        if (val != null && val.isNotEmpty && val.toLowerCase() != 'null' && val.toLowerCase() != 'adopter') {
          if (mounted) {
            setState(() => _userName = _formatGreetingName(val));
            return;
          }
        }
      }
    } catch (_) {}
  }

  String? _extractNameFromMap(Map<String, dynamic>? data) {
    if (data == null) return null;

    // Check direct properties
    for (final key in ['name', 'full_name', 'first_name', 'adopter_name', 'applicant_name']) {
      final val = data[key]?.toString().trim();
      if (val != null && val.isNotEmpty && val.toLowerCase() != 'null' && val.toLowerCase() != 'adopter') {
        return val;
      }
    }

    // Check nested objects: 'user', 'data', 'profile', 'adopter'
    for (final parentKey in ['user', 'data', 'profile', 'adopter']) {
      if (data[parentKey] is Map) {
        final nested = data[parentKey] as Map;
        for (final key in ['name', 'full_name', 'first_name', 'adopter_name', 'applicant_name']) {
          final val = nested[key]?.toString().trim();
          if (val != null && val.isNotEmpty && val.toLowerCase() != 'null' && val.toLowerCase() != 'adopter') {
            return val;
          }
        }
      }
    }

    // Check username
    final username = data['username']?.toString().trim();
    if (username != null && username.isNotEmpty && username.toLowerCase() != 'null' && username.toLowerCase() != 'adopter') {
      return username;
    }

    // Check email prefix
    final email = data['email']?.toString().trim();
    if (email != null && email.contains('@')) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty && local.toLowerCase() != 'adopter') {
        return '${local[0].toUpperCase()}${local.substring(1)}';
      }
    }

    // If only 'name' exists even if it matches 'Adopter'
    final rawName = data['name']?.toString().trim();
    if (rawName != null && rawName.isNotEmpty && rawName.toLowerCase() != 'null') {
      return rawName;
    }

    return null;
  }

  Future<void> _loadDashboardData() async {
    // 1. Immediately ensure cached data is loaded first for instant display
    await _loadCachedData();

    // 2. Fetch fresh profile, applications, vaccine reminders, and compatibility preferences in parallel
    final profileFuture = ApiService.getProfile().catchError((_) => null);
    final appsFuture = ApiService.getMyApplications().catchError((_) => <Map<String, dynamic>>[]);
    final remindersFuture = ApiService.getVaccineReminders().catchError((_) => <Map<String, dynamic>>[]);
    final prefsFuture = ApiService.getSavedPreferences().catchError((_) => null);

    final results = await Future.wait([
      profileFuture,
      appsFuture,
      remindersFuture,
      prefsFuture,
    ]);

    final profile = results[0] as Map<String, dynamic>?;
    final apps = (results[1] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    final reminders = (results[2] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    final savedPrefs = results[3] as Map<String, dynamic>?;

    final bool hasQuiz = savedPrefs != null && savedPrefs['is_locked'] == true;

    if (!mounted) return;

    // Cache latest dashboard data for instant zero-lag rendering on future visits
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_home_applications', jsonEncode(apps));
      await prefs.setString('cached_home_reminders', jsonEncode(reminders));
      await prefs.setBool('cached_quiz_locked', hasQuiz);
    } catch (_) {}

    setState(() {
      _hasCompletedQuiz = hasQuiz;
      if (profile != null) {
        _userProfile = profile;
        final name = _extractNameFromMap(profile);
        if (name != null && name.isNotEmpty && name.toLowerCase() != 'adopter') {
          _userName = _formatGreetingName(name);
        }
      }

      _applications = apps;
      if (_userName.toLowerCase() == 'adopter' && apps.isNotEmpty) {
        for (final app in apps) {
          final applicantName = app['adopter_name'] ??
              app['applicant_name'] ??
              app['adopterName'] ??
              app['applicantName'] ??
              app['user']?['name'] ??
              app['user_name'];
          if (applicantName != null && applicantName.toString().trim().isNotEmpty) {
            final extracted = applicantName.toString().trim();
            if (extracted.toLowerCase() != 'adopter' && extracted.toLowerCase() != 'null') {
              _userName = _formatGreetingName(extracted);
              break;
            }
          }
        }
      }

      _vaccineReminders = reminders;
      _isLoading = false;
    });

    _checkUnreadNotificationsFromData(apps, reminders);
  }

  Future<void> _checkUnreadNotificationsFromData(
    List<Map<String, dynamic>> apps,
    List<Map<String, dynamic>> reminders,
  ) async {
    try {
      final user = await ApiService.getUser();
      if (user == null) return;
      final userId = user['id'];
      final prefs = await SharedPreferences.getInstance();
      final lastReadStr = prefs.getString('user_${userId}_last_read_notif_time');

      final hasUpcomingReminders = reminders.any((r) {
        final days = r['days_until_due'] as int? ?? 999;
        final isOverdue = r['is_overdue'] == true || days < 0;
        return isOverdue || days <= 30;
      });

      if (hasUpcomingReminders) {
        if (mounted) setState(() => _hasUnreadNotifications = true);
        return;
      }

      final hasActionableApps = apps.any((app) {
        final requiresNaming = app['requires_naming'] == true || app['requiresNaming'] == true;
        final status = (app['status'] as String? ?? '').toLowerCase();
        final isSigned = app['is_signed'] == true || app['is_pre_signed'] == true;
        final isFinalized = app['is_finalized'] == true || app['isFinalized'] == true;
        final isApprovedAwaitingSign = status == 'approved' && !isFinalized && !isSigned;
        final isKaponScheduled = app['kapon_status'] == 'scheduled';
        return requiresNaming || isApprovedAwaitingSign || isKaponScheduled;
      });

      if (hasActionableApps) {
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
        setState(() => _hasUnreadNotifications = hasNewUpdate);
      }
    } catch (_) {}
  }



  List<Map<String, dynamic>> get _adoptedPets {
    return _applications.where((app) {
      final status = (app['status'] as String? ?? '').toLowerCase();
      final isArchived = app['is_archived'] == true || app['isArchived'] == true;
      return (status == 'approved' || status == 'adopted') && !isArchived;
    }).toList();
  }

  // Direct Navigation Handlers
  void _openAiMatchmaker() {
    HapticFeedback.mediumImpact();
    if (_hasCompletedQuiz) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MatchQuizScreen(initialShowResults: true),
        ),
      ).then((_) => _loadDashboardData());
      return;
    }
    if (widget.onPetFinderPressed != null) {
      widget.onPetFinderPressed!();
    } else if (widget.onSeeAllPressed != null) {
      widget.onSeeAllPressed!();
    } else {
      Navigator.pushNamed(context, '/match-quiz').then((_) => _loadDashboardData());
    }
  }

  void _openMonthlyReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyAdoptedPetsScreen(
          isMonthlyReportMode: true,
          initialPets: _adoptedPets,
        ),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _openPetHub() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyAdoptedPetsScreen(
          isHealthCardMode: true,
          initialPets: _adoptedPets,
        ),
      ),
    ).then((_) => _loadDashboardData());
  }





  Widget _buildMinimalNotificationCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    VoidCallback? onTap,
  }) {
    final isDark = AppTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getCardBorder(context), width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Icon(icon, color: iconColor, size: 17),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.getTextPrimary(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2.5),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNamePetDialog(BuildContext context, Map<String, dynamic> app, String currentName) {
    final petId = app['pet_id'] ?? app['petId'] ?? app['pet']?['id'];
    if (petId == null) return;

    final controller = TextEditingController();
    bool isSaving = false;
    final isDark = AppTheme.isDark(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppTheme.getCardColor(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.drive_file_rename_outline_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Name Your Adopted Pet',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.getTextPrimary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Give your new family member their official name! This will appear on their digital certificate, vaccination book, and health hub.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.getTextPrimary(context),
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Bella, Milo, Rocky',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextSecondary : Colors.grey.shade400,
                        ),
                        prefixIcon: const Icon(Icons.pets_rounded, size: 18, color: AppTheme.primary),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.getCardBorder(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.getCardBorder(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              foregroundColor: isDark ? Colors.white : const Color(0xFF475569),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final entered = controller.text.trim();
                                    if (entered.isEmpty) return;

                                    setDialogState(() => isSaving = true);
                                    try {
                                      final parsedId = petId is int ? petId : int.parse(petId.toString());
                                      await ApiService.updatePetName(
                                        petId: parsedId,
                                        name: entered,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(dialogContext);
                                        _loadDashboardData();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Pet name updated to "$entered"',
                                              style: GoogleFonts.poppins(fontSize: 13),
                                            ),
                                            backgroundColor: AppTheme.successColor,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setDialogState(() => isSaving = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString().replaceAll('Exception: ', ''),
                                              style: GoogleFonts.poppins(fontSize: 13),
                                            ),
                                            backgroundColor: const Color(0xFFDC2626),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Save Name',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        final isDark = AppTheme.isDark(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppTheme.primary,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Notifications & Alerts',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(modalContext),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark ? const Color(0xFFE2E8F0) : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: AppTheme.getCardBorder(context)),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: ApiService.getMyApplications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const NotificationsModalSkeletonLoader();
                    }
                    final apps = snapshot.data ?? [];
                    final activeReminders = _vaccineReminders.where((r) {
                      final days = r['days_until_due'] as int? ?? 999;
                      final isOverdue = r['is_overdue'] == true || days < 0;
                      return isOverdue || days <= 30;
                    }).toList();

                    if (apps.isEmpty && activeReminders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No notifications right now',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'You are all caught up',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      children: [
                        if (activeReminders.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 2),
                            child: Text(
                              'HEALTH REMINDERS',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade500,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          ...activeReminders.map((reminder) {
                            final days = reminder['days_until_due'] as int? ?? 999;
                            final isOverdue = reminder['is_overdue'] == true || days < 0;
                            final dueLabel = reminder['next_due_label'] as String? ?? '';
                            final petName = reminder['pet_name'] as String? ?? 'Your pet';
                            final category = reminder['category'] as String? ?? 'Health';
                            final petId = reminder['pet_id'] as int?;

                            final bool isToday = days == 0;
                            final bool isTomorrow = days == 1;
                            final bool isUrgent = days <= 3;

                            final Color iconColor = (isOverdue || isToday)
                                ? const Color(0xFFDC2626)
                                : isUrgent
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFF0D9488);
                            final Color iconBg = (isOverdue || isToday)
                                ? const Color(0xFFFEF2F2)
                                : isUrgent
                                    ? const Color(0xFFFFF7ED)
                                    : const Color(0xFFF0FDFA);

                            final String badgeText = isOverdue
                                ? (days == -1 ? '1 day overdue' : '${-days} days overdue')
                                : isToday
                                    ? 'Due Today'
                                    : isTomorrow
                                        ? 'Tomorrow'
                                        : 'In $days days';
                            final Color badgeColor = (isOverdue || isToday)
                                ? const Color(0xFFDC2626)
                                : isUrgent
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFF0D9488);
                            final Color badgeBg = (isOverdue || isToday)
                                ? const Color(0xFFFEE2E2)
                                : isUrgent
                                    ? const Color(0xFFFFEDD5)
                                    : const Color(0xFFCCFBF1);

                            final String subtitle = isOverdue
                                ? '$category overdue since $dueLabel'
                                : isToday
                                    ? '$category due today ($dueLabel)'
                                    : isTomorrow
                                        ? '$category due tomorrow ($dueLabel)'
                                        : '$category due on $dueLabel';

                            return _buildMinimalNotificationCard(
                              icon: Icons.vaccines_rounded,
                              iconColor: iconColor,
                              iconBg: iconBg,
                              title: '$petName - $category',
                              subtitle: subtitle,
                              badgeText: badgeText,
                              badgeColor: badgeColor,
                              badgeBg: badgeBg,
                              onTap: petId != null
                                  ? () {
                                      Navigator.pop(modalContext);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PetMedicalCardScreen(
                                            petId: petId,
                                            petName: petName,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                            );
                          }),
                        ],

                        if (apps.isNotEmpty) ...[
                          if (activeReminders.isNotEmpty) const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 2),
                            child: Text(
                              'APPLICATION UPDATES',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade500,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          ...apps.map((item) {
                            final petName = item['petName'] as String? ?? 'Pet';
                            final isAdoptedByOther = (item['isAdoptedByOther'] as bool?) ?? false;
                            final status = (item['status'] as String? ?? '').toLowerCase();

                            if (isAdoptedByOther) {
                              return _buildMinimalNotificationCard(
                                icon: Icons.home_outlined,
                                iconColor: const Color(0xFFE11D48),
                                iconBg: const Color(0xFFFFF1F2),
                                title: '$petName - Application Closed',
                                subtitle: 'Pet found a home with another applicant',
                                badgeText: 'Closed',
                                badgeColor: const Color(0xFFE11D48),
                                badgeBg: const Color(0xFFFFE4E6),
                                onTap: null,
                              );
                            }

                            final isFinalized = item['is_finalized'] == true ||
                                item['isFinalized'] == true ||
                                item['contract_unlocked'] == true;

                            final isSigned = item['is_signed'] == true ||
                                item['is_pre_signed'] == true;

                            final requiresNaming = item['requires_naming'] == true ||
                                item['requiresNaming'] == true ||
                                (isFinalized && (
                                  petName.isEmpty ||
                                  petName.toLowerCase() == 'adopted pet' ||
                                  petName.toLowerCase() == 'rescued pet' ||
                                  petName.toLowerCase().startsWith('pet no.') ||
                                  petName.toLowerCase().startsWith('pet #')
                                ));

                            if ((status == 'approved' || status == 'adopted') && isFinalized) {
                              if (requiresNaming) {
                                return _buildMinimalNotificationCard(
                                  icon: Icons.drive_file_rename_outline_rounded,
                                  iconColor: const Color(0xFFEA580C),
                                  iconBg: const Color(0xFFFFF7ED),
                                  title: '$petName - Adoption Finalized!',
                                  subtitle: 'Handover complete! Tap to give your pet their official name.',
                                  badgeText: 'Name Pet',
                                  badgeColor: const Color(0xFFEA580C),
                                  badgeBg: const Color(0xFFFFEDD5),
                                  onTap: () {
                                    Navigator.pop(modalContext);
                                    _showNamePetDialog(context, item, petName);
                                  },
                                );
                              }

                              final kaponStatus = (item['kapon_status'] ?? '').toString().toLowerCase();
                              final kaponSchedDate = item['kapon_scheduled_date'] ?? item['kapon_scheduled_raw'];

                              if (kaponStatus == 'scheduled' && kaponSchedDate != null) {
                                return _buildMinimalNotificationCard(
                                  icon: Icons.event_available_rounded,
                                  iconColor: const Color(0xFF0284C7),
                                  iconBg: const Color(0xFFF0F9FF),
                                  title: '$petName - Kapon Scheduled',
                                  subtitle: 'Surgery set: $kaponSchedDate. Tap for pre-op instructions.',
                                  badgeText: 'Kapon Date',
                                  badgeColor: const Color(0xFF0284C7),
                                  badgeBg: const Color(0xFFE0F2FE),
                                  onTap: () {
                                    Navigator.pop(modalContext);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AdoptedPetHubScreen(application: item),
                                      ),
                                    );
                                  },
                                );
                              }

                              final String adoptedSubtitle = (kaponStatus == 'awaiting_schedule')
                                  ? 'Handover complete • Queued for shelter Kapon schedule'
                                  : 'Handover complete - Tap to view Health Hub & Records';

                              return _buildMinimalNotificationCard(
                                icon: Icons.pets_rounded,
                                iconColor: const Color(0xFF059669),
                                iconBg: const Color(0xFFECFDF5),
                                title: '$petName - Adoption Finalized',
                                subtitle: adoptedSubtitle,
                                badgeText: 'Adopted',
                                badgeColor: const Color(0xFF059669),
                                badgeBg: const Color(0xFFD1FAE5),
                                onTap: () {
                                  Navigator.pop(modalContext);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdoptedPetHubScreen(application: item),
                                    ),
                                  );
                                },
                              );
                            }

                            if (status == 'approved') {
                              final eventDate = item['scheduledAt'] ?? 'Sunday Event';
                              final bool isStudent = item['isStudent'] == true ||
                                  item['is_student'] == true ||
                                  item['employment_status']?.toString().toLowerCase() == 'student' ||
                                  item['employmentStatus']?.toString().toLowerCase() == 'student' ||
                                  (item['id_type']?.toString().toLowerCase().contains('student') ?? false) ||
                                  (item['id_type']?.toString().toLowerCase().contains('cor') ?? false);
                              final bool isRented = item['home_ownership']?.toString().toLowerCase() == 'rented' ||
                                  item['homeOwnership']?.toString().toLowerCase() == 'rented';
                              final idDocShort = isStudent ? 'Student ID/COR' : 'ID';
                              final resDocShort = isRented ? 'Proof of Residence' : 'Brgy Cert';

                              if (!isSigned) {
                                return _buildMinimalNotificationCard(
                                  icon: Icons.assignment_turned_in_outlined,
                                  iconColor: const Color(0xFF0D9488),
                                  iconBg: const Color(0xFFF0FDFA),
                                  title: '$petName - Application Approved!',
                                  subtitle: 'Approved! Tap to review and pre-sign your contract.',
                                  badgeText: 'Sign Contract',
                                  badgeColor: const Color(0xFF0D9488),
                                  badgeBg: const Color(0xFFCCFBF1),
                                  onTap: () {
                                    Navigator.pop(modalContext);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const MyApplicationsScreen(),
                                      ),
                                    );
                                  },
                                );
                              }

                              return _buildMinimalNotificationCard(
                                icon: Icons.event_available_rounded,
                                iconColor: const Color(0xFF0D9488),
                                iconBg: const Color(0xFFF0FDFA),
                                title: '$petName - Scheduled for Pickup',
                                subtitle: 'Event: $eventDate - Bring $idDocShort & $resDocShort',
                                badgeText: 'Approved',
                                badgeColor: const Color(0xFF0D9488),
                                badgeBg: const Color(0xFFCCFBF1),
                                onTap: () {
                                  Navigator.pop(modalContext);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MyApplicationsScreen(),
                                    ),
                                  );
                                },
                              );
                            }

                            if (status == 'rejected') {
                              return _buildMinimalNotificationCard(
                                icon: Icons.info_outline_rounded,
                                iconColor: const Color(0xFFDC2626),
                                iconBg: const Color(0xFFFEF2F2),
                                title: '$petName - Application Status',
                                subtitle: 'Application was not approved',
                                badgeText: 'Declined',
                                badgeColor: const Color(0xFFDC2626),
                                badgeBg: const Color(0xFFFEE2E2),
                                onTap: null,
                              );
                            }

                            if (status == 'under_review') {
                              return _buildMinimalNotificationCard(
                                icon: Icons.manage_search_rounded,
                                iconColor: const Color(0xFF2563EB),
                                iconBg: const Color(0xFFEFF6FF),
                                title: '$petName - In Review',
                                subtitle: 'Staff is reviewing your application details',
                                badgeText: 'In Review',
                                badgeColor: const Color(0xFF2563EB),
                                badgeBg: const Color(0xFFDBEAFE),
                                onTap: () {
                                  Navigator.pop(modalContext);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MyApplicationsScreen(),
                                    ),
                                  );
                                },
                              );
                            }

                            return _buildMinimalNotificationCard(
                              icon: Icons.hourglass_top_rounded,
                              iconColor: const Color(0xFFD97706),
                              iconBg: const Color(0xFFFFFBEB),
                              title: '$petName - Application Submitted',
                              subtitle: 'Awaiting review by CAWS shelter team',
                              badgeText: 'Submitted',
                              badgeColor: const Color(0xFFD97706),
                              badgeBg: const Color(0xFFFEF3C7),
                              onTap: () {
                                Navigator.pop(modalContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MyApplicationsScreen(),
                                  ),
                                );
                              },
                            );
                          }),
                        ],
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
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;
    // Usable body height between top status bar and bottom nav bar (~56px + bottom padding)
    final usableHeight = screenHeight - topPadding - bottomPadding - 56.0;

    // Remaining vertical space after accounting for fixed text and titles (~390px)
    final remainingHeight = (usableHeight - 390.0).clamp(130.0, 420.0);

    // Hero image height smoothly scales to occupy available space (145px on small screens, up to 215px on taller screens)
    final heroImageHeight = (remainingHeight * 0.62).clamp(145.0, 215.0);

    // Spacing between companion hero and adoption journey section
    final sectionGap = (remainingHeight * 0.08).clamp(12.0, 24.0);

    // Vertical padding inside journey cards
    final cardVerticalPadding = (remainingHeight * 0.025 + 9.5).clamp(12.0, 15.0);

    // Spacing between the two cards
    final cardGap = (remainingHeight * 0.03 + 7.0).clamp(9.0, 12.0);

    // Bottom padding below card 2 with extra clearance for floating navigation bar
    final bottomSpacing = (remainingHeight * 0.05 + 10.0).clamp(14.0, 26.0) + 85.0;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppTheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildModernHeader(context),
          SliverToBoxAdapter(
            child: _isLoading
                ? HomeSkeletonLoader(
                    heroImageHeight: heroImageHeight,
                    cardVerticalPadding: cardVerticalPadding,
                    cardGap: cardGap,
                    sectionGap: sectionGap,
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // 1. Companion Hero Section (Dog & Kitten Photo + Title + Desc + Button)
                        _buildCompanionHeroSection(context, imageHeight: heroImageHeight),
                        SizedBox(height: sectionGap),

                        // 2. "Your Adoption Journey" Section
                        Text(
                          'Your Adoption Journey',
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextPrimary(context),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Card 1: Monthly Report
                        _buildJourneyActionCard(
                          icon: Icons.assignment_turned_in_outlined,
                          title: 'Monthly Report',
                          subtitle: 'Submit recurring pet condition & welfare logs.',
                          onTap: _openMonthlyReports,
                          verticalPadding: cardVerticalPadding,
                        ),
                        SizedBox(height: cardGap),

                        // Card 2: Pet Health Updates
                        _buildJourneyActionCard(
                          icon: Icons.favorite_border_rounded,
                          title: 'Pet Health Updates',
                          subtitle: 'View relevant health details and reminders.',
                          onTap: _openPetHub,
                          verticalPadding: cardVerticalPadding,
                        ),
                        SizedBox(height: bottomSpacing),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Header matching the serene modern concept UI
  Widget _buildModernHeader(BuildContext context) {
    final avatarUrl = _userProfile?['avatar_url']?.toString() ??
        _userProfile?['avatar']?.toString() ??
        _userProfile?['profile']?['avatar_url']?.toString() ??
        _userProfile?['profile']?['avatar']?.toString() ??
        _userProfile?['adopter']?['avatar_url']?.toString();
    final hasValidAvatar = avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http');
    final isDark = AppTheme.isDark(context);

    return SliverToBoxAdapter(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to your adoption journey!',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getTextSecondary(context),
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Find your perfect match',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextPrimary(context),
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Notification Bell
                    GestureDetector(
                      onTap: _showNotificationsBottomSheet,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.getCardColor(context),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.getCardBorder(context)),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: AppTheme.getTextPrimary(context),
                                size: 20,
                              ),
                            ),
                            if (_hasUnreadNotifications)
                              Positioned(
                                top: 9,
                                right: 9,
                                child: Container(
                                  width: 7,
                                  height: 7,
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
                    const SizedBox(width: 8),
                    // User Profile Avatar
                    GestureDetector(
                      onTap: () => widget.onViewProfilePressed?.call(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: hasValidAvatar ? null : AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.getCardBorder(context)),
                          image: hasValidAvatar
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: hasValidAvatar
                            ? null
                            : Center(
                                child: Text(
                                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
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

  // Hero Companion Section with Shelter Photo & Call to Action Button
  Widget _buildCompanionHeroSection(BuildContext context, {required double imageHeight}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Auto-sliding Photo Carousel with rounded corners & pagination indicators
        CompanionHeroCarousel(height: imageHeight),
        const SizedBox(height: 10),

        // Ready to meet your companion?
        Text(
          _hasCompletedQuiz ? 'Your Matches Are Waiting' : 'Ready to meet your companion?',
          style: GoogleFonts.poppins(
            fontSize: 17.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextPrimary(context),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),

        // Descriptive copy
        Text(
          _hasCompletedQuiz
              ? 'Our matching system has curated pet recommendations tailored specifically to your lifestyle and household.'
              : 'Tell us about your lifestyle, living environment, and ability to care for a pet. Our matching system will recommend suitable pets for you.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: AppTheme.getTextSecondary(context),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),

        // Start Pet Matching Button / View Matches Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _openAiMatchmaker,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 52),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _hasCompletedQuiz ? Icons.pets_rounded : Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Text(
                  _hasCompletedQuiz ? 'View My Matches' : 'Start Pet Matching',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Adoption Journey Action Card (e.g. My Applications & Pet Health Updates)
  Widget _buildJourneyActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    double verticalPadding = 13.0,
  }) {
    final isDark = AppTheme.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getCardBorder(context), width: 1.1),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: AppTheme.primary,
                      size: 21,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextPrimary(context),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.getTextSecondary(context),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.getTextSecondary(context),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }






}

/// Auto-sliding companion hero carousel with smooth animated indicator dots.
class CompanionHeroCarousel extends StatefulWidget {
  final double height;
  const CompanionHeroCarousel({super.key, required this.height});

  @override
  State<CompanionHeroCarousel> createState() => _CompanionHeroCarouselState();
}

class _CompanionHeroCarouselState extends State<CompanionHeroCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  static const List<Map<String, String>> _slides = [
    {
      'image': 'assets/images/companion_hero.jpg',
      'credit': 'CAWS Shelter Team',
    },
    {
      'image': 'assets/images/companion_hero_2.jpg',
      'credit': 'CAWS Adoption Drive',
    },
    {
      'image': 'assets/images/companion_hero_3.jpg',
      'credit': 'CAWS Adopter',
    },
    {
      'image': 'assets/images/companion_hero_4.jpg',
      'credit': 'CAWS Adopter',
    },
    {
      'image': 'assets/images/companion_hero_5.jpg',
      'credit': 'CAWS Community Drive',
    },
    {
      'image': 'assets/images/companion_hero_6.jpg',
      'credit': 'CAWS Medical Mission',
    },
    {
      'image': 'assets/images/companion_hero_7.jpg',
      'credit': 'CAWS Free Vaccination',
    },
    {
      'image': 'assets/images/companion_hero_8.jpg',
      'credit': 'CAWS Pet Health Check',
    },
    {
      'image': 'assets/images/companion_hero_9.jpg',
      'credit': 'CAWS Free Clinic',
    },
    {
      'image': 'assets/images/companion_hero_10.jpg',
      'credit': 'CAWS Adopter',
    },
    {
      'image': 'assets/images/companion_hero_11.jpg',
      'credit': 'CAWS Rescue Kittens',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _startAutoSlide();
              },
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Image.asset(
                  slide['image']!,
                  width: double.infinity,
                  height: widget.height,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: double.infinity,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Icon(Icons.pets_rounded, size: 44, color: AppTheme.primary),
                    ),
                  ),
                );
              },
            ),

            // Subtle top gradient for logo badge contrast
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),

            // Small CAWS Logo Badge at top left
            Positioned(
              top: 9,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(1.5),
                      child: Image.asset(
                        'assets/images/caws_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CAWS',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.95),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Subtle bottom gradient for tag and indicator readability
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.50),
                    ],
                  ),
                ),
              ),
            ),

            // Photographer / Shelter Tag
            Positioned(
              bottom: 8,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _slides[_currentPage]['credit']!,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ),

            // Pagination indicator dots with active pill animation
            Positioned(
              bottom: 10,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_slides.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 1.8),
                    width: isActive ? 14 : 4.5,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
