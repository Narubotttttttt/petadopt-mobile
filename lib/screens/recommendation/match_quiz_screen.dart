import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/screens/pets/pet_detail_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/ai_recommendation_hero.dart';
import 'package:mobile_petadopt/widgets/app_confirmation_dialog.dart';
import 'package:mobile_petadopt/widgets/connectivity_banner.dart';
import 'package:mobile_petadopt/widgets/pet_comparison_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MatchQuizScreen extends StatefulWidget {
  final bool isEmbeddedInTab;

  const MatchQuizScreen({
    super.key,
    this.isEmbeddedInTab = false,
  });

  @override
  State<MatchQuizScreen> createState() => _MatchQuizScreenState();
}

class _MatchQuizScreenState extends State<MatchQuizScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _showResults = false;
  bool _isLocked = false;
  bool _isLoadingRecommendations = false;
  List<Map<String, dynamic>> _recommendations = [];
  int _selectedMatchIndex = 0;
  bool _showAllInList = false;
  int _adoptedCount = 0;
  bool _canRetake = false;
  String _retakeStatus = 'none';
  int _daysRemaining = 30;
  String? _nextRetakeDate;
  int _revisionCount = 1;
  String _loadingStatus = 'Analyzing your living environment and lifestyle compatibility...';
  int _loadingStep = 1;

  // Step 1: Companion Type Selection
  String? _preferredSpecies;

  // Step 2: Living & Lifestyle
  String? _livingEnvironment;
  String? _yardType;
  bool? _hasYard;
  String? _activityLevel;

  // Step 3: Experience & Household
  String? _petExperience;
  bool? _hasChildren;
  bool? _hasOtherPets;

  // Step 4: Capacity & Temperament
  String? _hoursAlone;
  bool? _specialCareCapacity;
  final Set<String> _desiredTemperaments = {};

