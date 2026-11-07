import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_config.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

class PetComparisonSheet extends StatefulWidget {
  final List<Map<String, dynamic>> pets;
  final Map<String, dynamic>? comparativeAnalysis;
  final Function(List<Map<String, dynamic>> selectedPets) onApply;

  const PetComparisonSheet({
    super.key,
    required this.pets,
    this.comparativeAnalysis,
    required this.onApply,
  });

  static String cleanBracketText(String text) {
    if (text.isEmpty) return text;
    var result = text
        .replaceAll(RegExp(r'Puspin\s*\((?:Mixed|Mix)\s*Breed\)\s*Cat', caseSensitive: false), 'Puspin Cat')
        .replaceAll(RegExp(r'Aspin\s*\((?:Mixed|Mix)\s*Breed\)\s*Dog', caseSensitive: false), 'Aspin Dog')
        .replaceAll(RegExp(r'Puspin\s*\((?:Mixed|Mix)\s*Breed\)', caseSensitive: false), 'Puspin')
        .replaceAll(RegExp(r'Aspin\s*\((?:Mixed|Mix)\s*Breed\)', caseSensitive: false), 'Aspin');

    result = result.replaceAllMapped(
      RegExp(r'\(([^()]*?)\s*\((?:Mixed|Mix)\s*Breed\)\s*([^()]*?)\)', caseSensitive: false),
      (m) => '(${m[1]} ${m[2]})',
    );
    result = result.replaceAllMapped(
      RegExp(r'\(\s*\(([^()]+)\)\s*\)'),
      (m) => '(${m[1]})',
    );

    return result
        .replaceAll(RegExp(r'\(\s+'), '(')
        .replaceAll(RegExp(r'\s+\)'), ')')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  static Future<void> show({
    required BuildContext context,
    required List<Map<String, dynamic>> pets,
    Map<String, dynamic>? comparativeAnalysis,
    required Function(List<Map<String, dynamic>> selectedPets) onApply,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PetComparisonSheet(
          pets: pets,
          comparativeAnalysis: comparativeAnalysis,
          onApply: onApply,
        ),
      ),
    );
  }

  @override
  State<PetComparisonSheet> createState() => _PetComparisonSheetState();
}

class _PetComparisonSheetState extends State<PetComparisonSheet> {
  final Set<String> _selectedPetIds = {};
  final ScrollController _scrollController = ScrollController();
  late final PageController _traitCardPageController;
  int _currentTraitCardIndex = 0;

  Timer? _cursorBlinkTimer;
  bool _cursorVisible = true;

  String _fullSummary = '';
  String _fullVerdict = '';

  List<String> _summaryWords = [];
  int _summaryWordIndex = 0;

  List<String> _verdictWords = [];
  int _verdictWordIndex = 0;

  String _displayedSummary = '';
  String _displayedVerdict = '';

  bool _isThinking = true;
  String _thinkingStatusText = '';
  final Random _random = Random();

  bool _isTypingSummary = false;
  bool _isTypingVerdict = false;
  bool _isAnalysisComplete = false;
  bool _showVerdict = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _traitCardPageController = PageController(
      viewportFraction: 0.84,
      initialPage: 0,
    );

    // Pre-select the top match by default
    if (widget.pets.isNotEmpty) {
      final topId = (widget.pets[0]['pet_id'] ?? widget.pets[0]['id'])?.toString();
      if (topId != null) {
        _selectedPetIds.add(topId);
      }
    }

    final count = widget.pets.length;
    _thinkingStatusText = count > 2
        ? 'Analyzing $count candidate profiles'
        : (count == 2 ? 'Comparing 2 companion profiles' : 'Analyzing companion profile');

