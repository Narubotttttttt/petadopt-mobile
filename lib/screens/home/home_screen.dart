import 'dart:async';
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
          _matchesLifestyle = 'none';
          _matchesSearch = '';
          _petListEntranceTrigger++;
          _selectedIndex = 1;
        });
      },
      onViewApplicationsPressed: () => setState(() => _selectedIndex = 2),
      onViewProfilePressed: () => setState(() => _selectedIndex = 3),
      onLifestyleFilter: (lifestyle) {
        setState(() {
          _matchesLifestyle = lifestyle;
          _petListEntranceTrigger++;
          _selectedIndex = 1;
        });
      },
      onSearchSubmitted: (query) {
        setState(() {
          _matchesSearch = query;
          _petListEntranceTrigger++;
          _selectedIndex = 1;
        });
      },
    ),
    PetListScreen(
      key: ValueKey('pet_list_$_petListEntranceTrigger'),
      initialLifestyle: _matchesLifestyle,
      initialSearch: _matchesSearch,
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
        backgroundColor: const Color(0xFFF8FAFC),
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
                if (index == 1 && _selectedIndex != 1) {
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
  Map<String, dynamic>? _preferences;
  List<Map<String, dynamic>> _applications = [];
  List<Map<String, dynamic>> _vaccineReminders = [];
  bool _isLoading = true;
  bool _hasUnreadNotifications = false;

  // Expandable Meta AI Button state
  bool _isAiButtonExpanded = false;
  Timer? _collapseTimer;

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

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
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
    HapticFeedback.mediumImpact();
    if (widget.onPetFinderPressed != null) {
      widget.onPetFinderPressed!();
    } else if (widget.onSeeAllPressed != null) {
      widget.onSeeAllPressed!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PetListScreen(
            key: ValueKey('pet_list_${DateTime.now().millisecondsSinceEpoch}'),
            entranceTrigger: DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );
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
        NotificationListener<ScrollNotification>(
          onNotification: (_) {
            if (_isAiButtonExpanded) {
              _collapseTimer?.cancel();
              setState(() => _isAiButtonExpanded = false);
            }
            return false;
          },
          child: RefreshIndicator(
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

                            // 2. Quick Actions Section Header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 3.5,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        'QUICK ACTIONS',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF334155),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '4 Services',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 3. The 2x2 Modular Action Cards Grid
                            _buildDashboardGrid(context),
                            const SizedBox(height: 22),

                            // 4. Application Tracker Section Header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 3.5,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        'APPLICATION TRACKER',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF334155),
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_applications.isNotEmpty)
                                    GestureDetector(
                                      onTap: _openApplications,
                                      child: Text(
                                        'View All (${_applications.length}) →',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 5. Application Tracker Card
                            _buildApplicationTrackerCard(context),
                            const SizedBox(height: 90), // Spacing for floating Meta AI button
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),

        // Floating Meta AI Button pinned to bottom-right corner (expands on tap)
        Positioned(
          bottom: 18,
          right: 16,
          child: _buildFloatingAiButton(),
        ),
      ],
    );
  }

  // Header inspired by Tarsi app design
  Widget _buildModernHeader(BuildContext context) {
    final avatarUrl = _userProfile?['avatar_url']?.toString() ??
        _userProfile?['avatar']?.toString() ??
        _userProfile?['profile']?['avatar_url']?.toString() ??
        _userProfile?['profile']?['avatar']?.toString() ??
        _userProfile?['adopter']?['avatar_url']?.toString();
    final hasValidAvatar = avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http');

    return SliverToBoxAdapter(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF094C51),
                    Color(0xFF0E7A80),
                    Color(0xFF138A91),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF094C51).withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Soft ambient glow in top-right corner
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                widget.onViewProfilePressed?.call();
                              },
                              child: Row(
                                children: [
                                  // Avatar squircle
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: hasValidAvatar ? null : Colors.white.withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                      image: hasValidAvatar
                                          ? DecorationImage(
                                              image: NetworkImage(avatarUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
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
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Welcome back,',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(alpha: 0.78),
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _userName.isNotEmpty ? _userName : 'Adopter',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -0.4,
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
                          ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showNotificationsBottomSheet,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          if (_hasUnreadNotifications)
                            Positioned(
                              top: 10,
                              right: 10,
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
),
);
  }

  // The 2x2 Dashboard Cards Grid (Tarsi Modular Actions)
  Widget _buildDashboardGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // 1. Top-Left: Pet Finder (Tarsi Teal)
            Expanded(
              child: _buildPastelCard(
                title: 'Pet Finder',
                subtitle: 'AI Match & Lifestyle',
                statusPill: _hasCompletedAssessment ? 'Matches Ready' : 'Quiz Pending',
                icon: Icons.auto_awesome,
                accentColor: const Color(0xFF0E7A80),
                onTap: _openAiMatchmaker,
              ),
            ),
            const SizedBox(width: 14),

            // 2. Top-Right: Monthly Report (Rose / Berry)
            Expanded(
              child: _buildPastelCard(
                title: 'Monthly Report',
                subtitle: 'Photo & Weight Logs',
                statusPill: _adoptedPets.isNotEmpty ? 'Check-in' : 'Care Logs',
                icon: Icons.assignment_turned_in_rounded,
                accentColor: const Color(0xFFBE185D),
                onTap: _openMonthlyReports,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            // 3. Bottom-Left: Pet Care Hub (Sky Blue)
            Expanded(
              child: _buildPastelCard(
                title: 'Pet Care Hub',
                subtitle: 'Health Card & Records',
                statusPill: _adoptedPets.isNotEmpty ? '${_adoptedPets.length} Health Cards' : 'Health Cards',
                icon: Icons.medical_services_rounded,
                accentColor: const Color(0xFF0284C7),
                onTap: _openPetHub,
              ),
            ),
            const SizedBox(width: 14),

            // 4. Bottom-Right: Applications & Contract (Warm Amber)
            Expanded(
              child: _buildPastelCard(
                title: 'Applications',
                subtitle: 'Status & Legal Contract',
                statusPill: _activeApplications.isNotEmpty ? '${_activeApplications.length} In Review' : 'View Queue',
                icon: Icons.description_rounded,
                accentColor: const Color(0xFFD97706),
                onTap: _openApplications,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Modular Tarsi-Style Dashboard Card
  Widget _buildPastelCard({
    required String title,
    required String subtitle,
    required String statusPill,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 154,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: accentColor.withValues(alpha: 0.1),
          highlightColor: accentColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Primary Icon squircle + Arrow indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.14),
                            accentColor.withValues(alpha: 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: accentColor.withValues(alpha: 0.22), width: 1),
                      ),
                      child: Center(
                        child: Icon(icon, color: accentColor, size: 20),
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor.withValues(alpha: 0.16), width: 0.8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_outward_rounded,
                          size: 13,
                          color: accentColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
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
                        color: const Color(0xFF64748B),
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
                    color: accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: accentColor.withValues(alpha: 0.22), width: 0.8),
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


  // Application Tracker Card
  Widget _buildApplicationTrackerCard(BuildContext context) {
    if (_applications.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.description_outlined, color: AppTheme.primary, size: 22),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No Applications Yet',
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Find a rescue companion and submit an adoption request to track its review progress here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF64748B),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: _openAiMatchmaker,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Find a Match →',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Pick the most relevant application to highlight
    final primaryApp = _applications.firstWhere(
      (app) {
        final s = (app['status'] as String? ?? '').toLowerCase();
        return s == 'approved' || s == 'under_review' || s == 'pending';
      },
      orElse: () => _applications.first,
    );

    final rawStatus = (primaryApp['status'] as String? ?? 'pending').toLowerCase();
    final isAdoptedByOther = primaryApp['isAdoptedByOther'] == true;
    final isScheduled = (primaryApp['scheduledAt']?.toString() ?? '').isNotEmpty;
    final isSigned = primaryApp['is_signed'] == true ||
        (primaryApp['signature_url'] != null && primaryApp['signature_url'].toString().isNotEmpty);
    final isFinalized = primaryApp['is_finalized'] == true || primaryApp['contract_unlocked'] == true;

    int currentStep = 1; // 0: Submitted, 1: Review, 2: Interview, 3: Finalized
    String statusLabel = 'In Review';
    Color statusColor = const Color(0xFF0284C7);
    Color statusBg = const Color(0xFFE0F2FE);
    String statusMessage = 'Application under evaluation by CAWS adoption staff.';

    if (isAdoptedByOther || rawStatus == 'rejected') {
      statusLabel = 'Declined';
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEE2E2);
      currentStep = 1;
      statusMessage = 'Application was not approved by the shelter.';
    } else if (rawStatus == 'adopted' || (rawStatus == 'approved' && isFinalized)) {
      statusLabel = 'Adopted';
      statusColor = const Color(0xFF0D9488);
      statusBg = const Color(0xFFCCFBF1);
      currentStep = 3;
      statusMessage = 'Adoption finalized! Companion is officially in your care.';
    } else if (rawStatus == 'approved') {
      statusLabel = isSigned ? 'Contract Signed' : 'Pre-Approved';
      statusColor = const Color(0xFF10B981);
      statusBg = const Color(0xFFD1FAE5);
      currentStep = isSigned ? 3 : 2;
      statusMessage = isSigned
          ? 'Contract submitted. Awaiting shelter final release.'
          : 'Congratulations! Please review and sign the adoption agreement.';
    } else if (isScheduled) {
      statusLabel = 'Visit Scheduled';
      statusColor = const Color(0xFF7C3AED);
      statusBg = const Color(0xFFEDE9FE);
      currentStep = 2;
      statusMessage = 'Interview / home visit scheduled. Tap to view schedule details.';
    } else if (rawStatus == 'under_review') {
      statusLabel = 'In Review';
      statusColor = const Color(0xFF0284C7);
      statusBg = const Color(0xFFE0F2FE);
      currentStep = 1;
      statusMessage = 'Staff is actively reviewing your adoption questionnaire.';
    } else {
      statusLabel = 'Pending';
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      currentStep = 1;
      statusMessage = 'Application queued for review by shelter coordinators.';
    }

    final petName = (primaryApp['adoptedPetName'] ?? primaryApp['proposedName'] ?? primaryApp['petName'] ?? primaryApp['pet']?['name'])?.toString() ?? 'Companion';
    final petBreed = primaryApp['shelterPetCode']?.toString() ?? primaryApp['petBreed']?.toString() ?? primaryApp['pet']?['breed']?.toString() ?? 'Adoption Request';
    final rawPetImage = primaryApp['petImage'] ?? primaryApp['pet']?['image'];
    final petImage = ApiService.normalizeImageUrl(rawPetImage as String?);

    return Container(
      width: double.infinity,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openApplications,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Pet Image, Names, Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        color: const Color(0xFFF1F5F9),
                        child: petImage.isNotEmpty
                            ? Image.network(
                                petImage,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.pets_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 22,
                                ),
                              )
                            : const Icon(
                                Icons.pets_rounded,
                                color: Color(0xFF94A3B8),
                                size: 22,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            petName,
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            petBreed,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stepper Row: 4 visual milestones
                _buildTrackerStepper(currentStep, isDeclined: rawStatus == 'rejected' || isAdoptedByOther),
                const SizedBox(height: 14),

                // Bottom Status Banner with CTA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        rawStatus == 'rejected' || isAdoptedByOther
                            ? Icons.info_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 15,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusMessage,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Details →',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
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

  // Visual Stepper for Application Progress
  Widget _buildTrackerStepper(int currentStep, {bool isDeclined = false}) {
    final steps = ['Submitted', 'Review', 'Interview', 'Finalize'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBefore = index ~/ 2;
          final isCompleted = !isDeclined && stepBefore < currentStep;
          return Expanded(
            child: Container(
              height: 2.5,
              decoration: BoxDecoration(
                color: isCompleted ? AppTheme.primary : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }

        // Step node
        final stepIndex = index ~/ 2;
        final isCompleted = !isDeclined && stepIndex < currentStep;
        final isCurrent = !isDeclined && stepIndex == currentStep;
        final isStepDeclined = isDeclined && stepIndex == currentStep;

        final Color circleColor = isStepDeclined
            ? const Color(0xFFDC2626)
            : isCompleted || isCurrent
                ? AppTheme.primary
                : const Color(0xFFCBD5E1);

        final Color circleBg = isStepDeclined
            ? const Color(0xFFFEE2E2)
            : isCompleted
                ? AppTheme.primary
                : isCurrent
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : const Color(0xFFF1F5F9);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: circleColor,
                  width: isCurrent ? 2 : 1.5,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              steps[stepIndex],
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isCurrent || isCompleted ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                letterSpacing: -0.2,
              ),
            ),
          ],
        );
      }),
    );
  }




  // Floating Meta AI Button pinned to bottom-right corner (expands to "Find a pet?" on tap)
  Widget _buildFloatingAiButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        if (!_isAiButtonExpanded) {
          // 1st Tap: Expand and show "Find a pet?"
          setState(() {
            _isAiButtonExpanded = true;
          });
          _collapseTimer?.cancel();
          _collapseTimer = Timer(const Duration(seconds: 5), () {
            if (mounted && _isAiButtonExpanded) {
              setState(() {
                _isAiButtonExpanded = false;
              });
            }
          });
        } else {
          // 2nd Tap (or tapping while expanded): Launch Pet Finder
          _collapseTimer?.cancel();
          setState(() {
            _isAiButtonExpanded = false;
          });
          _openAiMatchmaker();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 52,
        padding: EdgeInsets.symmetric(
          horizontal: _isAiButtonExpanded ? 8 : 0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: _isAiButtonExpanded
              ? const LinearGradient(
                  colors: [
                    Color(0xFF093B3E),
                    Color(0xFF0A4F54),
                    Color(0xFF0F766E),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : const RadialGradient(
                  colors: [
                    Color(0xFF0F766E),
                    Color(0xFF0A4F54),
                    Color(0xFF093B3E),
                  ],
                  center: Alignment(-0.2, -0.3),
                  radius: 0.95,
                ),
          border: Border.all(
            color: const Color(0xFF2DD4BF).withValues(alpha: 0.85),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14B8A6).withValues(alpha: _isAiButtonExpanded ? 0.5 : 0.42),
              blurRadius: _isAiButtonExpanded ? 20 : 16,
              spreadRadius: _isAiButtonExpanded ? 1 : 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: const Center(
                child: IgnorePointer(
                  child: OverflowBox(
                    maxWidth: 48,
                    maxHeight: 48,
                    child: LuminousAiOrb(size: 32),
                  ),
                ),
              ),
            ),
            ClipRect(
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 240),
                firstCurve: Curves.easeOutCubic,
                secondCurve: Curves.easeInCubic,
                crossFadeState: _isAiButtonExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: 0, height: 0),
                secondChild: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    Text(
                      'Find a pet?',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DD4BF).withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: Color(0xFF2DD4BF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
