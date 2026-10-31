import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/screens/adoption/pet_medical_card_screen.dart';
import 'package:mobile_petadopt/screens/adoption/submit_health_checkin_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

class MyAdoptedPetsScreen extends StatefulWidget {
  final bool isMonthlyReportMode;
  final bool isHealthCardMode;
  final List<Map<String, dynamic>>? initialPets;

  const MyAdoptedPetsScreen({
    super.key,
    this.isMonthlyReportMode = false,
    this.isHealthCardMode = false,
    this.initialPets,
  });

  @override
  State<MyAdoptedPetsScreen> createState() => _MyAdoptedPetsScreenState();
}

class _MyAdoptedPetsScreenState extends State<MyAdoptedPetsScreen> {
  List<Map<String, dynamic>> _adoptedPets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialPets != null && widget.initialPets!.isNotEmpty) {
      _adoptedPets = List<Map<String, dynamic>>.from(widget.initialPets!);
      _isLoading = false;
    }
    _fetchAdoptedPets();
  }

  Future<void> _fetchAdoptedPets() async {
    try {
      final list = await ApiService.getMyApplications();
      final approved = list.where((app) {
        final status = (app['status'] as String? ?? '').toLowerCase();
        final isFinalized = app['is_finalized'] == true ||
            app['isFinalized'] == true ||
            app['contract_unlocked'] == true;
        return (status == 'approved' || status == 'adopted') && isFinalized;
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
          widget.isMonthlyReportMode
              ? 'Monthly Welfare Reports'
              : widget.isHealthCardMode
                  ? 'Pet Health Cards'
                  : 'My Adopted Pets',
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      if (widget.isMonthlyReportMode) ...[
                        _buildMonthlyReportBanner(),
                        const SizedBox(height: 14),
                      ] else if (widget.isHealthCardMode) ...[
                        _buildHealthCardBanner(),
                        const SizedBox(height: 14),
                      ],
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _adoptedPets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final pet = _adoptedPets[index];
                          return _buildPetCard(pet);
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHealthCardBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Color(0xFF0284C7),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pet Health Cards & History',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0369A1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Select an adopted companion to view their verified health passport, vaccinations, and veterinary care history.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF0C4A6E),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReportBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
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
                  'Monthly Welfare Check-ins',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Select an adopted companion to submit recurring photo updates, pet condition logs, and weight records.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              child: Icon(
                widget.isMonthlyReportMode ? Icons.assignment_turned_in_rounded : Icons.pets_rounded,
                size: 40,
                color: AppTheme.primary,
              ),
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
              widget.isMonthlyReportMode
                  ? 'Monthly health check-in reports unlock once an adoption is finalized and your companion is officially handed over to your care.'
                  : 'When your adoption is completed and verified by CAWS, your pet health check-in hub will appear here.',
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
    final petName = (pet['adoptedPetName'] ?? pet['proposedName'] ?? pet['petName'])?.toString() ?? 'Adopted Pet';
    final shelterId = pet['shelterPetId'] ?? pet['pet_id'] ?? pet['petId'] ?? pet['pet']?['id'];
    final shelterCode = pet['shelterPetCode']?.toString() ?? (shelterId != null ? 'Pet no. $shelterId' : '');
    final petBreed = pet['petBreed'] as String? ?? 'Mixed';
    final petType = pet['petType'] as String? ?? 'Pet';
    final petImage = pet['petImage'] as String? ?? '';
    final appId = (pet['id'] as num?)?.toInt() ?? 0;
    final rawPetStatus = (pet['pet_status'] ??
            pet['status'] ??
            pet['shelter_pet_status'] ??
            pet['pet']?['status'] ??
            pet['pet']?['pet_status'] ??
            pet['health_status'] ??
            pet['life_status'])
        ?.toString()
        .toLowerCase()
        .trim();

    final isDeceased = rawPetStatus == 'deceased' ||
        rawPetStatus == 'in memory' ||
        rawPetStatus == 'in_memory' ||
        rawPetStatus == 'passed away' ||
        rawPetStatus == 'passed_away' ||
        pet['is_deceased'] == true ||
        pet['is_in_memory'] == true ||
        pet['in_memory'] == true ||
        pet['pet']?['is_deceased'] == true ||
        pet['pet']?['is_in_memory'] == true ||
        (pet['health_updates'] is List &&
            (pet['health_updates'] as List).any((u) =>
                u is Map &&
                ((u['health_status']?.toString().toLowerCase().trim() == 'deceased') ||
                    (u['health_status']?.toString().toLowerCase().trim() == 'in memory') ||
                    (u['health_status']?.toString().toLowerCase().trim() == 'passed away'))));

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
          onTap: isDeceased
              ? null
              : () {
                  if (widget.isMonthlyReportMode) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubmitHealthCheckinScreen(
                          applicationId: appId,
                          petName: petName,
                          petImage: petImage,
                          isDeceasedReport: false,
                        ),
                      ),
                    ).then((_) => _fetchAdoptedPets());
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PetMedicalCardScreen(
                          petId: (pet['pet_id'] ?? pet['petId'] ?? pet['pet']?['id'] ?? pet['shelterPetId']) as int? ?? 0,
                          applicationId: appId,
                          petName: petName,
                          petImage: petImage,
                        ),
                      ),
                    ).then((_) => _fetchAdoptedPets());
                  }
                },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: petImage.isNotEmpty
                          ? Image.network(
                              ApiService.normalizeImageUrl(petImage),
                              width: 74,
                              height: 74,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 74,
                                height: 74,
                                color: AppTheme.primaryLight,
                                child: const Icon(Icons.pets_rounded, color: AppTheme.primary, size: 30),
                              ),
                            )
                          : Container(
                              width: 74,
                              height: 74,
                              color: AppTheme.primaryLight,
                              child: const Icon(Icons.pets_rounded, color: AppTheme.primary, size: 30),
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
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: isDeceased
                                      ? const Color(0xFFF1F5F9)
                                      : widget.isMonthlyReportMode
                                          ? const Color(0xFFFDF2F8)
                                          : widget.isHealthCardMode
                                              ? const Color(0xFFE0F2FE)
                                              : const Color(0xFFE8F8F1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDeceased
                                        ? const Color(0xFFE2E8F0)
                                        : widget.isMonthlyReportMode
                                            ? const Color(0xFFFBCFE8)
                                            : widget.isHealthCardMode
                                                ? const Color(0xFFBAE6FD)
                                                : const Color(0xFFA7F3D0),
                                  ),
                                ),
                                child: Text(
                                  isDeceased
                                      ? 'In Memory'
                                      : widget.isMonthlyReportMode
                                          ? 'Monthly Report'
                                          : widget.isHealthCardMode
                                              ? 'Health Card'
                                              : 'Adopted',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDeceased
                                        ? const Color(0xFF475569)
                                        : widget.isMonthlyReportMode
                                            ? const Color(0xFFBE185D)
                                            : widget.isHealthCardMode
                                                ? const Color(0xFF0284C7)
                                                : AppTheme.successColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            shelterCode.isNotEmpty ? '$shelterCode • $petBreed' : '$petBreed • $petType',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDeceased
                                ? 'Check-in obligations respectfully concluded'
                                : widget.isHealthCardMode
                                    ? 'Clinical records, vaccines & treatments'
                                    : 'Recurring photo & health check-ins',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                if (widget.isMonthlyReportMode) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isDeceased
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SubmitHealthCheckinScreen(
                                    applicationId: appId,
                                    petName: petName,
                                    petImage: petImage,
                                    isDeceasedReport: false,
                                  ),
                                ),
                              ).then((_) => _fetchAdoptedPets());
                            },
                      icon: Icon(
                        isDeceased ? Icons.favorite_rounded : Icons.assignment_turned_in_rounded,
                        size: 16,
                        color: isDeceased ? const Color(0xFF94A3B8) : Colors.white,
                      ),
                      label: Text(
                        isDeceased ? 'In Memory' : 'Submit Monthly Report',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: isDeceased ? FontWeight.w600 : FontWeight.w700,
                          color: isDeceased ? const Color(0xFF94A3B8) : Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFF1F5F9),
                        disabledForegroundColor: const Color(0xFF94A3B8),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isDeceased ? const BorderSide(color: Color(0xFFCBD5E1)) : BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ] else if (widget.isHealthCardMode) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PetMedicalCardScreen(
                              petId: (pet['pet_id'] ?? pet['petId'] ?? pet['pet']?['id'] ?? pet['shelterPetId']) as int? ?? 0,
                              applicationId: appId,
                              petName: petName,
                              petImage: petImage,
                            ),
                          ),
                        ).then((_) => _fetchAdoptedPets());
                      },
                      icon: const Icon(Icons.medical_services_rounded, size: 16, color: Colors.white),
                      label: Text(
                        'Health Card History',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PetMedicalCardScreen(
                                  petId: (pet['pet_id'] ?? pet['petId'] ?? pet['pet']?['id'] ?? pet['shelterPetId']) as int? ?? 0,
                                  applicationId: appId,
                                  petName: petName,
                                  petImage: petImage,
                                ),
                              ),
                            ).then((_) => _fetchAdoptedPets());
                          },
                          icon: const Icon(Icons.medical_services_outlined, size: 15, color: AppTheme.primary),
                          label: Text(
                            'Health Card History',
                            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isDeceased
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SubmitHealthCheckinScreen(
                                        applicationId: appId,
                                        petName: petName,
                                        petImage: petImage,
                                      ),
                                    ),
                                  ).then((_) => _fetchAdoptedPets());
                                },
                          icon: Icon(
                            isDeceased ? Icons.favorite_rounded : Icons.assignment_turned_in_rounded,
                            size: 15,
                            color: isDeceased ? const Color(0xFF94A3B8) : Colors.white,
                          ),
                          label: Text(
                            isDeceased ? 'In Memory' : 'Submit Report',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: isDeceased ? FontWeight.w600 : FontWeight.w700,
                              color: isDeceased ? const Color(0xFF94A3B8) : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBE185D),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFF1F5F9),
                            disabledForegroundColor: const Color(0xFF94A3B8),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: isDeceased ? const BorderSide(color: Color(0xFFE2E8F0)) : BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

