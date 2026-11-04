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

  static Future<void> show({
    required BuildContext context,
    required List<Map<String, dynamic>> pets,
    Map<String, dynamic>? comparativeAnalysis,
    required Function(List<Map<String, dynamic>> selectedPets) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PetComparisonSheet(
        pets: pets,
        comparativeAnalysis: comparativeAnalysis,
        onApply: onApply,
      ),
    );
  }

  @override
  State<PetComparisonSheet> createState() => _PetComparisonSheetState();
}

class _PetComparisonSheetState extends State<PetComparisonSheet> {
  final Set<String> _selectedPetIds = {};

  @override
  void initState() {
    super.initState();
    // Pre-select the top match by default
    if (widget.pets.isNotEmpty) {
      final topId = (widget.pets[0]['pet_id'] ?? widget.pets[0]['id'])?.toString();
      if (topId != null) {
        _selectedPetIds.add(topId);
      }
    }
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
    final comp = widget.comparativeAnalysis;
    final summary = comp?['summary']?.toString() ??
        'Our Scikit-Learn Random Forest recommendation model evaluated these candidates based on your lifestyle profile, space capacity, and routine.';
    final verdict = comp?['verdict']?.toString();

    final selectedList = widget.pets.where((p) {
      final pid = (p['pet_id'] ?? p['id'])?.toString();
      return pid != null && _selectedPetIds.contains(pid);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle and header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Companion Comparison',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Side-by-side match breakdown powered by Gemini AI',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: Colors.grey.shade600,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Comparison Instructions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Side-by-Side Comparison',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Select up to 3 to apply',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Side-by-side cards / table (Displayed at the top)
                  _buildComparisonTable(context),

                  const SizedBox(height: 22),

                  // 3. Gemini AI Synthesis Card (Positioned directly at the bottom of the cards)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF0FDFA), // Soft teal
                          Color(0xFFF8FAFC), // Crisp slate
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF99F6E4), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
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
                                  Text(
                                    'GEMINI AI SYNTHESIS',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                'Random Forest ML',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          summary,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            height: 1.5,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        if (verdict != null && verdict.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
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
                                        TextSpan(text: verdict),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      selectedList.length > 1
                          ? 'Apply for ${selectedList.length} Pets'
                          : 'Apply for Adoption',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildComparisonTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.pets.map((pet) {
          final petId = (pet['pet_id'] ?? pet['id'])?.toString() ?? '';
          final isSelected = _selectedPetIds.contains(petId);
          final rawScore = pet['match_percentage'] ?? pet['compatibility_score'] ?? 80;
          final score = (rawScore is num) ? rawScore.toStringAsFixed(1) : rawScore.toString();
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
            width: 220,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0FDFA) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade300,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF0D9488).withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _togglePetSelection(petId),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header: Match badge + Selection toggle
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFCCFBF1).withValues(alpha: 0.35) : Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$score% Match',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _togglePetSelection(petId),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isSelected ? 'Selected' : 'Select',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                    color: isSelected ? const Color(0xFF0D9488) : Colors.grey.shade400,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, st) => Container(
                                    width: 72,
                                    height: 72,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.pets, color: Colors.grey, size: 28),
                                  ),
                                )
                              : Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.pets, color: Colors.grey, size: 28),
                                ),
                        ),
                        const SizedBox(height: 8),
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

                  // Trait matrix list
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildTraitRow('Living Space', space, Icons.home_outlined),
                        const Divider(height: 14),
                        _buildTraitRow('Energy Level', energy, Icons.bolt_outlined),
                        const Divider(height: 14),
                        _buildTraitRow('Alone Tolerance', alone, Icons.access_time_outlined),
                        const Divider(height: 14),
                        _buildTraitRow('Social Synergy', social, Icons.groups_outlined),
                        const Divider(height: 14),
                        _buildTraitRow('Care & Grooming', grooming, Icons.spa_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTraitRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF0D9488)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
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
