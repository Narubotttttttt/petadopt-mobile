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
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 12),
            actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            title: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isBlacklisted ? const Color(0xFFFFEAEA) : const Color(0xFFFFFBEB),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.block_rounded,
                      color: isBlacklisted ? AppTheme.errorColor : AppTheme.warningColor,
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
                    color: AppTheme.textPrimary,
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
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
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
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ApiService.clearSession();
                        if (mounted) {
                          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF475569),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Log Out',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF475569),
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

  int _petListEntranceTrigger = 0;
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
      onViewApplicationsPressed: () => setState(() => _selectedIndex = 2),
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
        backgroundColor: Colors.white,
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
              color: const Color(0xFF0F172A).withValues(alpha: 0.12),
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
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
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
                      color: isSelected ? AppTheme.primary : const Color(0xFF64748B),
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
                    color: isSelected ? AppTheme.primary : const Color(0xFF64748B),
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

  void reload() {
    _loadDashboardData();
  }

  @override
  void initState() {
    super.initState();
    _loadCachedUser();
    _loadDashboardData();
    NotificationService.setupFirebaseFCM();
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
    // 1. Immediately ensure cached user is applied
    await _loadCachedUser();

    // 2. Fetch fresh profile independently
    try {
      final profile = await ApiService.getProfile();
      if (profile != null) {
        final name = _extractNameFromMap(profile);
        if (mounted) {
          setState(() {
            _userProfile = profile;
            if (name != null && name.isNotEmpty && name.toLowerCase() != 'adopter') {
              _userName = _formatGreetingName(name);
            }
          });
        }
      }
    } catch (_) {}


    // 4. Fetch applications independently (and extract applicant name if still fallback!)
    List<Map<String, dynamic>> apps = [];
    try {
      apps = await ApiService.getMyApplications();
      if (mounted) {
        setState(() {
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
        });
      }
    } catch (_) {}

    // 5. Fetch vaccine reminders independently
    List<Map<String, dynamic>> reminders = [];
    try {
      reminders = await ApiService.getVaccineReminders();
      if (mounted) {
        setState(() => _vaccineReminders = reminders);
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      _checkUnreadNotificationsFromData(apps, reminders);
    }
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
        setState(() => _hasUnreadNotifications = hasNewUpdate);
      }
    } catch (_) {}
  }



  List<Map<String, dynamic>> get _adoptedPets {
    return _applications.where((app) {
      final status = (app['status'] as String? ?? '').toLowerCase();
      final isFinalized = app['is_finalized'] == true ||
          app['isFinalized'] == true ||
          app['contract_unlocked'] == true;
      return (status == 'approved' || status == 'adopted') && isFinalized;
    }).toList();
  }

  // Direct Navigation Handlers
  void _openAiMatchmaker() {
    HapticFeedback.mediumImpact();
    if (widget.onPetFinderPressed != null) {
      widget.onPetFinderPressed!();
    } else if (widget.onSeeAllPressed != null) {
      widget.onSeeAllPressed!();
    } else {
      Navigator.pushNamed(context, '/match-quiz');
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
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
                                color: AppTheme.textPrimary,
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
          height: MediaQuery.of(context).size.height * 0.70,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
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
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(modalContext),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: ApiService.getMyApplications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
                      );
                    }
                    final apps = snapshot.data ?? [];
                    if (apps.isEmpty && _vaccineReminders.isEmpty) {
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
                        if (_vaccineReminders.isNotEmpty) ...[
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
                          ..._vaccineReminders.map((reminder) {
                            final days = reminder['days_until_due'] as int? ?? 999;
                            final dueLabel = reminder['next_due_label'] as String? ?? '';
                            final petName = reminder['pet_name'] as String? ?? 'Your pet';
                            final category = reminder['category'] as String? ?? 'Health';
                            final petId = reminder['pet_id'] as int?;

                            final bool isToday = days == 0;
                            final bool isTomorrow = days == 1;
                            final bool isUrgent = days <= 3;

                            final Color iconColor = isToday
                                ? const Color(0xFFDC2626)
                                : isUrgent
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFF0D9488);
                            final Color iconBg = isToday
                                ? const Color(0xFFFEF2F2)
                                : isUrgent
                                    ? const Color(0xFFFFF7ED)
                                    : const Color(0xFFF0FDFA);

                            final String badgeText = isToday
                                ? 'Due Today'
                                : isTomorrow
                                    ? 'Tomorrow'
                                    : 'In $days days';
                            final Color badgeColor = isToday
                                ? const Color(0xFFDC2626)
                                : isUrgent
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFF0D9488);
                            final Color badgeBg = isToday
                                ? const Color(0xFFFEE2E2)
                                : isUrgent
                                    ? const Color(0xFFFFEDD5)
                                    : const Color(0xFFCCFBF1);

                            final String subtitle = isToday
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
                          if (_vaccineReminders.isNotEmpty) const SizedBox(height: 10),
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
                                title: '$petName - Adopted',
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

                            if ((status == 'approved' || status == 'adopted') && isFinalized) {
                              return _buildMinimalNotificationCard(
                                icon: Icons.pets_rounded,
                                iconColor: const Color(0xFF059669),
                                iconBg: const Color(0xFFECFDF5),
                                title: '$petName - Adopted',
                                subtitle: 'Handover complete - Tap to view Health Hub',
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
                              return _buildMinimalNotificationCard(
                                icon: Icons.assignment_turned_in_outlined,
                                iconColor: const Color(0xFF0D9488),
                                iconBg: const Color(0xFFF0FDFA),
                                title: '$petName - Pre-Approved',
                                subtitle: 'Event: $eventDate - Bring ID & Brgy Cert',
                                badgeText: 'Pre-Approved',
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
                                title: '$petName - Application',
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
                                subtitle: 'Staff is reviewing your application',
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
                              title: '$petName - Pending',
                              subtitle: 'Awaiting review by CAWS staff',
                              badgeText: 'Pending',
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

                        // Urgent Health Alert Banner (if any due reminders)
                        if (_vaccineReminders.isNotEmpty) ...[
                          _buildUrgentAlertBanner(context),
                          const SizedBox(height: 10),
                        ],

                        // 1. Companion Hero Section (Dog & Kitten Photo + Title + Desc + Button)
                        _buildCompanionHeroSection(context, imageHeight: heroImageHeight),
                        SizedBox(height: sectionGap),

                        // 2. "Your Adoption Journey" Section
                        Text(
                          'Your Adoption Journey',
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
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

    return SliverToBoxAdapter(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
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
                          color: AppTheme.textSecondary,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Find your perfect match',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: AppTheme.textPrimary,
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
                          border: Border.all(color: AppTheme.cardBorder),
                          image: hasValidAvatar
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          boxShadow: [
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
          'Ready to meet your companion?',
          style: GoogleFonts.poppins(
            fontSize: 17.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),

        // Descriptive copy
        Text(
          'Tell us about your lifestyle, living environment, and ability to care for a pet. Our matching system will recommend suitable pets for you.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF475569),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),

        // Start Pet Matching Button
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
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Text(
                  'Start Pet Matching',
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1.1),
        boxShadow: [
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
                    color: AppTheme.primaryLight,
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
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }





  // Urgent Alert Banner
  Widget _buildUrgentAlertBanner(BuildContext context) {
    final topReminder = _vaccineReminders.first;
    final petName = topReminder['pet_name'] as String? ?? 'Your adopted companion';
    final category = topReminder['category'] as String? ?? 'Vaccine / Check-in';
    final days = topReminder['days_until_due'] as int? ?? 999;
    final petId = topReminder['pet_id'] as int?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(Icons.vaccines_rounded, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$petName • $category Due in $days d',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                Text(
                  'Keep veterinary schedule active to fulfill adoption agreement.',
                  style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF78350F), height: 1.25),
                ),
              ],
            ),
          ),
          if (petId != null)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PetMedicalCardScreen(petId: petId, petName: petName),
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Passport →',
                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFD97706)),
              ),
            ),
        ],
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
      'credit': 'heldermartins',
    },
    {
      'image': 'assets/images/companion_hero_2.jpg',
      'credit': 'caws_rescue',
    },
    {
      'image': 'assets/images/companion_hero_3.jpg',
      'credit': 'caws_rescue',
    },
    {
      'image': 'assets/images/companion_hero_4.jpg',
      'credit': 'caws_adopter',
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
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: isActive ? 18 : 6,
                    height: 6,
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
