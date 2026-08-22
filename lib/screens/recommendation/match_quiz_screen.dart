import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/screens/pets/pet_detail_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

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

  // Step 1: Basics & Appearance
  String _preferredSpecies = 'any';
  String _preferredAge = 'any';
  String _preferredGender = 'any';
  String _preferredColor = 'any';

  // Step 2: Living & Lifestyle
  String _livingEnvironment = 'apartment';
  String _activityLevel = 'moderate';

  // Step 3: Experience & Household
  String _petExperience = 'first_time';
  bool _hasChildren = false;
  bool _hasOtherPets = false;

  // Step 4: Capacity & Temperament
  String _hoursAlone = '4_7';
  bool _specialCareCapacity = false;
  final Set<String> _desiredTemperaments = {'Friendly', 'Calm', 'Affectionate'};

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

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await ApiService.getSavedPreferences();
      if (prefs != null && mounted) {
        setState(() {
          _preferredSpecies = prefs['preferred_species'] ?? 'any';
          _preferredAge = prefs['preferred_age'] ?? 'any';
          _preferredGender = prefs['preferred_gender'] ?? 'any';
          _preferredColor = prefs['preferred_color'] ?? 'any';
          _livingEnvironment = prefs['living_environment'] ?? 'apartment';
          _activityLevel = prefs['activity_level'] ?? 'moderate';
          _petExperience = prefs['pet_experience'] ?? 'first_time';
          _hasChildren = prefs['has_children'] == true || prefs['has_children'] == 1;
          _hasOtherPets = prefs['has_other_pets'] == true || prefs['has_other_pets'] == 1;
          _hoursAlone = prefs['hours_alone'] ?? '4_7';
          _specialCareCapacity = prefs['special_care_capacity'] == true || prefs['special_care_capacity'] == 1;
          if (prefs['desired_temperaments'] != null) {
            _desiredTemperaments.clear();
            _desiredTemperaments.addAll(List<String>.from(prefs['desired_temperaments']));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _submitQuiz() async {
    setState(() => _isLoading = true);

    final payload = {
      'preferred_species': _preferredSpecies,
      'preferred_age': _preferredAge,
      'preferred_gender': _preferredGender,
      'preferred_color': _preferredColor,
      'living_environment': _livingEnvironment,
      'activity_level': _activityLevel,
      'pet_experience': _petExperience,
      'has_children': _hasChildren,
      'has_other_pets': _hasOtherPets,
      'hours_alone': _hoursAlone,
      'special_care_capacity': _specialCareCapacity,
      'desired_temperaments': _desiredTemperaments.toList(),
    };

    try {
      final recs = await ApiService.getRecommendations(profile: payload);
      final availableRecs = recs.where((pet) {
        final status = pet['status']?.toString().toLowerCase();
        return status == null || status == 'available';
      }).toList();
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
          _showResults ? 'Your Top Pet Matches' : 'Pet Match Quiz',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),
        ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing Compatibility...',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Running Machine Learning Cosine Similarity Model\nagainst shelter pets...',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
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
                        onPressed: () {
                          if (_currentStep < 3) {
                            setState(() => _currentStep++);
                          } else {
                            _submitQuiz();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: Text(
                          _currentStep < 3 ? 'Next Step →' : 'Find My Perfect Match 🐾',
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
        Text('Pet Preferences 🐾', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('Tell us what kind of pet you are looking for', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        _buildSectionTitle('Preferred Pet Species'),
        _buildRadioGroup(
          options: [
            {'val': 'any', 'label': 'Any Species 🐾'},
            {'val': 'dog', 'label': 'Dogs Only 🐶'},
            {'val': 'cat', 'label': 'Cats Only 🐱'},
          ],
          selected: _preferredSpecies,
          onSelected: (val) => setState(() => _preferredSpecies = val),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Preferred Age Group'),
        _buildRadioGroup(
          options: [
            {'val': 'any', 'label': 'Any Age'},
            {'val': 'kitten_puppy', 'label': 'Puppy / Kitten (< 1 yr)'},
            {'val': 'young', 'label': 'Young (1 - 3 yrs)'},
            {'val': 'adult', 'label': 'Adult (3 - 7 yrs)'},
            {'val': 'senior', 'label': 'Senior (8+ yrs)'},
          ],
          selected: _preferredAge,
          onSelected: (val) => setState(() => _preferredAge = val),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Preferred Gender'),
        _buildRadioGroup(
          options: [
            {'val': 'any', 'label': 'Any'},
            {'val': 'male', 'label': 'Male ♂'},
            {'val': 'female', 'label': 'Female ♀'},
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
        Text('Living Space & Routine 🏡', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('Helps match pets that thrive in your living environment', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        _buildSectionTitle('Your Residence Type'),
        _buildRadioGroup(
          options: [
            {'val': 'apartment', 'label': 'Apartment / Condominium 🏢'},
            {'val': 'house_with_yard', 'label': 'House with Fenced Yard 🏡'},
            {'val': 'house_no_yard', 'label': 'House without Yard 🏠'},
          ],
          selected: _livingEnvironment,
          onSelected: (val) => setState(() => _livingEnvironment = val),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Your Activity Level'),
        _buildRadioGroup(
          options: [
            {'val': 'relaxed', 'label': 'Calm & Relaxed 🛋️ (Indoor lounging)'},
            {'val': 'moderate', 'label': 'Moderately Active 🚶 (Daily walks & play)'},
            {'val': 'high', 'label': 'High Energy 🏃 (Running, hiking, outdoors)'},
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
        Text('Experience & Household 👨‍👩‍👧‍👦', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text('Ensures the pet is safe and friendly with everyone in your home', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 24),
        _buildSectionTitle('Your Experience with Pets'),
        _buildRadioGroup(
          options: [
            {'val': 'first_time', 'label': 'First-time Pet Owner 🔰'},
            {'val': 'experienced', 'label': 'Experienced Pet Owner 🏆'},
          ],
          selected: _petExperience,
          onSelected: (val) => setState(() => _petExperience = val),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Household Members'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Children in home', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('Recommends gentle & family-friendly pets', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
          value: _hasChildren,
          activeColor: AppTheme.primary,
          onChanged: (val) => setState(() => _hasChildren = val),
        ),
        const Divider(height: 20),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Existing pets in home', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('Recommends pets tested friendly with other animals', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
          value: _hasOtherPets,
          activeColor: AppTheme.primary,
          onChanged: (val) => setState(() => _hasOtherPets = val),
        ),
      ],
    );
  }

  // STEP 4: Capacity to Care & Temperament Traits
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Care Capacity & Traits 💖', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
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
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Open to Special Care / Medical Needs', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('Open to adopting pets with special dietary or maintenance needs', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
          value: _specialCareCapacity,
          activeColor: AppTheme.primary,
          onChanged: (val) => setState(() => _specialCareCapacity = val),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('Desired Pet Temperaments (Select traits)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allTemperaments.map((tag) {
            final isSelected = _desiredTemperaments.contains(tag);
            return FilterChip(
              label: Text(tag, style: GoogleFonts.poppins(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
              selected: isSelected,
              selectedColor: AppTheme.primaryLight,
              checkmarkColor: AppTheme.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: isSelected ? AppTheme.primary : Colors.grey.shade300),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _desiredTemperaments.add(tag);
                  } else {
                    if (_desiredTemperaments.length > 1) {
                      _desiredTemperaments.remove(tag);
                    }
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
    required String selected,
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
              color: isSelected ? AppTheme.primaryLight.withOpacity(0.4) : Colors.white,
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
    required String selected,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return ChoiceChip(
          label: Text(opt, style: GoogleFonts.poppins(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
          selected: isSelected,
          selectedColor: AppTheme.primaryLight,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: isSelected ? AppTheme.primary : Colors.grey.shade300),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top Matching Candidates 🌟', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Ranked using Scikit-Learn Cosine Similarity',
                          style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.85), fontSize: 11)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _showResults = false),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
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
                'id': pet['pet_id'] ?? pet['id'],
                'name': pet['name'] ?? 'Pet #${pet['pet_id']}',
                'breed': pet['breed'] ?? 'Mixed Breed',
                'age': pet['age'] ?? 'Adult',
                'gender': pet['gender'] ?? 'male',
                'type': pet['type'] ?? 'cat',
                'image': pet['photo_url'] ??
                    (pet['photo_path'] != null
                        ? 'http://10.0.2.2:8000/storage/${pet['photo_path']}'
                        : 'https://images.unsplash.com/photo-1543466835-00a7907e9de1'),
                'match_percentage': pet['match_percentage'],
                'isRecommended': true,
                ...pet,
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
                                  pet['photo_url'] ?? 'http://10.0.2.2:8000/storage/${pet['photo_path']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.pets, color: Colors.grey),
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
                                        ? AppTheme.successColor.withOpacity(0.12)
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
