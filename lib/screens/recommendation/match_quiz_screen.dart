import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/screens/pets/pet_detail_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/ai_recommendation_hero.dart';
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
  String _loadingStatus = 'Analyzing your living environment and lifestyle compatibility...';
  int _loadingStep = 1;

  // Step 1: Companion Type Selection
  String? _preferredSpecies;

  // Step 2: Living & Lifestyle
  String? _livingEnvironment;
  String? _activityLevel;

  // Step 3: Experience & Household
  String? _petExperience;
  bool? _hasChildren;
  bool? _hasOtherPets;

  // Step 4: Capacity & Temperament
  String? _hoursAlone;
  bool? _specialCareCapacity;
  final Set<String> _desiredTemperaments = {};

  final List<String> _allTemperaments = [
    'Friendly',
    'Calm',
    'Energetic',
    'Playful',
    'Affectionate',
    'Independent',
    'Protective',
    'Shy',
  ];

  bool get _hasAnySelection =>
      _preferredSpecies != null ||
      _livingEnvironment != null ||
      _activityLevel != null ||
      _petExperience != null ||
      _hasChildren != null ||
      _hasOtherPets != null ||
      _hoursAlone != null ||
      _specialCareCapacity != null ||
      _desiredTemperaments.isNotEmpty;

  void _resetQuiz() {
    if (_isLocked) return;
    setState(() {
      _currentStep = 0;
      _preferredSpecies = null;
      _livingEnvironment = null;
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
      if (mounted) {
        setState(() {
          _isLocked = isLockedCached;
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
        }

        setState(() {
          _isLocked = true;
          _preferredSpecies = saved['preferred_species']?.toString();
          _livingEnvironment = saved['living_environment']?.toString();
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
        }

        setState(() {
          _isLocked = false;
          _showResults = false;
          _currentStep = 0;
          _recommendations = [];
          _preferredSpecies = null;
          _livingEnvironment = null;
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
      final availableRecs = recs.where((pet) {
        final status = pet['status']?.toString().trim().toLowerCase();
        return status == 'available';
      }).take(3).toList();
      if (mounted) {
        setState(() {
          _recommendations = availableRecs;
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
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Submit Assessment?',
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
              'Please review your answers before submitting. In accordance with shelter policy:',
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
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogBullet('Your answers cannot be edited or modified after submission.'),
                  const SizedBox(height: 6),
                  _buildDialogBullet('You will not be able to retake the quiz again.'),
                  const SizedBox(height: 6),
                  _buildDialogBullet('Recommendations will be permanently based on these answers.'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Are you sure you want to finalize and submit to the recommendation engine?',
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'Review Again',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            child: Text(
              'Confirm & Submit',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
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

    final payload = {
      'preferred_species': _preferredSpecies ?? 'any',
      'preferred_age': 'any',
      'preferred_gender': 'any',
      'preferred_color': 'any',
      'living_environment': _livingEnvironment ?? 'apartment',
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
      final availableRecs = recs.where((pet) {
        final status = pet['status']?.toString().trim().toLowerCase();
        return status == 'available';
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
          }
          await prefs.remove('quiz_locked');
        } catch (_) {}
        setState(() {
          _isLocked = true;
          _recommendations = availableRecs;
          _showResults = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
      if (_desiredTemperaments.isEmpty) {
        _showValidationError('Please select at least one desired pet temperament.');
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
            {'val': 'house_with_yard', 'label': 'House with Fenced Yard'},
            {'val': 'house_no_yard', 'label': 'House without Yard'},
          ],
          selected: _livingEnvironment,
          onSelected: (val) => setState(() => _livingEnvironment = val),
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
          selected: _petExperience,
          onSelected: (val) => setState(() => _petExperience = val),
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
          onSelected: (val) => setState(() => _hasOtherPets = val == 'yes'),
        ),
      ],
    );
  }

  // STEP 4: Capacity to Care & Temperament Traits
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Care Capacity & Traits', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('Matches pets based on your daily schedule and desired personality', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        _buildSectionTitle('Hours pet will be left alone daily'),
        _buildRadioGroup(
          options: [
            {'val': '0_3', 'label': '0 - 3 Hours (Full attention & companionship)'},
            {'val': '4_7', 'label': '4 - 7 Hours (Standard work routine)'},
            {'val': '8_plus', 'label': '8+ Hours (Matched with independent pets)'},
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
        const SizedBox(height: 20),
        _buildSectionTitle('Desired Pet Temperaments (Select traits)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allTemperaments.map((tag) {
            final isSelected = _desiredTemperaments.contains(tag);
            return FilterChip(
              label: Text(
                tag,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryLight,
              checkmarkColor: AppTheme.primaryDark,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _desiredTemperaments.add(tag);
                  } else {
                    _desiredTemperaments.remove(tag);
                  }
                });
              },
            );
          }).toList(),
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

        // Prominent Warning Notice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important: One-Time Submission Only',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please review all your answers carefully. Once submitted, your quiz responses cannot be changed, edited, or retaken. The recommendation engine will permanently use these responses for your pet matches.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF78350F),
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

        // Section 4: Care Capacity & Temperaments Summary
        _buildReviewSectionCard(
          title: 'Care Capacity & Temperament',
          stepIndex: 3,
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
              if (showEditButton && !_isLocked)
                InkWell(
                  onTap: () => setState(() => _currentStep = stepIndex),
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
  Widget _buildLockedProfileView() {
    final bottomInset = widget.isEmbeddedInTab ? 100.0 : 24.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Locked Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_rounded, color: Color(0xFF334155), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compatibility Quiz Locked',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You have already submitted and finalized your compatibility assessment. In accordance with shelter policy, assessment answers are permanent and cannot be modified or retaken.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
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
            showEditButton: false,
            rows: [
              {'label': 'Species', 'val': _getSpeciesLabel()},
            ],
          ),

          _buildReviewSectionCard(
            title: 'Living Space & Routine',
            stepIndex: 1,
            showEditButton: false,
            rows: [
              {'label': 'Residence', 'val': _getResidenceLabel()},
              {'label': 'Activity Level', 'val': _getActivityLabel()},
            ],
          ),

          _buildReviewSectionCard(
            title: 'Experience & Household',
            stepIndex: 2,
            showEditButton: false,
            rows: [
              {'label': 'Pet Experience', 'val': _getExperienceLabel()},
              {'label': 'Children in Home', 'val': _hasChildren == true ? 'Yes, children present' : 'No children'},
              {'label': 'Existing Pets', 'val': _hasOtherPets == true ? 'Yes, other pets in home' : 'No other pets'},
            ],
          ),

          _buildReviewSectionCard(
            title: 'Care Capacity & Temperament',
            stepIndex: 3,
            showEditButton: false,
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
    if (_livingEnvironment == 'apartment') return 'Apartment / Condominium';
    if (_livingEnvironment == 'house_with_yard') return 'House with Fenced Yard';
    if (_livingEnvironment == 'house_no_yard') return 'House without Yard';
    return 'Standard Residence';
  }

  String _getActivityLabel() {
    if (_activityLevel == 'relaxed') return 'Calm & Relaxed (Indoor lounging)';
    if (_activityLevel == 'moderate') return 'Moderately Active (Daily walks)';
    if (_activityLevel == 'high') return 'High Energy (Running, hiking)';
    return 'Moderate';
  }

  String _getExperienceLabel() {
    if (_petExperience == 'first_time') return 'First-time Pet Owner';
    if (_petExperience == 'experienced') return 'Experienced Pet Owner';
    return 'Standard';
  }

  String _getHoursAloneLabel() {
    if (_hoursAlone == '0_3') return '0 - 3 Hours (Full attention)';
    if (_hoursAlone == '4_7') return '4 - 7 Hours (Standard work routine)';
    if (_hoursAlone == '8_plus') return '8+ Hours (Independent pets)';
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
              const Icon(Icons.pets_rounded, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text('No direct matches found', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                _isLocked
                    ? 'No pets currently match your locked preferences. Check back soon for newly rescued pets!'
                    : 'Try broadening your preferences or check back soon for newly rescued pets!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: Text('Back to Pets', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final hasBottomAction = _isLocked;
    final totalItems = _recommendations.length + 1 + (hasBottomAction ? 1 : 0);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryDark, AppTheme.primary]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: LuminousAiOrb(size: 34),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top 3 Matched Companions', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Ranked by AI Compatibility (Shelter policy: up to 3 adoptions)',
                          style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'AI Matched',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
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

        if (hasBottomAction && index > _recommendations.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
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
          );
        }

        if (index - 1 < 0 || index - 1 >= _recommendations.length) {
          return const SizedBox.shrink();
        }

        final pet = _recommendations[index - 1];
        final rawPct = pet['match_percentage'] ?? pet['match_score'];
        final double matchPct = rawPct is num
            ? rawPct.toDouble()
            : (double.tryParse(rawPct.toString().replaceAll('%', '').trim()) ?? 80.0);
        final rawReasons = pet['match_reasons'] ?? pet['reasons'];
        final reasons = (rawReasons as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
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
                'match_percentage': pet['match_percentage'],
                'compatibility_score': pet['match_percentage'],
                'isRecommended': true,
                'application_source': 'recommendation',
                'match_reasons': reasons,
                'reasons': reasons,
              };
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PetDetailScreen(pet: petData),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: pet['photo_url'] != null || pet['photo_path'] != null
                              ? Image.network(
                                  pet['photo_url'] ?? ApiService.normalizeImageUrl(pet['photo_path']),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(Icons.pets, color: Colors.grey),
                                )
                              : const Icon(Icons.pets, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: index == 1
                                    ? const Color(0xFFE0F2FE)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: index == 1
                                      ? const Color(0xFFBAE6FD)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                index == 1 ? 'Rank #1 • Best Match' : 'Rank #$index Match',
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: index == 1
                                      ? AppTheme.primaryDark
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    pet['name'] ?? 'Unnamed Pet',
                                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: matchPct >= 90
                                        ? AppTheme.successColor.withValues(alpha: 0.12)
                                        : AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${matchPct.toInt()}% Match',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: matchPct >= 90 ? AppTheme.successColor : AppTheme.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${pet['size'] != null ? pet['size'].toString() : 'Medium'} • ${pet['type'] != null ? (pet['type'].toString().toUpperCase()) : 'PET'} • ${pet['age'] ?? 'Adult'}',
                              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            if (pet['temperaments'] != null && (pet['temperaments'] as List).isNotEmpty)
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: (pet['temperaments'] as List).take(3).map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tag.toString(),
                                      style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (reasons.isNotEmpty) ...[
                    const Divider(height: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: reasons.map((r) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  r,
                                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
