import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/services/notification_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/pet_recommendation_loader.dart';
import 'package:mobile_petadopt/widgets/pet_card.dart';
import 'package:mobile_petadopt/screens/pets/pet_list_screen.dart';
import 'package:mobile_petadopt/screens/adoption/my_applications_screen.dart';
import 'package:mobile_petadopt/screens/adoption/adopted_pet_hub_screen.dart';
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
                      ? 'Your account has been banned from submitting adoption applications. You can still view pet compatibility matches in read-only mode.'
                      : 'Your account is restricted from new adoption applications. You can still view pet matches.',
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
            } else if (index == 3) {
              ApiService.getProfile();
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
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  bool _hasUnreadNotifications = false;
  List<Map<String, dynamic>> _vaccineReminders = [];
  String _selectedCategory = 'all';

  bool _hasCheckedExplorationModal = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchRecommendations();
    _checkUnreadNotifications();
    NotificationService.setupFirebaseFCM();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      _checkExplorationModal();
    });
  }

  void _checkExplorationModal() {
    if (_hasCheckedExplorationModal || !mounted) return;
    _hasCheckedExplorationModal = true;

    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is Map && rawArgs['showExplorationModal'] == true) {
      try {
        rawArgs['showExplorationModal'] = false;
      } catch (_) {}

      if (_recommendations.isEmpty) {
        _checkBanNoticeForAction(actionDescription: 'take the pet match').then((isBanned) {
          if (!isBanned && mounted) {
            Navigator.pushNamed(context, '/match-quiz').then((_) {
              if (mounted) _fetchRecommendations();
            });
          }
        });
      }
    }
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
                      ? 'Your account has been banned from submitting adoption applications and taking match quizzes. You can view pet matches in read-only mode.'
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

      final mappedRecs = availableRecs.map((raw) {
        final photoUrl = raw['photo_url'] ??
            (raw['photo_path'] != null
                ? ApiService.normalizeImageUrl(raw['photo_path'])
                : 'https://images.unsplash.com/photo-1543466835-00a7907e9de1');

        return {
          ...raw,
          'id': raw['pet_id'] ?? raw['id'],
          'name': raw['name'] ?? 'Pet no. ${raw['pet_id'] ?? raw['id']}',
          'breed': raw['breed'] ?? 'Mixed Breed',
          'age': raw['age'] ?? 'Adult',
          'gender': raw['gender'] ?? 'male',
          'type': raw['type'] ?? 'dog',
          'image': photoUrl,
          'photo_url': photoUrl,
          'match_percentage': raw['match_percentage'],
          'compatibility_score': raw['match_percentage'],
          'isRecommended': true,
          'application_source': 'recommendation',
          'temperaments': raw['temperaments'] ?? raw['temperament'] ?? [],
          'match_reasons': raw['match_reasons'] ?? [],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _recommendations = mappedRecs;
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


  List<Map<String, dynamic>> get _filteredPets {
    if (_selectedCategory == 'all') return _recommendations;
    return _recommendations.where((pet) {
      final type = (pet['type'] ?? '').toString().toLowerCase();
      return type == _selectedCategory;
    }).toList();
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
                        // Health Reminders Section
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

                        // Application Status Updates Section
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

                            if (status == 'approved') {
                              final eventDate = item['scheduledAt'] ?? 'Sunday Event';
                              return _buildMinimalNotificationCard(
                                icon: Icons.assignment_turned_in_outlined,
                                iconColor: const Color(0xFF0D9488),
                                iconBg: const Color(0xFFF0FDFA),
                                title: '$petName - Pre-Approved',
                                subtitle: 'Event: $eventDate · Bring ID & Brgy Cert',
                                badgeText: 'Pre-Approved',
                                badgeColor: const Color(0xFF0D9488),
                                badgeBg: const Color(0xFFCCFBF1),
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

                            // Pending / default
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
    final displayedPets = _filteredPets;
    final hasRecommendations = _recommendations.isNotEmpty;
    final topPet = hasRecommendations ? _recommendations.first : null;
    final companions = hasRecommendations && topPet != null
        ? (_selectedCategory == 'all'
            ? displayedPets.where((p) => (p['id'] ?? p['pet_id']) != (topPet['id'] ?? topPet['pet_id'])).toList()
            : displayedPets)
        : displayedPets;

    return RefreshIndicator(
      onRefresh: () async {
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
                  // 1. Centerpiece Recommendation Hero Card
                  const SizedBox(height: 16),
                  _buildRecommendationHero(context),

                  // 2. Quick Category Filters
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildCategoryChip('all', 'All Matches', Icons.auto_awesome_rounded),
                      const SizedBox(width: 8),
                      _buildCategoryChip('dog', 'Dogs', Icons.pets_rounded),
                      const SizedBox(width: 8),
                      _buildCategoryChip('cat', 'Cats', Icons.cruelty_free_rounded),
                    ],
                  ),

                  // 3. More Compatible Companions Section
                  const SizedBox(height: 22),
                  _sectionHeader(
                    context,
                    hasRecommendations ? 'More Compatible Companions' : 'Compatible Companions',
                    'View All',
                    isPowered: hasRecommendations,
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
                      : companions.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.pets_rounded,
                                      size: 44,
                                      color: AppTheme.primary.withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      hasRecommendations
                                          ? 'No other matches in this category'
                                          : 'No matches found',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hasRecommendations
                                          ? 'Your #1 top match is featured above.'
                                          : 'Complete the quiz above to view tailored matches.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
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
                              itemCount: companions.length,
                              itemBuilder: (context, index) {
                                final pet = companions[index];
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

  Widget _buildRecommendationHero(BuildContext context) {
    if (_recommendations.isEmpty) {
      return _buildQuizPromptHeroCard(context);
    }
    return _buildTopMatchHeroCard(context, _recommendations.first);
  }

  Widget _buildQuizPromptHeroCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A6B72), AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'AI PET MATCHMAKER',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Your Ideal Companion',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Our machine learning engine matches pets to your living space, activity level, and lifestyle.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: PetRecommendationIcon(
                    size: 38,
                    color: Color(0xFF0A6B72),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final isBanned = await _checkBanNoticeForAction(actionDescription: 'take the pet match');
                if (isBanned || !context.mounted) return;
                await Navigator.pushNamed(context, '/match-quiz');
                _fetchRecommendations();
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 17),
              label: Text(
                'Start 1-Minute Match Quiz',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMatchHeroCard(BuildContext context, Map<String, dynamic> pet) {
    int matchScore = 95;
    final rawScore = pet['match_percentage'] ?? pet['compatibility_score'];
    if (rawScore is num) {
      matchScore = rawScore.round();
    } else if (rawScore is String) {
      matchScore = double.tryParse(rawScore)?.round() ?? 95;
    }
    matchScore = matchScore.clamp(1, 100);

    final name = pet['name']?.toString() ?? 'Pet';
    final breed = pet['breed']?.toString() ?? 'Mixed Breed';
    final age = pet['age']?.toString() ?? 'Adult';
    final rawGender = (pet['gender'] ?? '').toString();
    final gender = rawGender.isNotEmpty
        ? '${rawGender[0].toUpperCase()}${rawGender.substring(1).toLowerCase()}'
        : 'Unknown';

    String? imageUrl;
    final rawImg = pet['image']?.toString() ?? pet['photo_url']?.toString();
    if (rawImg != null && rawImg.trim().isNotEmpty && rawImg != 'null') {
      imageUrl = ApiService.normalizeImageUrl(rawImg);
    } else {
      final rawPath = pet['photo_path']?.toString();
      if (rawPath != null && rawPath.trim().isNotEmpty && rawPath != 'null') {
        imageUrl = ApiService.normalizeImageUrl(rawPath);
      }
    }

    final reasons = pet['match_reasons'] as List<dynamic>? ?? [];
    final temperaments = pet['temperaments'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCCFBF1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF0FDFA),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TOP ML RECOMMENDATION',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F766E),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      final isBanned = await _checkBanNoticeForAction(actionDescription: 'retake match quiz');
                      if (isBanned || !context.mounted) return;
                      await Navigator.pushNamed(context, '/match-quiz');
                      _fetchRecommendations();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune_rounded, size: 12, color: Color(0xFF0F766E)),
                          const SizedBox(width: 4),
                          Text(
                            'Retake',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Hero Pet Photo with Floating Badge & Details
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/pet-detail', arguments: pet),
              child: Stack(
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildHeroPlaceholder(),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 190,
                          color: const Color(0xFFF1F5F9),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    _buildHeroPlaceholder(),

                  // Bottom gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.72), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),

                  // Match Percentage Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
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
                          const Icon(Icons.favorite_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            '$matchScore% Match',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pet name, breed & meta
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.7),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$breed • $age • $gender',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.7),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Match Reasons Section & Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WHY THIS COMPANION MATCHES YOU',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (reasons.isNotEmpty)
                        ...reasons.take(3).map((r) => _buildMatchChip(r.toString(), true))
                      else if (temperaments.isNotEmpty)
                        ...temperaments.take(3).map((t) => _buildMatchChip(t.toString(), true))
                      else ...[
                        _buildMatchChip('Compatible Energy', true),
                        _buildMatchChip('Lifestyle Match', true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/pet-detail', arguments: pet),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View Compatibility Profile',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroPlaceholder() {
    return Container(
      height: 190,
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 6),
            Text(
              'Photo arriving soon',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchChip(String label, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPositive ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 12,
            color: isPositive ? const Color(0xFF059669) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isPositive ? const Color(0xFF065F46) : const Color(0xFF92400E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            child: Text(
              actionLabel,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