// Temperaments are now predicted by the Random Forest model

  bool get _hasAnySelection =>
      _preferredSpecies != null ||
      _livingEnvironment != null ||
      _yardType != null ||
      _activityLevel != null ||
      _petExperience != null ||
      _hasChildren != null ||
      _hasOtherPets != null ||
      _hoursAlone != null ||
      _specialCareCapacity != null;

  void _resetQuiz() {
    if (_isLocked) return;
    setState(() {
      _currentStep = 0;
      _preferredSpecies = null;
      _livingEnvironment = null;
      _yardType = null;
      _hasYard = null;
      _activityLevel = null;
      _petExperience = null;
      _hasChildren = null;
      _hasOtherPets = null;
      _hoursAlone = null;
      _specialCareCapacity = null;
      _desiredTemperaments.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _checkBanStanding();
    _checkCachedLockState();
    _loadSavedPreferences();
  }

  Future<String?> _getUserQuizLockKey() async {
    try {
      final user = await ApiService.getUser();
      final userId = user?['id'];
      if (userId != null) {
        return 'quiz_locked_user_$userId';
      }
    } catch (_) {}
    return null;
  }

  Future<void> _checkCachedLockState() async {
    try {
      final lockKey = await _getUserQuizLockKey();
      if (lockKey == null) {
        if (mounted) {
          setState(() {
            _isLocked = false;
          });
        }
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final isLockedCached = prefs.getBool(lockKey) ?? false;
      final canRetakeCached = prefs.getBool('${lockKey}_can_retake');
      final revisionCountCached = prefs.getInt('${lockKey}_revision_count');
      final daysRemainingCached = prefs.getInt('${lockKey}_days_remaining');
      final nextRetakeDateCached = prefs.getString('${lockKey}_next_retake_date');
      final retakeStatusCached = prefs.getString('${lockKey}_retake_status');
      final savedPrefsJson = prefs.getString('${lockKey}_saved_prefs_json');

      if (mounted) {
        setState(() {
          _isLocked = isLockedCached;
          if (canRetakeCached != null) {
            _canRetake = canRetakeCached;
          } else if (isLockedCached) {
            _canRetake = false;
          }
          if (revisionCountCached != null) {
            _revisionCount = revisionCountCached;
          } else if (isLockedCached) {
            _revisionCount = 1;
          }
          if (daysRemainingCached != null) {
            _daysRemaining = daysRemainingCached;
          } else if (isLockedCached) {
            _daysRemaining = 30;
          }
          if (nextRetakeDateCached != null) {
            _nextRetakeDate = nextRetakeDateCached;
          }
          if (retakeStatusCached != null) {
            _retakeStatus = retakeStatusCached;
          }

          if (savedPrefsJson != null && savedPrefsJson.isNotEmpty) {
            try {
              final cachedMap = jsonDecode(savedPrefsJson);
              if (cachedMap is Map<String, dynamic>) {
                _preferredSpecies = cachedMap['preferred_species']?.toString();
                _livingEnvironment = cachedMap['living_environment']?.toString();
                final hy = cachedMap['has_yard'];
                if (hy != null) {
                  _hasYard = hy == true || hy == 1 || hy.toString() == '1' || hy.toString().toLowerCase() == 'true';
                }
                _yardType = cachedMap['yard_type']?.toString();
                _activityLevel = cachedMap['activity_level']?.toString();
                _petExperience = cachedMap['pet_experience']?.toString();
                final hc = cachedMap['has_children'];
                if (hc != null) {
                  _hasChildren = hc == true || hc == 1 || hc.toString() == '1' || hc.toString().toLowerCase() == 'true';
                }
                final hp = cachedMap['has_other_pets'];
                if (hp != null) {
                  _hasOtherPets = hp == true || hp == 1 || hp.toString() == '1' || hp.toString().toLowerCase() == 'true';
                  if (_hasOtherPets == true) {
                    _petExperience = 'experienced';
                  }
                }
                _hoursAlone = cachedMap['hours_alone']?.toString();
                final sc = cachedMap['special_care_capacity'];
                if (sc != null) {
                  _specialCareCapacity = sc == true || sc == 1 || sc.toString() == '1' || sc.toString().toLowerCase() == 'true';
                }
                if (cachedMap['desired_temperaments'] is List) {
                  _desiredTemperaments.clear();
                  for (final t in cachedMap['desired_temperaments']) {
                    _desiredTemperaments.add(t.toString());
                  }
                }
              }
            } catch (_) {}
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final lockKey = await _getUserQuizLockKey();
      final prefs = await SharedPreferences.getInstance();
      final saved = await ApiService.getSavedPreferences();

      // Clean up legacy device-wide lock key if present
      await prefs.remove('quiz_locked');

      if (saved != null && mounted) {
        if (lockKey != null) {
          await prefs.setBool(lockKey, true);
          await prefs.setBool('${lockKey}_can_retake', saved['can_retake'] == true);
          await prefs.setInt('${lockKey}_revision_count', (saved['revision_count'] as num?)?.toInt() ?? 0);
          await prefs.setInt('${lockKey}_days_remaining', (saved['days_remaining'] as num?)?.toInt() ?? 0);
          if (saved['next_retake_date'] != null) {
            await prefs.setString('${lockKey}_next_retake_date', saved['next_retake_date'].toString());
          }
          await prefs.setString('${lockKey}_retake_status', saved['retake_status']?.toString() ?? 'none');
          await prefs.setString('${lockKey}_saved_prefs_json', jsonEncode(saved));
        }

        setState(() {
          _isLocked = true;
          _adoptedCount = RecommendationService.adoptedCount;
          _canRetake = saved['can_retake'] == true;
          _retakeStatus = saved['retake_status']?.toString() ?? 'none';
          _daysRemaining = (saved['days_remaining'] as num?)?.toInt() ?? 0;
          _nextRetakeDate = saved['next_retake_date']?.toString();
          _revisionCount = (saved['revision_count'] as num?)?.toInt() ?? 0;
          _preferredSpecies = saved['preferred_species']?.toString();
          _livingEnvironment = saved['living_environment']?.toString();
          if (saved['has_yard'] != null) {
            _hasYard = saved['has_yard'] is bool
                ? saved['has_yard']
                : saved['has_yard'].toString() == '1' || saved['has_yard'].toString() == 'true';
          } else {
            _hasYard = _livingEnvironment == 'house_with_yard';
          }
          _yardType = saved['yard_type']?.toString() ?? (_hasYard == true ? 'fenced' : (_livingEnvironment == 'apartment' ? 'none' : 'unfenced'));
          _activityLevel = saved['activity_level']?.toString();
          _petExperience = saved['pet_experience']?.toString();
          if (saved['has_children'] != null) {
            _hasChildren = saved['has_children'] is bool
                ? saved['has_children']
                : saved['has_children'].toString() == '1' || saved['has_children'].toString() == 'true';
          }
          if (saved['has_other_pets'] != null) {
            _hasOtherPets = saved['has_other_pets'] is bool
                ? saved['has_other_pets']
                : saved['has_other_pets'].toString() == '1' || saved['has_other_pets'].toString() == 'true';
            if (_hasOtherPets == true) {
              _petExperience = 'experienced';
            }
          }
          _hoursAlone = saved['hours_alone']?.toString();
          if (saved['special_care_capacity'] != null) {
            _specialCareCapacity = saved['special_care_capacity'] is bool
                ? saved['special_care_capacity']
                : saved['special_care_capacity'].toString() == '1' || saved['special_care_capacity'].toString() == 'true';
          }
          if (saved['desired_temperaments'] is List) {
            _desiredTemperaments.clear();
            for (final t in saved['desired_temperaments']) {
              _desiredTemperaments.add(t.toString());
            }
          }
        });

        // Pre-fetch recommendations in background for this specific user
        _fetchSavedRecommendations();
        return;
      } else if (mounted) {
        // Fresh user or account with no submitted quiz
        if (lockKey != null) {
          await prefs.setBool(lockKey, false);
          await prefs.remove('${lockKey}_can_retake');
          await prefs.remove('${lockKey}_revision_count');
          await prefs.remove('${lockKey}_days_remaining');
          await prefs.remove('${lockKey}_next_retake_date');
          await prefs.remove('${lockKey}_retake_status');
          await prefs.remove('${lockKey}_saved_prefs_json');
        }

        setState(() {
          _isLocked = false;
          _showResults = false;
          _currentStep = 0;
          _recommendations = [];
          _preferredSpecies = null;
          _livingEnvironment = null;
          _yardType = null;
          _hasYard = null;
          _activityLevel = null;
          _petExperience = null;
          _hasChildren = null;
          _hasOtherPets = null;
          _hoursAlone = null;
          _specialCareCapacity = null;
          _desiredTemperaments.clear();
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
      });
    }
  }

  Future<void> _fetchSavedRecommendations() async {
    try {
      final recs = await ApiService.getRecommendations();
      final applications = await ApiService.getMyApplications();
      final appliedPetIds = applications
          .where((app) {
            final st = (app['status']?.toString() ?? '').toLowerCase();
            return ['pending', 'under_review', 'approved', 'adopted'].contains(st);
          })
          .map((app) => (app['pet_id'] ?? app['petId'])?.toString())
          .where((id) => id != null)
          .toSet();

      final availableRecs = recs.where((pet) {
        final status = pet['status']?.toString().trim().toLowerCase();
        final petId = (pet['pet_id'] ?? pet['id'])?.toString();
        final alreadyApplied = petId != null && appliedPetIds.contains(petId);
        return (status == null || status.isEmpty || status == 'available') && !alreadyApplied;
      }).take(3).toList();
      if (mounted) {
        setState(() {
          _recommendations = availableRecs;
          if (_selectedMatchIndex >= _recommendations.length) {
            _selectedMatchIndex = 0;
          }
          _adoptedCount = RecommendationService.adoptedCount;
          // CRITICAL: DO NOT auto-set _showResults = true here!
          // The screen must stay on the locked profile review until the adopter taps 'View Recommended Pets'.
        });
      }
    } catch (_) {}
  }

  Future<void> _checkBanStanding() async {
    try {
      final user = await ApiService.getProfile();
      if (user != null && (user['status'] == 'blacklisted' || user['status'] == 'restricted')) {
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (_) {}
  }

  Future<void> _confirmAndSubmitQuiz() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_user_outlined, color: AppTheme.primaryDark, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Submit Assessment Verification',
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
              'Please review your answers before submitting. Under shelter compatibility rules:',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogBullet(_revisionCount == 0
                      ? 'You will have 1 immediate edit chance to fix any initial mistakes.'
                      : 'Submitting this revision will activate a 30-day profile cooldown.'),
                  const SizedBox(height: 6),
                  _buildDialogBullet('After using your edit chance, profile updates are limited to once every 30 days.'),
                  const SizedBox(height: 6),
                  _buildDialogBullet('A strict maximum adoption limit of 3 pets per household is enforced.'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ready to evaluate your compatibility matches?',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Review Again',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              elevation: 0,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Confirm & Submit',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _submitQuiz();
    }
  }

  Widget _buildDialogBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5, right: 8),
          child: Icon(Icons.circle, size: 5, color: Color(0xFFD97706)),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF92400E),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitQuiz() async {
    setState(() {
      _isLoading = true;
      _loadingStep = 1;
      _loadingStatus = 'Evaluating pet temperament and home environment match...';
    });

    String resolvedLiving = _livingEnvironment ?? 'apartment';
    if (resolvedLiving == 'house') {
      resolvedLiving = (_yardType == 'fenced') ? 'house_with_yard' : 'house_no_yard';
    }

    final payload = {
      'preferred_species': _preferredSpecies ?? 'any',
      'living_environment': resolvedLiving,
      'has_yard': _hasYard ?? (_yardType == 'fenced'),
      'yard_type': _yardType ?? 'none',
      'activity_level': _activityLevel ?? 'moderate',
      'pet_experience': _petExperience ?? 'first_time',
      'has_children': _hasChildren ?? false,
      'has_other_pets': _hasOtherPets ?? false,
      'hours_alone': _hoursAlone ?? '4_7',
      'special_care_capacity': _specialCareCapacity ?? false,
      'desired_temperaments': _desiredTemperaments.toList(),
    };

    try {
      final startTime = DateTime.now();
      final recsFuture = ApiService.getRecommendations(profile: payload);

      // Multi-stage natural AI evaluation progression
      await Future.delayed(const Duration(milliseconds: 1100));
      if (mounted && _isLoading) {
        setState(() {
          _loadingStep = 2;
          _loadingStatus = 'Evaluating pet temperaments and lifestyle fit...';
        });
      }

      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted && _isLoading) {
        setState(() {
          _loadingStep = 3;
          _loadingStatus = 'Ranking top matches by lifestyle and environmental safety...';
        });
      }

      final recs = await recsFuture;
      final applications = await ApiService.getMyApplications();
      final appliedPetIds = applications
          .where((app) {
            final st = (app['status']?.toString() ?? '').toLowerCase();
            return ['pending', 'under_review', 'approved', 'adopted'].contains(st);
          })
          .map((app) => (app['pet_id'] ?? app['petId'])?.toString())
          .where((id) => id != null)
          .toSet();

      final availableRecs = recs.where((pet) {
        final status = pet['status']?.toString().trim().toLowerCase();
        final petId = (pet['pet_id'] ?? pet['id'])?.toString();
        final alreadyApplied = petId != null && appliedPetIds.contains(petId);
        return (status == null || status.isEmpty || status == 'available') && !alreadyApplied;
      }).take(3).toList();

      // Ensure the full animated recommendation evaluation cycle finishes naturally (~3.4s total)
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 3400) {
        await Future.delayed(Duration(milliseconds: 3400 - elapsed));
      }

      if (mounted) {
        try {
          final lockKey = await _getUserQuizLockKey();
          final prefs = await SharedPreferences.getInstance();
          if (lockKey != null) {
            await prefs.setBool(lockKey, true);
            await prefs.setBool('${lockKey}_can_retake', false);
            await prefs.setInt('${lockKey}_revision_count', _revisionCount + 1);
            await prefs.setInt('${lockKey}_days_remaining', 30);
            await prefs.setString('${lockKey}_retake_status', 'cooldown');
          }
          await prefs.remove('quiz_locked');
        } catch (_) {}
        setState(() {
          _isLocked = true;
          _recommendations = availableRecs;
          _selectedMatchIndex = 0;
          _showResults = true;
          _isLoading = false;
          _canRetake = false;
          _daysRemaining = 30;
          _revisionCount++;
        });
        _loadSavedPreferences();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (ApiClient.isNetworkError(e)) {
          NetworkErrorHelper.showConnectionLostDialog(
            context,
            title: 'Connection Lost',
            message:
                'Unable to evaluate pet matches because your internet connection was lost. Please check your network and tap Retry.',
            onRetry: () => _submitQuiz(),
          );
          return;
        }
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
    return PopScope(
      canPop: !(_showResults && _isLocked),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showResults && _isLocked) {
          setState(() => _showResults = false);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: widget.isEmbeddedInTab
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  tooltip: 'Back',
                  onPressed: () {
                    if (_showResults && _isLocked) {
                      setState(() => _showResults = false);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
          title: Text(
            _showResults
                ? 'Recommended Pet Matches'
                : (_isLocked ? 'Compatibility Profile' : 'Compatibility Assessment'),
            style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          actions: [
            if (!_showResults && !_isLoading && _hasAnySelection && !_isLocked)
              TextButton(
                onPressed: _resetQuiz,
                child: Text(
                  'Clear',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            if (_isLocked && !_showResults)
              Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 13, color: Color(0xFF475569)),
                    const SizedBox(width: 4),
                    Text(
                      'Locked',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : _showResults
                ? _buildResultsView()
                : (_isLocked ? _buildLockedProfileView() : _buildQuizView()),
      ),
    );
  }


  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.22),
                    blurRadius: 36,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: LuminousAiOrb(size: 112),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Finding Your Perfect Match',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                _loadingStatus,
                key: ValueKey<String>(_loadingStatus),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final active = index < _loadingStep;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primary : AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNextStep() {
    if (_currentStep == 0) {
      if (_preferredSpecies == null) {
        _showValidationError('Please select which companion you are looking to adopt (or Any Species).');
        return;
      }
    } else if (_currentStep == 1) {
      if (_livingEnvironment == null) {
        _showValidationError('Please select your residence type.');
        return;
      }
      if (_yardType == null) {
        _showValidationError('Please select your outdoor and yard space type.');
        return;
      }
      if (_activityLevel == null) {
        _showValidationError('Please select your activity level.');
        return;
      }
    } else if (_currentStep == 2) {
      if (_petExperience == null) {
        _showValidationError('Please select your experience with pets.');
        return;
      }
      if (_hasChildren == null) {
        _showValidationError('Please indicate if children live in your household.');
        return;
      }
      if (_hasOtherPets == null) {
        _showValidationError('Please indicate if you have other pets.');
        return;
      }
    } else if (_currentStep == 3) {
      if (_hoursAlone == null) {
        _showValidationError('Please select daily hours the pet will be left alone.');
        return;
      }
      if (_specialCareCapacity == null) {
        _showValidationError('Please indicate your special care capacity.');
        return;
      }
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _confirmAndSubmitQuiz();
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildQuizView() {
    final bottomInset = widget.isEmbeddedInTab ? 100.0 : 24.0;
    return Column(
      children: [
        _buildProgressBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentStep == 0) _buildStep1(),
                if (_currentStep == 1) _buildStep2(),
                if (_currentStep == 2) _buildStep3(),
                if (_currentStep == 3) _buildStep4(),
                if (_currentStep == 4) _buildStep5Review(),
                const SizedBox(height: 32),
                Row(
                  children: [
                    if (_currentStep > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Back', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.primary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _handleNextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentStep == 4 ? const Color(0xFF0F766E) : AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: Text(
                          _currentStep < 4 ? 'Next Step' : 'Confirm & Submit Quiz',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final titles = [
      'Companion Type',
      'Living Space',
      'Experience',
      'Personality',
      'Review & Confirm',
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of 5: ${titles[_currentStep]}',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary),
              ),
              Text(
                '${((_currentStep + 1) / 5 * 100).toInt()}%',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // STEP 1: Target Companion Type
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Companion Type',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tell us which companion you are looking to adopt',
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('Which companion are you looking for?'),
        _buildRadioGroup(
          options: [
            {'val': 'any', 'label': 'Any Species (Dogs & Cats)'},
            {'val': 'dog', 'label': 'Dogs Only'},
            {'val': 'cat', 'label': 'Cats Only'},
          ],
          selected: _preferredSpecies,
          onSelected: (val) => setState(() => _preferredSpecies = val),
        ),
      ],
    );
  }

  // STEP 2: Living Environment & Lifestyle
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Living Space & Routine', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('Helps match pets that thrive in your living environment', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        _buildSectionTitle('Your Residence Type'),
        _buildRadioGroup(
          options: [
            {'val': 'apartment', 'label': 'Apartment / Condominium'},
            {'val': 'house', 'label': 'House'},
            {'val': 'townhouse', 'label': 'Townhouse / Duplex'},
          ],
          selected: _livingEnvironment,
          onSelected: (val) => setState(() => _livingEnvironment = val),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Outdoor & Yard Space'),
        _buildRadioGroup(
          options: [
            {'val': 'fenced', 'label': 'Fully Fenced Yard (Secure perimeter)'},
            {'val': 'unfenced', 'label': 'Unfenced Yard or Open Property'},
            {'val': 'balcony', 'label': 'Balcony / Patio Only'},
            {'val': 'none', 'label': 'No Private Outdoor Area (Parks only)'},
          ],
          selected: _yardType,
          onSelected: (val) => setState(() {
            _yardType = val;
            _hasYard = (val == 'fenced');
          }),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Your Activity Level'),
        _buildRadioGroup(
          options: [
            {'val': 'relaxed', 'label': 'Calm & Relaxed (Indoor lounging)'},
            {'val': 'moderate', 'label': 'Moderately Active (Daily walks & play)'},
            {'val': 'high', 'label': 'High Energy (Running, hiking, outdoors)'},
          ],
          selected: _activityLevel,
          onSelected: (val) => setState(() => _activityLevel = val),
        ),
      ],
    );
  }

  // STEP 3: Experience & Household Dynamics
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Experience & Household', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('Ensures the pet is safe and friendly with everyone in your home', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        _buildSectionTitle('Your Experience with Pets'),
        _buildRadioGroup(
          options: [
            {'val': 'first_time', 'label': 'First-time Pet Owner'},
            {'val': 'experienced', 'label': 'Experienced Pet Owner'},
          ],
          selected: _hasOtherPets == true ? 'experienced' : _petExperience,
          onSelected: (val) {
            setState(() {
              _petExperience = val;
              if (val == 'first_time' && _hasOtherPets == true) {
                _hasOtherPets = false;
              }
            });
          },
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Children in Household'),
        _buildRadioGroup(
          options: [
            {'val': 'yes', 'label': 'Yes, children live in household'},
            {'val': 'no', 'label': 'No children in household'},
          ],
          selected: _hasChildren == null ? null : (_hasChildren! ? 'yes' : 'no'),
          onSelected: (val) => setState(() => _hasChildren = val == 'yes'),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Existing Pets in Household'),
        _buildRadioGroup(
          options: [
            {'val': 'yes', 'label': 'Yes, have other pets in home'},
            {'val': 'no', 'label': 'No other pets in home'},
          ],
          selected: _hasOtherPets == null ? null : (_hasOtherPets! ? 'yes' : 'no'),
          onSelected: (val) {
            setState(() {
              _hasOtherPets = val == 'yes';
              if (_hasOtherPets == true) {
                _petExperience = 'experienced';
              }
            });
          },
        ),
      ],
    );
  }

  // STEP 4: Daily Schedule & Care Availability
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Schedule & Care Capacity', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('Matches pets based on your daily work hours and care availability', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        _buildSectionTitle('Hours pet will be left alone daily'),
        _buildRadioGroup(
          options: [
            {'val': '0_3', 'label': '0 - 3 Hours'},
            {'val': '4_7', 'label': '4 - 7 Hours'},
            {'val': '8_plus', 'label': '8+ Hours'},
          ],
          selected: _hoursAlone,
          onSelected: (val) => setState(() => _hoursAlone = val),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Special Care Capacity'),
        _buildRadioGroup(
          options: [
            {'val': 'yes', 'label': 'Open to special care or medical needs'},
            {'val': 'no', 'label': 'Standard care only (no special needs)'},
          ],
          selected: _specialCareCapacity == null ? null : (_specialCareCapacity! ? 'yes' : 'no'),
          onSelected: (val) => setState(() => _specialCareCapacity = val == 'yes'),
        ),
      ],
    );
  }

  // STEP 5: Review & Confirmation Screen (Final Page)
  Widget _buildStep5Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Answers',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Please verify all your choices before final submission to the engine.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 18),

        // Verification & Evaluation Guidelines Notice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF99F6E4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_user_outlined, color: AppTheme.primaryDark, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment Verification Guidelines',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0E7A80),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please verify your home, yard, and routine details. You will have 1 immediate grace chance to edit any mistakes after submission. Finalized profiles can be updated once every 30 days. Maximum 3 pets allowed per household.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF134E4A),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Section 1: Target Companion Type Summary
        _buildReviewSectionCard(
          title: 'Target Companion Type',
          stepIndex: 0,
          rows: [
            {'label': 'Species', 'val': _getSpeciesLabel()},
          ],
        ),

        // Section 2: Living Space Summary
        _buildReviewSectionCard(
          title: 'Living Space & Routine',
          stepIndex: 1,
          rows: [
            {'label': 'Residence', 'val': _getResidenceLabel()},
            {'label': 'Outdoor Space', 'val': _getYardLabel()},
            {'label': 'Activity Level', 'val': _getActivityLabel()},
          ],
        ),

        // Section 3: Household & Experience Summary
        _buildReviewSectionCard(
          title: 'Experience & Household',
          stepIndex: 2,
          rows: [
            {'label': 'Pet Experience', 'val': _getExperienceLabel()},
            {'label': 'Children in Home', 'val': _hasChildren == true ? 'Yes, children present' : 'No children'},
            {'label': 'Existing Pets', 'val': _hasOtherPets == true ? 'Yes, other pets in home' : 'No other pets'},
          ],
        ),

        // Section 4: Schedule & Care Capacity Summary
        _buildReviewSectionCard(
          title: 'Schedule & Care Capacity',
          stepIndex: 3,
          rows: [
            {'label': 'Hours Alone Daily', 'val': _getHoursAloneLabel()},
            {'label': 'Special Care Needs', 'val': _specialCareCapacity == true ? 'Open to special care / medical' : 'Standard care only'},
          ],
        ),
      ],
    );
  }

  Widget _buildReviewSectionCard({
    required String title,
    required int stepIndex,
    required List<Map<String, String>> rows,
    Widget? extraWidget,
    bool showEditButton = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              if (showEditButton && (!_isLocked || _canRetake))
                InkWell(
                  onTap: () {
                    setState(() {
                      _isLocked = false;
                      _showResults = false;
                      _currentStep = stepIndex;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 13, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 16),
          ...rows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      row['label']!,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row['val']!,
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),
            );
          }),
          ?extraWidget,
        ],
      ),
    );
  }

  // Locked Profile View (for adopters who already finalized the quiz)
  Widget _buildRevisionStatusCard() {
    final bool canEdit = _canRetake;
    final bool isGrace = _revisionCount == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canEdit ? const Color(0xFFE0F7FA).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canEdit ? const Color(0xFF80DEEA) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: canEdit ? AppTheme.primaryLight : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  canEdit ? Icons.edit_note_rounded : Icons.lock_clock_rounded,
                  color: canEdit ? AppTheme.primaryDark : const Color(0xFF64748B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canEdit
                          ? (isGrace ? '1 Edit Chance Available' : 'Monthly Update Available')
                          : 'Profile Locked • 30-Day Cooldown',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      canEdit
                          ? (isGrace
                              ? 'You have 1 chance to revise your answers if you made an initial mistake. Submitting will activate a 30-day cooldown.'
                              : 'Your monthly window is open. You may update your profile to reflect new home or routine circumstances.')
                          : 'To maintain matching integrity, profiles can be updated once every 30 days. Next update available on ${_nextRetakeDate ?? "next month"} (${_daysRemaining} days remaining).',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleStartRetake,
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: Text(
                  isGrace ? 'Edit Assessment Answers' : 'Update Living & Routine Answers',
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleStartRetake() {
    AppConfirmationDialog.show(
      context,
      icon: Icons.edit_note_rounded,
      iconColor: AppTheme.primary,
      iconBackgroundColor: AppTheme.primaryLight,
      title: _revisionCount == 0 ? 'Edit Assessment Answers?' : 'Update Profile Answers?',
      message: _revisionCount == 0
          ? 'You can adjust your living environment, yard access, or work routine. Once submitted, your profile will lock for 30 days.'
          : 'Updating your profile will recalculate your pet compatibility matches based on your new answers. Continue?',
      cancelText: 'Cancel',
      confirmText: 'Continue to Edit',
      onConfirm: () {
        setState(() {
          _isLocked = false;
          _showResults = false;
          _currentStep = 0;
        });
      },
    );
  }

  Widget _buildLockedProfileView() {
    final bottomInset = widget.isEmbeddedInTab ? 100.0 : 24.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Revision / Cooldown Status Card
          _buildRevisionStatusCard(),

          const SizedBox(height: 14),

          // Household Adoption Capacity Card
          _buildHouseholdCapacityCard(),

          const SizedBox(height: 14),

          // Primary action to view pet recommendations
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingRecommendations
                  ? null
                  : () async {
                      if (_recommendations.isEmpty) {
                        setState(() => _isLoadingRecommendations = true);
                        await _fetchSavedRecommendations();
                        if (mounted) {
                          setState(() {
                            _isLoadingRecommendations = false;
                            _showResults = true;
                          });
                        }
                      } else {
                        setState(() => _showResults = true);
                      }
                    },
              icon: _isLoadingRecommendations
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.pets_rounded, size: 18),
              label: Text(
                _isLoadingRecommendations ? 'Loading Recommendations...' : 'View Recommended Pets',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Your Saved Preferences',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),

          _buildReviewSectionCard(
            title: 'Target Companion Type',
            stepIndex: 0,
            showEditButton: _canRetake,
            rows: [
              {'label': 'Species', 'val': _getSpeciesLabel()},
            ],
          ),

          _buildReviewSectionCard(
            title: 'Living Space & Routine',
            stepIndex: 1,
            showEditButton: _canRetake,
            rows: [
              {'label': 'Residence', 'val': _getResidenceLabel()},
              {'label': 'Outdoor Space', 'val': _getYardLabel()},
              {'label': 'Activity Level', 'val': _getActivityLabel()},
            ],
          ),

          _buildReviewSectionCard(
            title: 'Experience & Household',
            stepIndex: 2,
            showEditButton: _canRetake,
            rows: [
              {'label': 'Pet Experience', 'val': _getExperienceLabel()},
              {'label': 'Children in Home', 'val': _hasChildren == true ? 'Yes, children present' : 'No children'},
              {'label': 'Existing Pets', 'val': _hasOtherPets == true ? 'Yes, other pets in home' : 'No other pets'},
            ],
          ),

          _buildReviewSectionCard(
            title: 'Care Capacity & Temperament',
            stepIndex: 3,
            showEditButton: _canRetake,
            rows: [
              {'label': 'Hours Alone Daily', 'val': _getHoursAloneLabel()},
              {'label': 'Special Care Needs', 'val': _specialCareCapacity == true ? 'Open to special care / medical' : 'Standard care only'},
            ],
            extraWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Desired Temperament Traits:',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _desiredTemperaments.map((trait) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        trait,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Label Helpers
  String _getSpeciesLabel() {
    if (_preferredSpecies == 'dog') return 'Dogs Only';
    if (_preferredSpecies == 'cat') return 'Cats Only';
    return 'Any Species (Dogs & Cats)';
  }



  String _getResidenceLabel() {
    if (_livingEnvironment == 'apartment') return 'Apartment / Condo';
    if (_livingEnvironment == 'house' || _livingEnvironment == 'house_with_yard' || _livingEnvironment == 'house_no_yard') return 'House';
    if (_livingEnvironment == 'townhouse') return 'Townhouse / Duplex';
    return 'Standard Residence';
  }

  String _getYardLabel() {
    if (_yardType == 'fenced') return 'Fully Fenced Yard';
    if (_yardType == 'unfenced') return 'Unfenced Yard';
    if (_yardType == 'balcony') return 'Balcony / Patio';
    if (_yardType == 'none') return 'No Private Yard';
    return _hasYard == true ? 'Fenced Yard' : 'No Private Yard';
  }

  String _getActivityLabel() {
    if (_activityLevel == 'relaxed') return 'Calm & Relaxed (Indoor lounging)';
    if (_activityLevel == 'moderate') return 'Moderately Active (Daily walks)';
    if (_activityLevel == 'high') return 'High Energy (Running, hiking)';
    return 'Moderate';
  }

  String _getExperienceLabel() {
    if (_hasOtherPets == true) return 'Experienced Pet Owner';
    if (_petExperience == 'first_time') return 'First-time Pet Owner';
    if (_petExperience == 'experienced') return 'Experienced Pet Owner';
    return 'Standard';
  }

  String _getHoursAloneLabel() {
    if (_hoursAlone == '0_3') return '0 - 3 Hours';
    if (_hoursAlone == '4_7') return '4 - 7 Hours';
    if (_hoursAlone == '8_plus') return '8+ Hours';
    return '4 - 7 Hours';
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildRadioGroup({
    required List<Map<String, String>> options,
    required String? selected,
    required Function(String) onSelected,
  }) {
    return Column(
      children: options.map((opt) {
        final isSelected = opt['val'] == selected;
        return GestureDetector(
          onTap: () => onSelected(opt['val']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.4) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppTheme.primary : Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    opt['label']!,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: AppTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }



  // RESULTS VIEW
  Widget _buildResultsView() {
    final bottomInset = widget.isEmbeddedInTab ? 110.0 : 20.0;
    if (_recommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHouseholdCapacityCard(),
              const SizedBox(height: 12),
              const Icon(Icons.pets_rounded, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text(
                _adoptedCount >= 3 ? 'Adoption Limit Reached' : 'No direct matches found',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _adoptedCount >= 3
                    ? 'You have reached the maximum shelter adoption limit of 3 pets. Your household is currently at full capacity.'
                    : (_isLocked
                        ? 'No pets currently match your compatibility profile (minimum 80% compatibility threshold). Check back soon for newly rescued pets!'
                        : 'Try broadening your preferences or check back soon for newly rescued pets!'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Back to Pets',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final safeIndex = _selectedMatchIndex.clamp(0, _recommendations.isEmpty ? 0 : _recommendations.length - 1);
    final hasBottomAction = _isLocked;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14, 4, 14, widget.isEmbeddedInTab ? bottomInset : 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAiHeaderBanner(),
          if (_recommendations.length > 1) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openPetComparisonSheet,
                icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF0D9488)),
                label: Text(
                  'Compare Matches & Gemini AI Synthesis',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F766E),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0FDFA),
                  foregroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFF99F6E4), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (!_showAllInList && _recommendations.length > 1) ...[
            _buildRankTabs(),
            _buildMatchNavigatorHeader(safeIndex),
            const SizedBox(height: 6),
          ],
          if (_showAllInList) ...[
            ...List.generate(_recommendations.length, (idx) {
              return _buildSinglePetCard(_recommendations[idx], idx + 1);
            }),
          ] else ...[
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -180 && _selectedMatchIndex < _recommendations.length - 1) {
                    setState(() => _selectedMatchIndex++);
                  } else if (details.primaryVelocity! > 180 && _selectedMatchIndex > 0) {
                    setState(() => _selectedMatchIndex--);
                  }
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(safeIndex),
                  child: _buildSinglePetCard(_recommendations[safeIndex], safeIndex + 1),
                ),
              ),
            ),
          ],
          if (_recommendations.length > 1) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAllInList = !_showAllInList),
                  icon: Icon(
                    _showAllInList ? Icons.tab_rounded : Icons.view_agenda_outlined,
                    size: 15,
                    color: AppTheme.primary,
                  ),
                  label: Text(
                    _showAllInList ? 'Switch to Focused Match Tabs' : 'View All 3 as Stacked List',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildHouseholdCapacityCard(isCompact: true),
          const SizedBox(height: 4),
          if (hasBottomAction)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 20),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showResults = false),
                  icon: const Icon(Icons.assignment_outlined, size: 16),
                  label: Text(
                    'View Saved Preferences Summary',
                    style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5)),
                    foregroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiHeaderBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryDark, AppTheme.primary]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Center(
              child: LuminousAiOrb(size: 24),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top 3 Matched Companions',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Evaluated by Predictive Compatibility Engine',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 11, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  'AI Matched',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankTabs() {
    if (_recommendations.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: List.generate(_recommendations.length, (i) {
          final isSelected = _selectedMatchIndex == i;
          final pet = _recommendations[i];
          final rawPct = pet['match_percentage'] ?? pet['match_score'];
          final double rawDouble = (rawPct is num
              ? rawPct.toDouble()
              : (double.tryParse(rawPct.toString().replaceAll('%', '').trim()) ?? 80.0));
          final String matchPctStr = rawDouble.truncateToDouble() == rawDouble
              ? '${rawDouble.toInt()}%'
              : '${rawDouble.toStringAsFixed(1)}%';

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMatchIndex = i;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (i == 0) ...[
                      Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 2.5),
                    ],
                    Text(
                      'Rank ${i + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      matchPctStr,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? AppTheme.primary : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMatchNavigatorHeader(int currentIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Match ${currentIndex + 1} of ${_recommendations.length}',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: currentIndex > 0 ? () => setState(() => _selectedMatchIndex--) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 11,
                    color: currentIndex > 0 ? AppTheme.primary : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_recommendations.length, (dotIdx) {
                  final isActive = dotIdx == currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: isActive ? 10 : 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              GestureDetector(
                onTap: currentIndex < _recommendations.length - 1 ? () => setState(() => _selectedMatchIndex++) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: currentIndex < _recommendations.length - 1 ? AppTheme.primary : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePetCard(Map<String, dynamic> pet, int rankIndex) {
    final rawPct = pet['match_percentage'] ?? pet['match_score'];
    final double matchPct = rawPct is num
        ? rawPct.toDouble()
        : (double.tryParse(rawPct.toString().replaceAll('%', '').trim()) ?? 80.0);
    final rawReasons = pet['match_reasons'] ?? pet['reasons'];
    final reasons = (rawReasons as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final careTip = pet['care_tip']?.toString() ?? pet['consideration']?.toString();
    final petData = {
      ...pet,
      'id': pet['pet_id'] ?? pet['id'],
      'name': pet['name'] ?? 'Pet no. ${pet['pet_id']}',
      'breed': pet['breed'] ?? 'Mixed Breed',
      'size': pet['size'] ?? 'Medium',
      'age': pet['age'] ?? 'Adult',
      'gender': pet['gender'] ?? 'male',
      'type': pet['type'] ?? 'cat',
      'image': pet['photo_url'] ??
          (pet['photo_path'] != null
              ? ApiService.normalizeImageUrl(pet['photo_path'])
              : 'https://images.unsplash.com/photo-1543466835-00a7907e9de1'),
      'match_percentage': matchPct,
      'compatibility_score': matchPct,
      'isRecommended': true,
      'application_source': 'recommendation',
      'match_reasons': reasons,
      'reasons': reasons,
      'care_tip': careTip,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PetDetailScreen(pet: petData),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 66,
                        height: 66,
                        color: const Color(0xFFF1F5F9),
                        child: pet['photo_url'] != null || pet['photo_path'] != null
                            ? Image.network(
                                pet['photo_url'] ?? ApiService.normalizeImageUrl(pet['photo_path']),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(Icons.pets, color: Colors.grey),
                              )
                            : const Icon(Icons.pets, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet['name'] ?? 'Unnamed Pet',
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${pet['size'] != null ? pet['size'].toString() : 'Medium'} • ${pet['type'] != null ? (pet['type'].toString().toUpperCase()) : 'PET'} • ${pet['age'] ?? 'Adult'}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (pet['temperaments'] != null && (pet['temperaments'] as List).isNotEmpty)
                            Wrap(
                              spacing: 4,
                              runSpacing: 3,
                              children: (pet['temperaments'] as List).take(3).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    tag.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      color: const Color(0xFF475569),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (pet['compatibility_breakdown'] != null || pet['breakdown'] != null)
                  _buildCompatibilityBreakdown(
                    (pet['compatibility_breakdown'] ?? pet['breakdown']) as Map<String, dynamic>?,
                    pet['name']?.toString(),
                  ),
                if (reasons.isNotEmpty) ...[
                  const Divider(height: 12, thickness: 0.8, color: Color(0xFFE2E8F0)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: reasons.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3.5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4.5,
                              height: 4.5,
                              margin: const EdgeInsets.only(top: 5.5, right: 7),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D9488),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                r,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: const Color(0xFF334155),
                                  fontWeight: FontWeight.w400,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (careTip != null && careTip.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(7),
                      border: const Border(
                        left: BorderSide(color: Color(0xFFF59E0B), width: 3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Care Consideration',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          careTip,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: const Color(0xFF78350F),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PetDetailScreen(pet: petData),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'View Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleApplyDirect(petData),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Apply to Adopt',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
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

  Widget _buildHouseholdCapacityCard({bool isCompact = false}) {
    final count = _adoptedCount.clamp(0, 3);
    final remaining = (3 - count).clamp(0, 3);
    final isFull = count >= 3;

    if (isCompact) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isFull ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFull ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isFull
                    ? const Color(0xFFFEF3C7)
                    : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.pets_rounded,
                size: 14,
                color: isFull ? const Color(0xFFD97706) : AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Household Capacity: $count/3 Active Pets',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: isFull ? const Color(0xFFFEF3C7) : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isFull ? 'Limit Reached' : '$remaining slots open',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isFull ? const Color(0xFFB45309) : AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFull ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFull ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isFull
                      ? const Color(0xFFFEF3C7)
                      : AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.pets_rounded,
                  size: 18,
                  color: isFull ? const Color(0xFFD97706) : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Household Adoption Capacity',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      isFull
                          ? 'Maximum Shelter Limit Reached'
                          : remaining == 1
                              ? '1 adoption slot remaining'
                              : '$remaining adoption slots open',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isFull ? const Color(0xFFB45309) : const Color(0xFF64748B),
                        fontWeight: isFull ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFull ? const Color(0xFFFEF3C7) : AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count / 3',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isFull ? const Color(0xFFB45309) : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 3-Segment Visual Capacity Bar
          Row(
            children: List.generate(3, (index) {
              final isAdopted = index < count;
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 3,
                    right: index == 2 ? 0 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: isAdopted
                        ? (isFull ? const Color(0xFFD97706) : AppTheme.primary)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            isFull
                ? 'Your home has welcomed 3 companions and reached maximum adoption limit under shelter guidelines.'
                : 'CAWS shelter policy allows up to 3 adopted pets per verified household to ensure optimal care.',
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCompatibilityBreakdown(Map<String, dynamic>? breakdown, [String? petName]) {
    if (breakdown == null || breakdown.isEmpty) return const SizedBox.shrink();

    final space = (breakdown['space'] as num?)?.toInt() ?? 88;
    final routine = (breakdown['routine'] as num?)?.toInt() ?? 85;
    final temperament = (breakdown['temperament'] as num?)?.toInt() ?? 90;
    final name = petName ?? 'this pet';

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildBreakdownColumn('Space Fit', space, name),
          Container(width: 1, height: 16, color: const Color(0xFFE2E8F0)),
          _buildBreakdownColumn('Routine', routine, name),
          Container(width: 1, height: 16, color: const Color(0xFFE2E8F0)),
          _buildBreakdownColumn('Temperament', temperament, name),
        ],
      ),
    );
  }

  Widget _buildBreakdownColumn(String label, int pct, String petName) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showPillarExplanationDialog(label, pct, petName),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                '$pct%',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F766E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPillarExplanationDialog(String label, int pct, String petName) {
    IconData icon;
    Color iconColor;
    Color bgBadgeColor;
    String pillarTitle;
    String description;
    List<Map<String, String>> factors;

    if (label.contains('Space')) {
      icon = Icons.home_work_outlined;
      iconColor = const Color(0xFF0284C7);
      bgBadgeColor = const Color(0xFFE0F2FE);
      pillarTitle = 'Space & Living Fit';
      description = 'Evaluates your home type and outdoor yard access against $petName\'s physical size, exercise bounds, and species roaming habits.';
      factors = [
        {'title': 'Residence Type', 'desc': _livingEnvironment == 'apartment' ? 'Apartment / Condo' : 'House / Single Family Home'},
        {'title': 'Yard Access', 'desc': _hasYard == true ? 'Outdoor yard space available' : 'No private yard access'},
        {'title': 'Pet Size Match', 'desc': 'Cross-referenced with adult size and activity needs'},
      ];
    } else if (label.contains('Routine')) {
      icon = Icons.access_time_rounded;
      iconColor = const Color(0xFFD97706);
      bgBadgeColor = const Color(0xFFFEF3C7);
      pillarTitle = 'Daily Routine Alignment';
      description = 'Evaluates your daily work hours alone and lifestyle pace against $petName\'s independence and separation comfort.';
      factors = [
        {'title': 'Work Routine', 'desc': _hoursAlone == '0_3' ? '0 to 3 hours alone daily' : (_hoursAlone == '8_plus' ? '8+ hours alone daily' : '4 to 7 standard hours')},
        {'title': 'Lifestyle Pace', 'desc': (_activityLevel ?? 'moderate').toUpperCase()},
        {'title': 'Separation Comfort', 'desc': 'Matched with natural independence and separation ease'},
      ];
    } else {
      icon = Icons.favorite_outline_rounded;
      iconColor = const Color(0xFF059669);
      bgBadgeColor = const Color(0xFFD1FAE5);
      pillarTitle = 'Behavioral & Temperament Synergy';
      description = 'Evaluates your household safety dynamics and preferred companion qualities against verified shelter temperament tags.';
      factors = [
        {'title': 'Household Safety', 'desc': '${_hasChildren == true ? 'Children in household' : 'No young kids'} • ${_hasOtherPets == true ? 'Resident pets present' : 'No other pets'}'},
        {'title': 'Desired Qualities', 'desc': _desiredTemperaments.isEmpty ? 'Flexible temperament preference' : _desiredTemperaments.join(', ')},
        {'title': 'Pet Temperament', 'desc': 'Validated through shelter behavioral intake assessments'},
      ];
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgBadgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pillarTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    '$pct% Compatibility Score',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: factors.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF334155)),
                              children: [
                                TextSpan(
                                  text: '${f['title']}: ',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: f['desc'] ?? '',
                                  style: const TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
              child: Text(
                'Understood',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPetComparisonSheet() {
    if (_recommendations.isEmpty) return;
    PetComparisonSheet.show(
      context: context,
      pets: _recommendations,
      comparativeAnalysis: RecommendationService.comparativeAnalysis,
      onApply: (selectedPets) {
        if (selectedPets.length == 1) {
          _handleApplyDirect(selectedPets.first);
        } else {
          final payload = <String, dynamic>{
            'pet': selectedPets.first,
            'selected_pets': selectedPets,
          };
          _handleApplyDirect(payload);
        }
      },
    );
  }

  Future<void> _handleApplyDirect(Map<String, dynamic> petData) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit an adoption application.')),
      );
      return;
    }

    if (_adoptedCount >= 3) {
      if (!mounted) return;
      AppConfirmationDialog.show(
        context,
        icon: Icons.block_rounded,
        iconColor: const Color(0xFFD97706),
        iconBackgroundColor: const Color(0xFFFEF3C7),
        title: 'Adoption Limit Reached',
        message: 'Your household has welcomed 3 companions and reached the maximum adoption limit under shelter guidelines.',
        cancelText: 'Close',
        confirmText: 'Understood',
        onConfirm: () {},
      );
      return;
    }

    final user = await ApiService.getProfile();
    if (user != null && (user['status'] == 'blacklisted' || user['status'] == 'restricted')) {
      final isBlacklisted = user['status'] == 'blacklisted';
      final rawNotes = user['admin_notes']?.toString().trim();
      final officialReason = (rawNotes != null && rawNotes.isNotEmpty)
          ? rawNotes
          : (isBlacklisted
              ? 'Non-compliance with CAWS adoption terms and animal welfare standards.'
              : 'Account under shelter administrative review.');

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(isBlacklisted ? 'Account Blacklisted' : 'Account Restricted'),
          content: Text(officialReason),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final userId = user != null ? user['id'] : 'guest';
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('user_${userId}_full_address') ?? (user != null ? user['address'] as String? : null);
    final phone = prefs.getString('user_${userId}_phone') ?? (user != null ? user['phone'] as String? : null);

    if (address == null || address.trim().isEmpty) {
      if (!mounted) return;
      AppConfirmationDialog.show(
        context,
        icon: Icons.location_on_outlined,
        iconColor: AppTheme.primary,
        iconBackgroundColor: AppTheme.primaryLight,
        title: 'Address Required',
        message: 'Please set your location in your profile first before applying for adoption.',
        cancelText: 'Later',
        confirmText: 'Set Address',
        onConfirm: () {
          Navigator.pushNamed(context, '/edit-address');
        },
      );
      return;
    }

    if (phone == null || phone.trim().isEmpty) {
      if (!mounted) return;
      AppConfirmationDialog.show(
        context,
        icon: Icons.phone_android_rounded,
        iconColor: AppTheme.primary,
        iconBackgroundColor: AppTheme.primaryLight,
        title: 'Phone Number Required',
        message: 'Please fill in your mobile number in your profile first before applying for adoption.',
        cancelText: 'Later',
        confirmText: 'Add Phone',
        onConfirm: () {
          Navigator.pushNamed(context, '/profile');
        },
      );
      return;
    }

    if (!mounted) return;
    await Navigator.pushNamed(
      context,
      '/adoption-form',
      arguments: petData,
    );
    if (mounted) {
      final appliedIds = <String>{};
      if (petData['selected_pets'] is List) {
        for (final p in (petData['selected_pets'] as List)) {
          final idStr = (p['pet_id'] ?? p['id'])?.toString();
          if (idStr != null) appliedIds.add(idStr);
        }
      } else {
        final idStr = (petData['pet_id'] ?? petData['id'])?.toString();
        if (idStr != null) appliedIds.add(idStr);
      }
      if (appliedIds.isNotEmpty) {
        setState(() {
          _recommendations.removeWhere((p) => appliedIds.contains((p['pet_id'] ?? p['id'])?.toString()));
          if (_selectedMatchIndex >= _recommendations.length) {
            _selectedMatchIndex = 0;
          }
        });
      }
      _fetchSavedRecommendations();
    }
  }

}
