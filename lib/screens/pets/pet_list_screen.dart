import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/pet_card.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  bool _hasTakenQuiz = false;

  final List<String> _filters = ['All', 'Dogs', 'Cats'];

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecommendations() async {
    setState(() => _isLoading = true);
    try {
      final savedPrefs = await ApiService.getSavedPreferences();
      final recs = await ApiService.getRecommendations();

      final availableRecs = recs.where((pet) {
        final status = pet['status']?.toString().toLowerCase();
        return status == null || status == 'available';
      }).toList();

      final mapped = availableRecs.map((raw) {
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
          _recommendations = mapped;
          _hasTakenQuiz = savedPrefs != null || recs.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPets {
    return _recommendations.where((pet) {
      // Species filter
      if (_selectedFilter == 'Dogs') {
        final t = (pet['type'] ?? '').toString().toLowerCase();
        if (t != 'dog') return false;
      } else if (_selectedFilter == 'Cats') {
        final t = (pet['type'] ?? '').toString().toLowerCase();
        if (t != 'cat') return false;
      }

      // Keyword search
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final name = (pet['name'] ?? '').toString().toLowerCase();
        final breed = (pet['breed'] ?? '').toString().toLowerCase();
        final color = (pet['color'] ?? '').toString().toLowerCase();
        final type = (pet['type'] ?? '').toString().toLowerCase();
        final idStr = (pet['id'] ?? '').toString();

        final matchesName = name.contains(q);
        final matchesBreed = breed.contains(q);
        final matchesColor = color.contains(q);
        final matchesType = type.contains(q);
        final matchesId = idStr == q || q == 'pet no. $idStr' || q == 'pet $idStr';

        if (!matchesName && !matchesBreed && !matchesColor && !matchesType && !matchesId) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  Future<void> _openQuiz() async {
    final result = await Navigator.pushNamed(context, '/match-quiz');
    if (result == true || mounted) {
      _fetchRecommendations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedPets = _filteredPets;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalized Matches',
              style: GoogleFonts.poppins(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Ranked by AI Compatibility',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: const Icon(Icons.tune_rounded, size: 16, color: AppTheme.primaryDark),
              label: Text(
                'Refine',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
              backgroundColor: AppTheme.primaryLight,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onPressed: _openQuiz,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRecommendations,
        color: AppTheme.primary,
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search within your matches...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            // Species Filter Chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => _onFilterSelected(filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.cardBorder,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : (!_hasTakenQuiz && _recommendations.isEmpty)
                      ? _buildQuizPromptState()
                      : displayedPets.isEmpty
                          ? _buildNoResultsState()
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                              physics: const AlwaysScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizPromptState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 38,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Discover Your Compatible Pets',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Our Machine Learning engine matches pets based on your living space, schedule, household, and personality.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openQuiz,
                icon: const Icon(Icons.quiz_outlined, size: 18),
                label: Text(
                  'Take Compatibility Assessment',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tune_rounded, size: 48, color: AppTheme.textSecondary),
          const SizedBox(height: 14),
          Text(
            'No matching pets found',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try switching categories or refining your assessment preferences.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _openQuiz,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Update Preferences',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
