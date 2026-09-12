import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/screens/adoption/adopted_pet_hub_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

class MyAdoptedPetsScreen extends StatefulWidget {
  const MyAdoptedPetsScreen({super.key});

  @override
  State<MyAdoptedPetsScreen> createState() => _MyAdoptedPetsScreenState();
}

class _MyAdoptedPetsScreenState extends State<MyAdoptedPetsScreen> {
  List<Map<String, dynamic>> _adoptedPets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdoptedPets();
  }

  Future<void> _fetchAdoptedPets() async {
    try {
      final list = await ApiService.getMyApplications();
      final approved = list.where((app) {
        final status = app['status'] as String? ?? '';
        final isSigned = app['is_signed'] == true ||
            (app['signature_url'] != null && app['signature_url'].toString().isNotEmpty);
        return (status == 'approved' || status == 'adopted') && isSigned;
      }).toList();

      if (mounted) {
        setState(() {
          _adoptedPets = approved;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'My Adopted Pets',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _adoptedPets.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchAdoptedPets,
                  color: AppTheme.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _adoptedPets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final pet = _adoptedPets[index];
                      return _buildPetCard(pet);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets_rounded, size: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No Adopted Pets Yet',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When your adoption application is approved by CAWS, your pet health check-in hub will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    final petName = pet['petName'] as String? ?? 'Adopted Pet';
    final petBreed = pet['petBreed'] as String? ?? 'Mixed';
    final petType = pet['petType'] as String? ?? 'Pet';
    final petImage = pet['petImage'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdoptedPetHubScreen(application: pet),
              ),
            ).then((_) => _fetchAdoptedPets());
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    petImage,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 76,
                      height: 76,
                      color: AppTheme.primaryLight,
                      child: const Icon(Icons.pets_rounded, color: AppTheme.primary, size: 30),
                    ),
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
                              petName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8F1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Adopted',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$petBreed • $petType',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.medical_services_outlined, size: 13, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to view Health Hub',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
