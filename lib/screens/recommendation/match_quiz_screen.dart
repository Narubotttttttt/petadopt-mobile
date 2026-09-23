import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/screens/pets/pet_detail_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/pet_recommendation_loader.dart';

class MatchQuizScreen extends StatefulWidget {
  const MatchQuizScreen({super.key});

  @override
  State<MatchQuizScreen> createState() => _MatchQuizScreenState();
}

class _MatchQuizScreenState extends State<MatchQuizScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _showResults = false;
  List<Map<String, dynamic>> _recommendations = [];
  String _loadingStatus = 'Analyzing your preferred color, age & gender...';
  int _loadingStep = 1;

  // Step 1: Basics & Appearance
  String? _preferredSpecies;
  String? _preferredAge;
  String? _preferredGender;
  String? _preferredColor;

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
      _preferredAge != null ||
      _preferredGender != null ||
      _preferredColor != null ||
      _livingEnvironment != null ||
      _activityLevel != null ||
      _petExperience != null ||
      _hasChildren != null ||
      _hasOtherPets != null ||
      _hoursAlone != null ||
      _specialCareCapacity != null ||
      _desiredTemperaments.isNotEmpty;

  void _resetQuiz() {
    setState(() {
      _currentStep = 0;
      _preferredSpecies = null;
      _preferredAge = null;
      _preferredGender = null;
      _preferredColor = null;
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


  Future<void> _submitQuiz() async {
    setState(() {
      _isLoading = true;
      _loadingStep = 1;
      _loadingStatus = 'Analyzing your preferred color, age & gender traits...';
    });

    final payload = {
      'preferred_species': _preferredSpecies ?? 'any',
      'preferred_age': _preferredAge ?? 'any',
      'preferred_gender': _preferredGender ?? 'any',
      'preferred_color': _preferredColor ?? 'any',
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
          _loadingStatus = 'Evaluating pet temperaments & lifestyle fit...';
        });
      }

      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted && _isLoading) {
        setState(() {
          _loadingStep = 3;
          _loadingStatus = 'Ranking top matches by demographic & lifestyle alignment...';
        });
      }

      final recs = await recsFuture;
      final availableRecs = recs.where((pet) {
        final status = pet['status']?.toString().toLowerCase();
        return status == null || status == 'available';
      }).toList();

      // Ensure the full animated recommendation evaluation cycle finishes naturally (~3.5s total)
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 3400) {
        await Future.delayed(Duration(milliseconds: 3400 - elapsed));
      }

      if (mounted) {
        setState(() {
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_showResults) {
              setState(() => _showResults = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _showResults ? 'Your Top Pet Matches' : 'Match a Pet',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_showResults && !_isLoading && _hasAnySelection)
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
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _showResults
              ? _buildResultsView()
              : _buildQuizView(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PetRecommendationLoader(
              size: 130,
              color: Color(0xFF1E293B),
              withSparkles: true,
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
        _showValidationError('Please select a preferred species (or Any Species).');
        return;
      }
      if (_preferredAge == null) {
        _showValidationError('Please select a preferred age group (or Any Age).');
        return;
      }
      if (_preferredGender == null) {
        _showValidationError('Please select a preferred gender (or Any).');
        return;
      }
      if (_preferredColor == null) {
        _showValidationError('Please select a preferred coat color (or Any Color).');
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

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _submitQuiz();
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
    return Column(
      children: [
        _buildProgressBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentStep == 0) _buildStep1(),
                if (_currentStep == 1) _buildStep2(),
                if (_currentStep == 2) _buildStep3(),
                if (_currentStep == 3) _buildStep4(),
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
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: Text(
                          _currentStep < 3 ? 'Next Step' : 'Find My Perfect Match',
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
    final titles = ['Preferences', 'Living Space', 'Experience', 'Personality'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${_currentStep + 1} of 4: ${titles[_currentStep]}',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              Text('${((_currentStep + 1) / 4 * 100).toInt()}%',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 4,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // STEP 1: Species, Age, Gender, Color
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pet Preferences', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('Tell us what kind of pet you are looking for', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        _buildSectionTitle('Preferred Pet Species'),
        _buildRadioGroup(
          options: [
            {'val': 'any', 'label': 'Any Species'},
            {'val': 'dog', 'label': 'Dogs Only'},
            {'val': 'cat', 'label': 'Cats Only'},
          ],
          selected: _preferredSpecies,
          onSelected: (val) => setState(() => _preferredSpecies = val),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Preferred Age Group'),
        _buildRadioGroup(
          options: [
            {'val': 'any', 'label': 'Any Age'},
            {'val': 'kitten_puppy', 'label': 'Puppy / Kitten (1-6months)'},
            {'val': 'adult', 'label': 'Adult (1+ yrs)'},
          ],
          selected: _preferredAge,
          onSelected: (val) => setState(() => _preferredAge = val),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Preferred Gender'),
        _buildRadioGroup(
          options: [
            {'val': 'any', 'label': 'Any'},
            {'val': 'male', 'label': 'Male'},
            {'val': 'female', 'label': 'Female'},
          ],
          selected: _preferredGender,
          onSelected: (val) => setState(() => _preferredGender = val),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Preferred Coat Color'),
        _buildChipGroup(
          options: [
            'Any Color',
            'Orange/Ginger',
            'Black',
            'White',
            'Brown/Tan',
            'Tricolor/Calico',
            'Gray',
            'Tabby/Striped',
          ],
          selected: _preferredColor == 'any' ? 'Any Color' : _preferredColor,
          onSelected: (val) {
            setState(() => _preferredColor = val == 'Any Color' ? 'any' : val);
          },
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

  Widget _buildChipGroup({
    required List<String> options,
    required String? selected,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return ChoiceChip(
          label: Text(
            opt,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
            ),
          ),
          selected: isSelected,
          selectedColor: AppTheme.primaryLight,
          backgroundColor: Colors.white,
          showCheckmark: true,
          checkmarkColor: AppTheme.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? AppTheme.primary : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          onSelected: (_) => onSelected(opt),
        );
      }).toList(),
    );
  }

  // RESULTS VIEW
  Widget _buildResultsView() {
    if (_recommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets_rounded, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text('No direct matches found', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Try broadening your preferences or check back soon for newly rescued pets!',
                  textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => _showResults = false),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                child: Text('Adjust Quiz Answers', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendations.length + 1,
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
                    child: PetRecommendationIcon(
                      size: 32,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top Matching Candidates', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Ranked using Scikit-Learn Cosine Similarity',
                          style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _showResults = false),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Edit Quiz', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }

        final pet = _recommendations[index - 1];
        final matchPct = (pet['match_percentage'] as num?)?.toDouble() ?? 80.0;
        final reasons = (pet['match_reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

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
                              '${pet['breed'] ?? 'Mixed Breed'} • ${pet['age'] ?? 'Adult'}',
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