    _initializeAgentTyping();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cursorBlinkTimer?.cancel();
    _traitCardPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAgentTyping() {
    final comp = widget.comparativeAnalysis;
    _fullSummary = PetComparisonSheet.cleanBracketText(comp?['summary']?.toString() ??
        'Our Scikit-Learn Random Forest recommendation model evaluated these candidates based on your lifestyle profile, space capacity, and routine.');
    _fullVerdict = PetComparisonSheet.cleanBracketText(comp?['verdict']?.toString() ?? '');

    _summaryWords = _fullSummary.split(' ').where((w) => w.isNotEmpty).toList();
    _verdictWords = _fullVerdict.split(' ').where((w) => w.isNotEmpty).toList();

    _cursorBlinkTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (mounted && !_isDisposed) {
        setState(() {
          _cursorVisible = !_cursorVisible;
        });
      }
    });

    _runDynamicThinkingSequence(widget.pets.length);
  }

  Future<void> _runDynamicThinkingSequence(int petCount) async {
    if (petCount <= 1) {
      if (!mounted || _isDisposed || _isAnalysisComplete) return;
      setState(() {
        _thinkingStatusText = 'Analyzing companion profile';
      });
      final delay = 900 + _random.nextInt(300);
      await Future.delayed(Duration(milliseconds: delay));
    } else if (petCount == 2) {
      // 2 pets: 2 realistic cognitive evaluation stages (~2.2s - 2.6s total)
      if (!mounted || _isDisposed || _isAnalysisComplete) return;
      setState(() {
        _thinkingStatusText = 'Comparing 2 companion profiles';
      });
      final stage1 = 1100 + _random.nextInt(250);
      await Future.delayed(Duration(milliseconds: stage1));

      if (!mounted || _isDisposed || _isAnalysisComplete) return;
      setState(() {
        _thinkingStatusText = 'Evaluating lifestyle & routine synergy';
      });
      final stage2 = 1100 + _random.nextInt(250);
      await Future.delayed(Duration(milliseconds: stage2));
    } else {
      // 3 or more pets: 3 comprehensive comparative stages (~3.3s - 3.8s total)
      if (!mounted || _isDisposed || _isAnalysisComplete) return;
      setState(() {
        _thinkingStatusText = 'Analyzing $petCount candidate profiles';
      });
      final stage1 = 1100 + _random.nextInt(200);
      await Future.delayed(Duration(milliseconds: stage1));

      if (!mounted || _isDisposed || _isAnalysisComplete) return;
      setState(() {
        _thinkingStatusText = 'Cross-evaluating living space & energy synergy';
      });
      final stage2 = 1200 + _random.nextInt(250);
      await Future.delayed(Duration(milliseconds: stage2));

      if (!mounted || _isDisposed || _isAnalysisComplete) return;
      setState(() {
        _thinkingStatusText = 'Synthesizing comparative trade-offs';
      });
      final stage3 = 1000 + _random.nextInt(200);
      await Future.delayed(Duration(milliseconds: stage3));
    }

    if (!mounted || _isDisposed || _isAnalysisComplete) return;
    _startTypingSummary();
  }

  void _startTypingSummary() {
    if (!mounted || _isDisposed || _isAnalysisComplete) return;
    setState(() {
      _isThinking = false;
      _isTypingSummary = true;
      _displayedSummary = '';
      _summaryWordIndex = 0;
    });

    _streamSummaryWord();
  }

  Future<void> _streamSummaryWord() async {
    if (!mounted || _isDisposed || _isAnalysisComplete) return;

    if (_summaryWordIndex >= _summaryWords.length) {
      if (!mounted) return;
      setState(() {
        _isTypingSummary = false;
        _displayedSummary = _fullSummary;
      });

      if (_fullVerdict.isNotEmpty) {
        // Natural deliberate pause before revealing conclusion verdict
        await Future.delayed(Duration(milliseconds: 380 + _random.nextInt(120)));
        if (!mounted || _isDisposed || _isAnalysisComplete) return;
        _startTypingVerdict();
      } else {
        _finishTyping();
      }
      return;
    }

    final currentWord = _summaryWords[_summaryWordIndex];
    _summaryWordIndex++;
    final currentText = _summaryWords.take(_summaryWordIndex).join(' ');

    if (!mounted || _isDisposed) return;
    setState(() {
      _displayedSummary = currentText;
    });

    // Natural reading cadence per word with subtle human/LLM variance
    int delayMs = 52 + _random.nextInt(26);

    // Modulation based on word length
    if (currentWord.length > 8) {
      delayMs += 16;
    } else if (currentWord.length <= 3) {
      delayMs = (delayMs - 12).clamp(30, 90);
    }

    // Punctuation cadence:
    if (currentWord.endsWith('.') || currentWord.endsWith('!') || currentWord.endsWith('?')) {
      // Natural breath at end of sentence
      delayMs = 340 + _random.nextInt(80);
    } else if (currentWord.endsWith(',') ||
        currentWord.endsWith(';') ||
        currentWord.endsWith(':') ||
        currentWord.endsWith('-')) {
      // Clause pause
      delayMs = 160 + _random.nextInt(50);
    }

    await Future.delayed(Duration(milliseconds: delayMs));
    _streamSummaryWord();
  }

  void _startTypingVerdict() {
    if (!mounted || _isDisposed || _isAnalysisComplete) return;
    setState(() {
      _showVerdict = true;
      _isTypingVerdict = true;
      _displayedVerdict = '';
      _verdictWordIndex = 0;
    });

    _streamVerdictWord();
  }

  Future<void> _streamVerdictWord() async {
    if (!mounted || _isDisposed || _isAnalysisComplete) return;

    if (_verdictWordIndex >= _verdictWords.length) {
      _finishTyping();
      return;
    }

    final currentWord = _verdictWords[_verdictWordIndex];
    _verdictWordIndex++;
    final currentText = _verdictWords.take(_verdictWordIndex).join(' ');

    if (!mounted || _isDisposed) return;
    setState(() {
      _displayedVerdict = currentText;
    });

    int delayMs = 54 + _random.nextInt(26);
    if (currentWord.length > 8) {
      delayMs += 16;
    } else if (currentWord.length <= 3) {
      delayMs = (delayMs - 12).clamp(30, 90);
    }

    if (currentWord.endsWith('.') || currentWord.endsWith('!') || currentWord.endsWith('?')) {
      delayMs = 340 + _random.nextInt(80);
    } else if (currentWord.endsWith(',') ||
        currentWord.endsWith(';') ||
        currentWord.endsWith(':')) {
      delayMs = 160 + _random.nextInt(50);
    }

    await Future.delayed(Duration(milliseconds: delayMs));
    _streamVerdictWord();
  }

  void _finishTyping() {
    _cursorBlinkTimer?.cancel();
    if (mounted && !_isDisposed) {
      setState(() {
        _isThinking = false;
        _isTypingSummary = false;
        _isTypingVerdict = false;
        _isAnalysisComplete = true;
        _displayedSummary = _fullSummary;
        _displayedVerdict = _fullVerdict;
        if (_fullVerdict.isNotEmpty) {
          _showVerdict = true;
        }
      });
    }
  }

  void _skipTyping() {
    if (_isAnalysisComplete) return;
    _finishTyping();
  }

  void _togglePetSelection(String petId) {
    setState(() {
      if (_selectedPetIds.contains(petId)) {
        if (_selectedPetIds.length > 1) {
          _selectedPetIds.remove(petId);
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'At least one companion must remain selected for adoption application.',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              backgroundColor: AppTheme.warningColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (_selectedPetIds.length >= 3) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You can select up to 3 companions to apply for simultaneously.',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              backgroundColor: AppTheme.warningColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          _selectedPetIds.add(petId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedList = widget.pets.where((p) {
      final pid = (p['pet_id'] ?? p['id'])?.toString();
      return pid != null && _selectedPetIds.contains(pid);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Companion Comparison',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Side-by-side match breakdown',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Pet Pictures Showcase (Top) - fits 2 or 3 pets with zero scrolling
                  _buildPetPicturesShowcase(context),

                  const SizedBox(height: 16),

                  // 2. Gemini AI Synthesis Card (Directly Below the Pictures)
                  _buildGeminiSynthesisCard(),

                  // 3. Detailed Trait Comparison Carousel (Smoothly revealed once Gemini completes comparison)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    child: _isAnalysisComplete
                        ? AnimatedOpacity(
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            opacity: _isAnalysisComplete ? 1.0 : 0.0,
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              offset: _isAnalysisComplete ? Offset.zero : const Offset(0, 0.05),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  // Detailed Trait Comparison Header
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Detailed Trait Comparison',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.swipe_outlined, size: 12, color: AppTheme.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Swipe to compare',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Comparison Cards Matrix (Detailed trait breakdown)
                                  _buildComparisonCards(context),

                                  const SizedBox(height: 14),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${selectedList.length} of ${widget.pets.length} Selected',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedList.length > 1
                              ? 'Unified application for ${selectedList.length} pets'
                              : 'Single companion application',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton(
                    onPressed: selectedList.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context);
                            widget.onApply(selectedList);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedList.length > 1
                              ? 'Apply for ${selectedList.length} Pets'
                              : 'Apply for Adoption',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiSynthesisCard() {
    return GestureDetector(
      onTap: _skipTyping,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFF0FDFA), // Soft luminous teal
              Color(0xFFFFFFFF), // Crisp pure white
              Color(0xFFF8FAFC), // Slate
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isAnalysisComplete ? const Color(0xFF99F6E4) : const Color(0xFF0D9488),
            width: _isAnalysisComplete ? 1.2 : 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withValues(alpha: _isAnalysisComplete ? 0.04 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Unified Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.psychology_outlined, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'SYNTHESIS',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Live Agent Status Badge
                if (!_isAnalysisComplete)
                  Flexible(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _isThinking ? 'Evaluating' : 'Synthesizing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F766E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Flexible(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Complete',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Dynamic Multi-Stage Thinking State (Proportional to Pet Count)
            if (_isThinking)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                        child: Row(
                          key: ValueKey<String>(_thinkingStatusText),
                          children: [
                            Flexible(
                              child: Text(
                                _thinkingStatusText,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F766E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const _GeminiBouncingDots(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Streamed Summary with Blinking Agent Cursor
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _displayedSummary,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.5,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    if (_isTypingSummary)
                      TextSpan(
                        text: ' ▌',
                        style: TextStyle(
                          color: _cursorVisible ? const Color(0xFF0D9488) : Colors.transparent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),

            // Streamed Verdict with Verified Badge
            if (_showVerdict && _fullVerdict.isNotEmpty) ...[
              const SizedBox(height: 12),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 1.0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCCFBF1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 16,
                        color: Color(0xFF0D9488),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: const Color(0xFF0F766E),
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Recommendation Verdict: ',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: _displayedVerdict),
                              if (_isTypingVerdict)
                                TextSpan(
                                  text: ' ▌',
                                  style: TextStyle(
                                    color: _cursorVisible ? const Color(0xFF0D9488) : Colors.transparent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
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

            if (!_isAnalysisComplete) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to reveal full analysis',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildPetPicturesShowcase(BuildContext context) {
    final petCount = widget.pets.length;
    final isThreeWay = petCount >= 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFCCFBF1),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row inside the card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'COMPANION CANDIDATES',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFF99F6E4)),
                    ),
                    child: Text(
                      isThreeWay ? '3 Candidates' : '2 Candidates',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pet pictures row
          if (isThreeWay)
            _buildThreePetRow()
          else
            _buildTwoPetRow(),
        ],
      ),
    );
  }

  Widget _buildTwoPetRow() {
    final pet1 = widget.pets[0];
    final pet2 = widget.pets.length > 1 ? widget.pets[1] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildPetPictureItem(
            pet: pet1,
            rank: 1,
            isCompact: false,
          ),
        ),
        // Gentle synergy connector between the 2 pets (No "VS" text)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF99F6E4), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  color: Color(0xFF0D9488),
                  size: 18,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Synergy',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D9488),
                ),
              ),
            ],
          ),
        ),
        if (pet2 != null)
          Expanded(
            child: _buildPetPictureItem(
              pet: pet2,
              rank: 2,
              isCompact: false,
            ),
          ),
      ],
    );
  }

  Widget _buildThreePetRow() {
    final petCount = widget.pets.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < 3 && i < petCount; i++) ...[
          if (i > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              width: 1,
              height: 52,
              color: Colors.grey.shade200,
            ),
          Expanded(
            child: _buildPetPictureItem(
              pet: widget.pets[i],
              rank: i + 1,
              isCompact: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPetPictureItem({
    required Map<String, dynamic> pet,
    required int rank,
    required bool isCompact,
  }) {
    final petId = (pet['pet_id'] ?? pet['id'])?.toString() ?? '';
    final isSelected = _selectedPetIds.contains(petId);
    final rawScore = pet['match_percentage'] ?? pet['compatibility_score'] ?? 80;
    final score = (rawScore is num) ? rawScore.toStringAsFixed(1) : rawScore.toString();
    final isTopMatch = rank == 1;
    final imageUrl = ApiConfig.normalizeImageUrl(pet['photo_url'] ?? pet['image'] ?? '');
    final name = pet['name']?.toString() ?? 'Companion';
    final breed = pet['breed']?.toString() ?? 'Mixed';
    final species = (pet['type']?.toString() ?? 'Pet').toUpperCase();

    final double photoSize = isCompact ? 58.0 : 70.0;

    return InkWell(
      onTap: () {
        _togglePetSelection(petId);
        if (_traitCardPageController.hasClients) {
          _traitCardPageController.animateToPage(
            rank - 1,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pet Photo Stack with Selection Check Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(photoSize / 2),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0D9488)
                          : isTopMatch
                              ? const Color(0xFF14B8A6)
                              : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF0D9488).withValues(alpha: 0.22)
                            : isTopMatch
                                ? const Color(0xFF14B8A6).withValues(alpha: 0.15)
                                : Colors.black.withValues(alpha: 0.04),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'pet_compare_hero_$petId',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular((photoSize - 5) / 2),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: photoSize,
                              height: photoSize,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, st) => Container(
                                width: photoSize,
                                height: photoSize,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.pets, color: Colors.grey, size: 24),
                              ),
                            )
                          : Container(
                              width: photoSize,
                              height: photoSize,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.pets, color: Colors.grey, size: 24),
                            ),
                    ),
                  ),
                ),

                // Top Match #1 Pill Badge
                if (isTopMatch)
                  Positioned(
                    bottom: -5,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, size: 9.5, color: Color(0xFFFDE047)),
                            const SizedBox(width: 2),
                            Text(
                              isCompact ? '#1 Pick' : '#1 Top Pick',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Selection check indicator in top-right corner
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0D9488) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade400,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTopMatch ? 9 : 6),

            // Pet Name
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isCompact ? 11 : 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),

            // Breed & Type
            Text(
              '$species • $breed',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isCompact ? 8.5 : 9.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 3),

            // Score Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isTopMatch
                    ? const Color(0xFFCCFBF1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$score% Match',
                style: GoogleFonts.poppins(
                  fontSize: isCompact ? 9 : 10,
                  fontWeight: FontWeight.w700,
                  color: isTopMatch
                      ? const Color(0xFF0F766E)
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCards(BuildContext context) {
    final petCount = widget.pets.length;

    return Column(
      children: [
        SizedBox(
          height: 415,
          child: PageView.builder(
            controller: _traitCardPageController,
            physics: const BouncingScrollPhysics(),
            itemCount: petCount,
            onPageChanged: (idx) {
              setState(() {
                _currentTraitCardIndex = idx;
              });
            },
            itemBuilder: (context, index) {
              final pet = widget.pets[index];
              return AnimatedBuilder(
                animation: _traitCardPageController,
                builder: (context, child) {
                  double scale = 1.0;
                  double opacity = 1.0;
                  if (_traitCardPageController.position.haveDimensions) {
                    final page = _traitCardPageController.page ?? _traitCardPageController.initialPage.toDouble();
                    final diff = (index - page).abs();
                    scale = (1.0 - (diff * 0.08)).clamp(0.92, 1.0);
                    opacity = (1.0 - (diff * 0.22)).clamp(0.78, 1.0);
                  } else {
                    scale = index == _currentTraitCardIndex ? 1.0 : 0.92;
                    opacity = index == _currentTraitCardIndex ? 1.0 : 0.78;
                  }

                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: child,
                      ),
                    ),
                  );
                },
                child: _buildSingleTraitCard(index, pet),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Carousel Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < petCount; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentTraitCardIndex ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentTraitCardIndex
                      ? const Color(0xFF0D9488)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSingleTraitCard(int index, Map<String, dynamic> pet) {
    final petId = (pet['pet_id'] ?? pet['id'])?.toString() ?? '';
    final isSelected = _selectedPetIds.contains(petId);
    final rawScore = pet['match_percentage'] ?? pet['compatibility_score'] ?? 80;
    final score = (rawScore is num) ? rawScore.toStringAsFixed(1) : rawScore.toString();
    final isTopMatch = index == 0;
    final traits = (pet['comparison_traits'] as Map<String, dynamic>?) ?? {};

    final energy = traits['energy_level']?.toString() ?? 'Moderate';
    final space = traits['space_fit']?.toString() ?? 'Apartment Friendly';
    final alone = traits['alone_tolerance']?.toString() ?? 'Moderate';
    final social = traits['social_compatibility']?.toString() ?? 'Friendly with pets';
    final grooming = traits['grooming_care']?.toString() ?? 'Low maintenance';

    final imageUrl = ApiConfig.normalizeImageUrl(pet['photo_url'] ?? pet['image'] ?? '');
    final name = pet['name']?.toString() ?? 'Companion';
    final breed = pet['breed']?.toString() ?? 'Mixed Breed';
    final species = (pet['type']?.toString() ?? 'Dog').toUpperCase();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0FDFA) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF0D9488)
              : isTopMatch
                  ? const Color(0xFF99F6E4)
                  : Colors.grey.shade300,
          width: isSelected ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF0D9488).withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Match badge + Candidate counter (NO select button)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFCCFBF1).withValues(alpha: 0.35)
                  : isTopMatch
                      ? const Color(0xFFF0FDFA)
                      : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    gradient: isTopMatch
                        ? const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isTopMatch ? null : const Color(0xFF0D9488),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: isTopMatch
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isTopMatch) ...[
                        const Icon(Icons.stars_rounded, size: 12, color: Color(0xFFFDE047)),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        isTopMatch ? 'Top Match $score%' : '$score% Match',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300, width: 0.8),
                  ),
                  child: Text(
                    'Candidate ${index + 1} of ${widget.pets.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pet Image & Identity
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 66,
                            height: 66,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              width: 66,
                              height: 66,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.pets, color: Colors.grey, size: 26),
                            ),
                          )
                        : Container(
                            width: 66,
                            height: 66,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.pets, color: Colors.grey, size: 26),
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '$species • $breed',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trait matrix list
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Column(
              children: [
                _buildTraitRow('Living Space', space, Icons.home_outlined),
                const Divider(height: 7, thickness: 0.8, color: Color(0xFFF1F5F9)),
                _buildTraitRow('Energy Level', energy, Icons.bolt_outlined),
                const Divider(height: 7, thickness: 0.8, color: Color(0xFFF1F5F9)),
                _buildTraitRow('Alone Tolerance', alone, Icons.access_time_outlined),
                const Divider(height: 7, thickness: 0.8, color: Color(0xFFF1F5F9)),
                _buildTraitRow('Social Synergy', social, Icons.groups_outlined),
                const Divider(height: 7, thickness: 0.8, color: Color(0xFFF1F5F9)),
                _buildTraitRow('Care & Grooming', grooming, Icons.spa_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF0D9488)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Animated 3-dot wave movement matching Google Gemini's chat thinking state
class _GeminiBouncingDots extends StatefulWidget {
  const _GeminiBouncingDots();

  @override
  State<_GeminiBouncingDots> createState() => _GeminiBouncingDotsState();
}

class _GeminiBouncingDotsState extends State<_GeminiBouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.18;
            final progress = (_controller.value - delay) % 1.0;
            // Smooth vertical bounce: 0 -> -4.5 -> 0
            final bounce = progress < 0.5
                ? -4.5 * (1.0 - (2.0 * (progress - 0.25).abs()))
                : 0.0;
            final opacity = (progress < 0.5
                ? 0.35 + (0.65 * (1.0 - (2.0 * (progress - 0.25).abs())))
                : 0.35).clamp(0.3, 1.0);

            return Transform.translate(
              offset: Offset(0, bounce),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.2),
                width: 4.5,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
