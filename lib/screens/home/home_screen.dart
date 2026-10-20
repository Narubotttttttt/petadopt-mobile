import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/services/notification_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/ai_recommendation_hero.dart';
import 'package:mobile_petadopt/screens/pets/pet_list_screen.dart';
import 'package:mobile_petadopt/screens/adoption/my_applications_screen.dart';
import 'package:mobile_petadopt/screens/adoption/adopted_pet_hub_screen.dart';
import 'package:mobile_petadopt/screens/adoption/my_adopted_pets_screen.dart';
import 'package:mobile_petadopt/screens/adoption/pet_medical_card_screen.dart';
import 'package:mobile_petadopt/screens/profile/profile_screen.dart';
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

  String _matchesLifestyle = 'none';
  String _matchesSearch = '';
  final GlobalKey<_HomeTabState> _homeTabKey = GlobalKey<_HomeTabState>();

  List<Widget> get _tabs => [
    _HomeTab(
      key: _homeTabKey,
      onSeeAllPressed: () => setState(() => _selectedIndex = 1),
      onViewApplicationsPressed: () => setState(() => _selectedIndex = 2),
      onViewProfilePressed: () => setState(() => _selectedIndex = 3),
      onLifestyleFilter: (lifestyle) {
        setState(() {
          _matchesLifestyle = lifestyle;
          _selectedIndex = 1;
        });
      },
      onSearchSubmitted: (query) {
        setState(() {
          _matchesSearch = query;
          _selectedIndex = 1;
        });
      },
    ),
    PetListScreen(
      initialLifestyle: _matchesLifestyle,
      initialSearch: _matchesSearch,
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
        body: IndexedStack(
          index: _selectedIndex,
          children: _tabs,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              final wasNotHome = _selectedIndex != 0;
              setState(() {
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
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textSecondary,
            selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.auto_awesome_outlined),
                activeIcon: Icon(Icons.auto_awesome_rounded),
                label: 'Matches',
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
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final VoidCallback? onSeeAllPressed;
  final VoidCallback? onViewApplicationsPressed;
  final VoidCallback? onViewProfilePressed;
  final ValueChanged<String>? onLifestyleFilter;
  final ValueChanged<String>? onSearchSubmitted;

  const _HomeTab({
    super.key,
    this.onSeeAllPressed,
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
  Map<String, dynamic>? _preferences;
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

    // 3. Fetch saved preferences independently
    try {
      final prefs = await ApiService.getSavedPreferences();
      if (prefs != null && mounted) {
        setState(() => _preferences = prefs);
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
                        ? 'Your account has been banned from submitting adoption applications and taking match quizzes. You can view pet matches in read-only mode.'
                        : 'Your account is restricted from taking recommendation quizzes at this time.',
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

  List<Map<String, dynamic>> get _adoptedPets {
    return _applications.where((app) {
      final status = (app['status'] as String? ?? '').toLowerCase();
      final isFinalized = app['is_finalized'] == true ||
          app['isFinalized'] == true ||
          app['contract_unlocked'] == true;
      return (status == 'approved' || status == 'adopted') && isFinalized;
    }).toList();
  }

  List<Map<String, dynamic>> get _activeApplications {
    return _applications.where((app) {
      final status = (app['status'] as String? ?? '').toLowerCase();
      final isFinalized = app['is_finalized'] == true ||
          app['isFinalized'] == true ||
          app['contract_unlocked'] == true;
      final isAdoptedByOther = app['isAdoptedByOther'] == true;
      if (isAdoptedByOther || status == 'rejected') return false;
      if ((status == 'approved' || status == 'adopted') && isFinalized) return false;
      return status == 'pending' || status == 'under_review' || status == 'approved';
    }).toList();
  }

  bool get _hasCompletedAssessment => _preferences != null && _preferences!.isNotEmpty;

  // Direct Navigation Handlers for the 4 Dashboard Modules
  void _openAiMatchmaker() {
    widget.onSeeAllPressed?.call();
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

  void _openApplications() {
    if (widget.onViewApplicationsPressed != null) {
      widget.onViewApplicationsPressed!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
      );
    }
  }

  void _showNoAdoptedPetDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Understood',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSeeAllPressed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Find a Match',
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showPetSelectionSheet({
    required String title,
    required void Function(Map<String, dynamic> pet) onPetSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ..._adoptedPets.map((pet) {
                final name = pet['adoptedPetName']?.toString() ?? pet['proposedName']?.toString() ?? pet['petName']?.toString() ?? 'Pet';
                final code = pet['shelterPetCode']?.toString() ?? 'Rescue';
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2FE),
                    child: Icon(Icons.pets, color: AppTheme.primary),
                  ),
                  title: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(code, style: GoogleFonts.poppins(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    onPetSelected(pet);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLivingEnvironment(String? env) {
    if (env == null || env.isEmpty) return 'Not Configured';
    switch (env.toLowerCase()) {
      case 'apartment':
        return 'Apartment / Condo';
      case 'house_small_yard':
      case 'house_yard':
        return 'House w/ Yard';
      case 'house_large_yard':
        return 'House w/ Large Yard';
      case 'farm_rural':
        return 'Rural / Acreage';
      default:
        return env.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
  }

  String _formatHoursAlone(String? hours) {
    if (hours == null || hours.isEmpty) return 'Not Configured';
    switch (hours.toLowerCase()) {
      case 'under_2':
      case '<2':
        return '< 2 hrs / day';
      case '2_4':
        return '2 - 4 hrs / day';
      case '4_7':
        return '4 - 7 hrs / day';
      case '8_plus':
      case '8+':
        return '8+ hrs / day';
      default:
        return hours.replaceAll('_', ' ');
    }
  }

  String _formatActivityLevel(String? act) {
    if (act == null || act.isEmpty) return 'Not Configured';
    switch (act.toLowerCase()) {
      case 'low':
        return 'Calm & Relaxed';
      case 'moderate':
        return 'Moderate Routine';
      case 'active':
        return 'High Activity';
      case 'very_active':
        return 'Athletic / Outdoor';
      default:
        return act.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
  }

  String _formatPetExperience(String? exp) {
    if (exp == null || exp.isEmpty) return 'Not Configured';
    switch (exp.toLowerCase()) {
      case 'first_time':
        return 'First-Time Adopter';
      case 'some_experience':
      case 'intermediate':
        return 'Intermediate Owner';
      case 'experienced':
        return 'Experienced Parent';
      default:
        return exp.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
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
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildModernHeader(context),
              SliverToBoxAdapter(
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: CircularProgressIndicator(color: AppTheme.primary),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),

                            // 1. Urgent Health / Report Alert Banner (if due)
                            if (_vaccineReminders.isNotEmpty) ...[
                              _buildUrgentAlertBanner(context),
                              const SizedBox(height: 18),
                            ],

                            // 2. The 2x2 Pastel Dashboard Cards Grid
                            _buildDashboardGrid(context),
                            const SizedBox(height: 24),

                            // 3. Detailed Sections
                            _buildCapabilityProfilePreview(context),
                            const SizedBox(height: 20),

                            const SizedBox(height: 90), // Spacing for floating Meta AI button
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),

        // Floating Meta AI Matchmaker Button with Animated Eyes
        Positioned(
          bottom: 18,
          right: 16,
          child: _buildFloatingAiButton(),
        ),
      ],
    );
  }

  // Header inspired by modern dashboard design
  Widget _buildModernHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $_userName 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5.5),
                          Text(
                            'CAWS Sanctuary • Welfare First',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF047857),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _showNotificationsBottomSheet,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF1E293B),
                          size: 22,
                        ),
                      ),
                      if (_hasUnreadNotifications)
                        Positioned(
                          top: 11,
                          right: 11,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4D4F),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // The 2x2 Dashboard Cards Grid (Matches Reference Image Structure & Colors)
  Widget _buildDashboardGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // 1. Top-Left: Pet Finder (Soft Lavender / Lilac)
            Expanded(
              child: _buildPastelCard(
                title: 'Pet Finder',
                subtitle: 'Lifestyle & Compatibility',
                statusPill: _hasCompletedAssessment ? 'Matches Ready' : 'Quiz Pending',
                icon: Icons.auto_awesome,
                gradientColors: const [Color(0xFFEDE9FE), Color(0xFFF3E8FF)],
                borderColor: const Color(0xFFDDD6FE),
                accentColor: const Color(0xFF7C3AED),
                onTap: _openAiMatchmaker,
              ),
            ),
            const SizedBox(width: 14),

            // 2. Top-Right: Monthly Report (Soft Pastel Rose / Berry, No Harsh Red)
            Expanded(
              child: _buildPastelCard(
                title: 'Monthly Report',
                subtitle: 'Photo & Weight Logs',
                statusPill: _adoptedPets.isNotEmpty ? 'Check-in' : 'Care Logs',
                icon: Icons.assignment_turned_in_rounded,
                gradientColors: const [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
                borderColor: const Color(0xFFFBCFE8),
                accentColor: const Color(0xFFBE185D),
                onTap: _openMonthlyReports,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            // 3. Bottom-Left: Pet Care Hub (Soft Sky / Mint)
            Expanded(
              child: _buildPastelCard(
                title: 'Pet Care Hub',
                subtitle: 'Health Card & Medical History',
                statusPill: _adoptedPets.isNotEmpty ? '${_adoptedPets.length} Health Card' : 'Health Card',
                icon: Icons.medical_services_rounded,
                gradientColors: const [Color(0xFFE0F2FE), Color(0xFFF0FDFA)],
                borderColor: const Color(0xFFBAE6FD),
                accentColor: const Color(0xFF0284C7),
                onTap: _openPetHub,
              ),
            ),
            const SizedBox(width: 14),

            // 4. Bottom-Right: Applications & Contract (Soft Warm Amber / Peach)
            Expanded(
              child: _buildPastelCard(
                title: 'Applications',
                subtitle: 'Status & Legal Contract',
                statusPill: _activeApplications.isNotEmpty ? '${_activeApplications.length} In Review' : 'View Queue',
                icon: Icons.description_rounded,
                gradientColors: const [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
                borderColor: const Color(0xFFFDE68A),
                accentColor: const Color(0xFFD97706),
                onTap: _openApplications,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Modular Pastel Dashboard Card (Polished Premium Aesthetic)
  Widget _buildPastelCard({
    required String title,
    required String subtitle,
    required String statusPill,
    required IconData icon,
    required List<Color> gradientColors,
    required Color borderColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 164,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor.withValues(alpha: 0.9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: accentColor.withValues(alpha: 0.1),
          highlightColor: accentColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Single Primary Icon squircle
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor.withValues(alpha: 0.7)),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                ),

                // Middle: Title & Subtitle with high-contrast typography
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                // Bottom: Clean Status Pill with accent indicator dot
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: borderColor.withValues(alpha: 0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5.5,
                        height: 5.5,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          statusPill,
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
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


  // Capability Metrics Preview
  Widget _buildCapabilityProfilePreview(BuildContext context) {
    final livingEnv = _formatLivingEnvironment(_preferences?['living_environment']?.toString());
    final hoursAlone = _formatHoursAlone(_preferences?['hours_alone']?.toString());
    final activity = _formatActivityLevel(_preferences?['activity_level']?.toString());
    final experience = _formatPetExperience(_preferences?['pet_experience']?.toString());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Center(
                        child: Icon(Icons.tune_rounded, size: 17, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Capability Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Lifestyle Compatibility',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final isBanned = await _checkBanNoticeForAction(actionDescription: 'update capability quiz');
                  if (isBanned || !context.mounted) return;
                  await Navigator.pushNamed(context, '/match-quiz');
                  _loadDashboardData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, size: 11, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Retake',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildMiniMetric('Space', livingEnv, Icons.apartment_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniMetric('Availability', hoursAlone, Icons.schedule_rounded)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMiniMetric('Routine', activity, Icons.directions_run_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniMetric('Experience', experience, Icons.military_tech_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF2F7), width: 0.9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                ),
                child: Icon(icon, size: 11, color: const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }




  // Floating Meta AI Button
  Widget _buildFloatingAiButton() {
    return GestureDetector(
      onTap: _openAiMatchmaker,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF22C55E).withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.38),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: OverflowBox(
                  maxWidth: 52,
                  maxHeight: 52,
                  child: LuminousAiOrb(size: 30),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pet Finder',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Tap to find companion',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
