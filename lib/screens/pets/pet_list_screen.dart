import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/ai_recommendation_hero.dart';
import 'package:mobile_petadopt/widgets/pet_card.dart';

class PetListScreen extends StatefulWidget {
  final String? initialSearch;
  final String? initialLifestyle;
  final int entranceTrigger;

  const PetListScreen({
    super.key,
    this.initialSearch,
    this.initialLifestyle,
    this.entranceTrigger = 0,
  });

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  final _searchController = TextEditingController();
  String _activeLifestyleFilter = 'none';
  String _searchQuery = '';
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  bool _hasTakenQuiz = false;
  String _userName = 'Adopter';
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    if (widget.initialLifestyle != null && widget.initialLifestyle!.isNotEmpty) {
      _activeLifestyleFilter = widget.initialLifestyle!;
    }
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchQuery = widget.initialSearch!;
      _searchController.text = widget.initialSearch!;
    }
    _loadUser();
    _fetchRecommendations();
  }

  @override
  void didUpdateWidget(PetListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool shouldUpdate = false;
    if (widget.initialLifestyle != null && widget.initialLifestyle != oldWidget.initialLifestyle) {
      _activeLifestyleFilter = widget.initialLifestyle!;
      shouldUpdate = true;
    }
    if (widget.initialSearch != null && widget.initialSearch != oldWidget.initialSearch) {
      _searchQuery = widget.initialSearch!;
      _searchController.text = widget.initialSearch!;
      shouldUpdate = true;
    }
    if (shouldUpdate && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await ApiService.getUser();
      if (mounted && user != null && user['name'] != null) {
        final rawName = (user['name'] as String).trim();
        final firstName = rawName.isNotEmpty ? rawName.split(RegExp(r'\s+')).first : 'Adopter';
        setState(() {
          _userName = firstName;
        });
      }
      final profile = await ApiService.getProfile();
      if (mounted && profile != null && profile['avatar'] != null) {
        final rawAvatar = profile['avatar'].toString().trim();
        if (rawAvatar.isNotEmpty && rawAvatar != 'null') {
          setState(() {
            _userAvatar = ApiService.normalizeImageUrl(rawAvatar);
          });
        }
      }
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getDateSubtitle() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Today • ${now.day} ${months[now.month - 1]}';
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
      // 1. Lifestyle filter
      if (_activeLifestyleFilter != 'none' && _activeLifestyleFilter.isNotEmpty) {
        final name = (pet['name'] ?? '').toString().toLowerCase();
        final breed = (pet['breed'] ?? '').toString().toLowerCase();
        final desc = (pet['description'] ?? '').toString().toLowerCase();
        final type = (pet['type'] ?? '').toString().toLowerCase();
        final temperaments = (pet['temperaments'] is List
                ? (pet['temperaments'] as List).join(' ')
                : (pet['temperaments'] ?? '').toString())
            .toLowerCase();
        final matchReasons = (pet['match_reasons'] is List
                ? (pet['match_reasons'] as List).join(' ')
                : (pet['match_reasons'] ?? '').toString())
            .toLowerCase();
        final allText = '$name $breed $desc $type $temperaments $matchReasons';

        if (_activeLifestyleFilter == 'apartment') {
          final isApartmentFriendly = type == 'cat' ||
              allText.contains('apartment') ||
              allText.contains('calm') ||
              allText.contains('quiet') ||
              allText.contains('gentle') ||
              allText.contains('indoor') ||
              allText.contains('small') ||
              allText.contains('low energy') ||
              allText.contains('relaxed');
          if (!isApartmentFriendly) return false;
        } else if (_activeLifestyleFilter == 'active') {
          final isActive = allText.contains('active') ||
              allText.contains('playful') ||
              allText.contains('energetic') ||
              allText.contains('curious') ||
              allText.contains('outdoor') ||
              allText.contains('lively') ||
              allText.contains('high energy') ||
              allText.contains('running');
          if (!isActive) return false;
        } else if (_activeLifestyleFilter == 'family') {
          final isFamily = allText.contains('family') ||
              allText.contains('gentle') ||
              allText.contains('friendly') ||
              allText.contains('kid') ||
              allText.contains('children') ||
              allText.contains('affectionate') ||
              allText.contains('social') ||
              allText.contains('loving') ||
              allText.contains('sweet');
          if (!isFamily) return false;
        }
      }

      // 3. Keyword / Prompt search
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final name = (pet['name'] ?? '').toString().toLowerCase();
        final breed = (pet['breed'] ?? '').toString().toLowerCase();
        final color = (pet['color'] ?? '').toString().toLowerCase();
        final type = (pet['type'] ?? '').toString().toLowerCase();
        final desc = (pet['description'] ?? '').toString().toLowerCase();
        final idStr = (pet['id'] ?? '').toString();
        final temperaments = (pet['temperaments'] is List
                ? (pet['temperaments'] as List).join(' ')
                : (pet['temperaments'] ?? '').toString())
            .toLowerCase();
        final matchReasons = (pet['match_reasons'] is List
                ? (pet['match_reasons'] as List).join(' ')
                : (pet['match_reasons'] ?? '').toString())
            .toLowerCase();

        final matchesName = name.contains(q);
        final matchesBreed = breed.contains(q);
        final matchesColor = color.contains(q);
        final matchesType = type.contains(q);
        final matchesDesc = desc.contains(q);
        final matchesTemp = temperaments.contains(q);
        final matchesReason = matchReasons.contains(q);
        final matchesId = idStr == q || q == 'pet no. $idStr' || q == 'pet $idStr';

        if (!matchesName &&
            !matchesBreed &&
            !matchesColor &&
            !matchesType &&
            !matchesDesc &&
            !matchesTemp &&
            !matchesReason &&
            !matchesId) {
          return false;
        }
      }

      return true;
    }).toList();
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: Navigator.canPop(context) ? 4 : 16,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
                color: const Color(0xFFE0F2FE),
              ),
              child: ClipOval(
                child: _userAvatar != null && _userAvatar!.isNotEmpty
                    ? Image.network(
                        _userAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: AppTheme.primary,
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_getGreeting()}, $_userName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    _getDateSubtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ActionChip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: const Icon(Icons.tune_rounded, size: 14, color: AppTheme.primaryDark),
              label: Text(
                'Match Quiz',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark,
                ),
              ),
              backgroundColor: AppTheme.primaryLight,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onPressed: _openQuiz,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRecommendations,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // AI Recommendation Hero Section with Staggered Reveal Animation
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                child: AiRecommendationHero(
                  key: ValueKey('ai_hero_${widget.entranceTrigger}'),
                  entranceTrigger: widget.entranceTrigger,
                  searchController: _searchController,
                  activeLifestyleFilter: _activeLifestyleFilter,
                  isCompact: _hasTakenQuiz || displayedPets.isNotEmpty,
                  onSearchChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                  onSearchSubmitted: (val) {
                    setState(() => _searchQuery = val);
                  },
                  onQuizPressed: _openQuiz,
                  onFilterSelected: (filter) {
                    setState(() {
                      _activeLifestyleFilter = filter;
                    });
                  },
                ),
              ),
            ),

            // Compatible Companions Header & Count
            if (!_isLoading && displayedPets.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _activeLifestyleFilter != 'none'
                            ? '${_activeLifestyleFilter[0].toUpperCase()}${_activeLifestyleFilter.substring(1)} Matches'
                            : 'Compatible Companions',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${displayedPets.length} ${displayedPets.length == 1 ? "match" : "matches"}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Content Area
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
              )
            else if (!_hasTakenQuiz && _recommendations.isEmpty)
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              )
            else if (displayedPets.isEmpty)
              SliverToBoxAdapter(
                child: _buildNoResultsState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
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
                    childCount: displayedPets.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 28,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No Matching Companions',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try adjusting your search terms or clearing your lifestyle filters.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _activeLifestyleFilter = 'none';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: Text(
                'Reset Filters',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
