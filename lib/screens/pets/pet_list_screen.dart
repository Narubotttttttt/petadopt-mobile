import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/ai_recommendation_hero.dart';

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
    String _userName = 'Adopter';
  String? _userAvatar;

  @override
  void initState() {
    super.initState();
    if (widget.initialLifestyle != null && widget.initialLifestyle!.isNotEmpty) {
      _activeLifestyleFilter = widget.initialLifestyle!;
    }
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
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
    try {
      // Pre-warm recommendation engine and user preferences
      await ApiService.getSavedPreferences();
      await ApiService.getRecommendations();


    } catch (_) {
    }
  }





  Future<void> _openQuiz() async {
    final result = await Navigator.pushNamed(context, '/match-quiz');
    if (result == true || mounted) {
      _fetchRecommendations();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  isCompact: false,
                  onSearchChanged: (_) {},
                  onSearchSubmitted: (_) => _openQuiz(),
                  onQuizPressed: _openQuiz,
                  onFilterSelected: (filter) {
                    setState(() {
                      _activeLifestyleFilter = filter;
                    });
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}
