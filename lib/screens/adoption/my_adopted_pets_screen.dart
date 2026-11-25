import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/screens/adoption/my_applications_screen.dart';
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
        final isArchived = app['is_archived'] == true || app['isArchived'] == true;
        return (status == 'approved' || status == 'adopted') && !isArchived;
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
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getSurfaceColor(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: AppTheme.getTextPrimary(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isMonthlyReportMode
              ? 'Monthly Welfare Reports'
              : widget.isHealthCardMode
                  ? 'Pet Health Cards'
                  : 'My Adopted Pets',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.getTextPrimary(context),
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
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.4) : const Color(0xFFBAE6FD)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.25) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services_rounded,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
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
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Select an adopted companion to view their verified health passport, vaccinations, and veterinary care history.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0C4A6E),
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
    final isDark = AppTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : AppTheme.primaryLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.primary.withValues(alpha: 0.35) : AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : Colors.white,
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
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Select an adopted companion to submit recurring photo updates, pet condition logs, and weight records.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AppTheme.getTextSecondary(context),
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
    final isDark = AppTheme.isDark(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primaryLight,
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
                color: AppTheme.getTextPrimary(context),
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
                color: AppTheme.getTextSecondary(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    final shelterId = pet['shelterPetId'] ?? pet['pet_id'] ?? pet['petId'] ?? pet['pet']?['id'];
    final shelterCode = pet['shelterPetCode']?.toString() ?? (shelterId != null ? 'Pet no. $shelterId' : 'Pet');
    var petName = (pet['adoptedPetName'] ?? pet['proposedName'] ?? pet['petName'])?.toString() ?? shelterCode;
    if (petName.isEmpty || petName.toLowerCase() == 'adopted pet') {
      petName = shelterCode;
    }
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

    final isFinalized = pet['is_finalized'] == true ||
        pet['isFinalized'] == true ||
        pet['contract_unlocked'] == true;

    final isDark = AppTheme.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.getCardBorder(context)),
        boxShadow: isDark
            ? []
            : [
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
            if (isDeceased) {
              _showMemorialDetails(context, pet);
            } else if (!isFinalized) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyApplicationsScreen(initialFilter: 'approved'),
                ),
              );
            } else if (widget.isMonthlyReportMode) {
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
                                color: isDark ? const Color(0xFF1E293B) : AppTheme.primaryLight,
                                child: const Icon(Icons.pets_rounded, color: AppTheme.primary, size: 30),
                              ),
                            )
                          : Container(
                              width: 74,
                              height: 74,
                              color: isDark ? const Color(0xFF1E293B) : AppTheme.primaryLight,
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
                                    color: AppTheme.getTextPrimary(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: isDeceased
                                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                                      : !isFinalized
                                          ? (isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFEF3C7))
                                          : widget.isMonthlyReportMode
                                              ? (isDark ? const Color(0xFF831843).withValues(alpha: 0.3) : const Color(0xFFFDF2F8))
                                              : widget.isHealthCardMode
                                                  ? (isDark ? const Color(0xFF075985).withValues(alpha: 0.3) : const Color(0xFFE0F2FE))
                                                  : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFE8F8F1)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDeceased
                                        ? (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0))
                                        : !isFinalized
                                            ? (isDark ? const Color(0xFFD97706).withValues(alpha: 0.5) : const Color(0xFFFDE68A))
                                            : widget.isMonthlyReportMode
                                                ? (isDark ? const Color(0xFFBE185D).withValues(alpha: 0.5) : const Color(0xFFFBCFE8))
                                                : widget.isHealthCardMode
                                                    ? (isDark ? const Color(0xFF0284C7).withValues(alpha: 0.5) : const Color(0xFFBAE6FD))
                                                    : (isDark ? const Color(0xFF059669).withValues(alpha: 0.5) : const Color(0xFFA7F3D0)),
                                  ),
                                ),
                                child: Text(
                                  isDeceased
                                      ? 'In Memory'
                                      : !isFinalized
                                          ? 'Awaiting Handover'
                                          : widget.isMonthlyReportMode
                                              ? 'Monthly Report'
                                              : widget.isHealthCardMode
                                                  ? 'Health Card'
                                                  : 'Adopted',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDeceased
                                        ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))
                                        : !isFinalized
                                            ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                                            : widget.isMonthlyReportMode
                                                ? (isDark ? const Color(0xFFF472B6) : const Color(0xFFBE185D))
                                                : widget.isHealthCardMode
                                                    ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                                                    : (isDark ? const Color(0xFF34D399) : AppTheme.successColor),
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
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isDeceased
                                ? 'Memorial record • Dedication honoring companion'
                                : !isFinalized
                                    ? 'Pre-approved • Scheduled for pickup and verification'
                                    : widget.isHealthCardMode
                                        ? 'Clinical records, vaccines & treatments'
                                        : 'Recurring photo & health check-ins',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                if (isFinalized && !isDeceased) ...[
                  _buildKaponStatusCard(pet, isDark),
                ],
                if (isDeceased) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showMemorialDetails(context, pet),
                      icon: const Icon(Icons.favorite_rounded, size: 15, color: Color(0xFF64748B)),
                      label: Text(
                        'In Loving Memory • View Memorial',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else if (!isFinalized) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyApplicationsScreen(initialFilter: 'approved'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.event_note_rounded, size: 15, color: Color(0xFFD97706)),
                      label: Text(
                        'Awaiting Handover • View Schedule',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A)),
                        backgroundColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.15) : const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else if (widget.isMonthlyReportMode) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
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
                      icon: const Icon(Icons.assignment_turned_in_rounded, size: 16, color: Colors.white),
                      label: Text(
                        'Submit Monthly Report',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  _buildReportPassingLink(appId, petName, petImage, isDark),
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
                  _buildReportPassingLink(appId, petName, petImage, isDark),
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
                            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
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
                          icon: const Icon(Icons.assignment_turned_in_rounded, size: 15, color: Colors.white),
                          label: Text(
                            'Submit Report',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBE185D),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _buildReportPassingLink(appId, petName, petImage, isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKaponStatusCard(Map<String, dynamic> pet, bool isDark) {
    final rawStatus = (pet['kapon_status'] ?? '').toString().toLowerCase().trim();
    final isNeutered = pet['is_neutered'] == true || pet['pet']?['is_neutered'] == true;
    final kaponStatus = rawStatus.isNotEmpty
        ? rawStatus
        : (isNeutered ? 'completed' : 'awaiting_schedule');

    if (kaponStatus == 'not_required') {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_outlined, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Neuter / Kapon Status: Already Completed or Not Required',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (kaponStatus == 'completed' || isNeutered) {
      final completedAt = pet['kapon_completed_at']?.toString();
      final vetName = pet['kapon_attending_vet']?.toString();
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF059669).withValues(alpha: 0.4) : const Color(0xFFA7F3D0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF059669).withValues(alpha: 0.3) : const Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spayed / Neutered (Kapon Done)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    completedAt != null && completedAt.isNotEmpty
                        ? 'Completed on $completedAt${vetName != null && vetName.isNotEmpty ? " • $vetName" : ""}'
                        : 'Official surgery procedure verified in pet medical passport.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (kaponStatus == 'scheduled') {
      final scheduledDate = pet['kapon_scheduled_date']?.toString() ?? 'Pending Date';
      final venue = pet['kapon_venue']?.toString() ?? 'CAWS Shelter Clinic';
      final instructions = pet['kapon_instructions']?.toString() ?? '';

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.3) : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.4) : const Color(0xFFBAE6FD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.3) : const Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    size: 16,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Spay / Neuter (Kapon) Scheduled',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 14, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Text(
                        'Date: $scheduledDate',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Venue: $venue',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (instructions.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.2) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.3) : const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              instructions,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                height: 1.35,
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
          ],
        ),
      );
    }

    // Default: awaiting_schedule
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.2) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.35) : const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Awaiting Kapon Schedule Announcement',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Your companion is queued for mandatory spay / neuter (kapon) to prevent cross-breeding. CAWS coordinates clinic dates in batches and will notify you as soon as the veterinary date is scheduled.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pre-op tip: Keep your pet indoors and in good health while awaiting surgery announcement.',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportPassingLink(int appId, String petName, String petImage, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubmitHealthCheckinScreen(
                  applicationId: appId,
                  petName: petName,
                  petImage: petImage,
                  isDeceasedReport: true,
                ),
              ),
            ).then((_) => _fetchAdoptedPets());
          },
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border_rounded, size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  'Report Pet Passing',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMemorialDetails(BuildContext context, Map<String, dynamic> pet) {
    final shelterId = pet['shelterPetId'] ?? pet['pet_id'] ?? pet['petId'] ?? pet['pet']?['id'];
    final shelterCode = pet['shelterPetCode']?.toString() ?? (shelterId != null ? 'Pet no. $shelterId' : 'Pet');
    var petName = (pet['adoptedPetName'] ?? pet['proposedName'] ?? pet['petName'])?.toString() ?? shelterCode;
    if (petName.isEmpty || petName.toLowerCase() == 'adopted pet') {
      petName = shelterCode;
    }
    final petBreed = pet['petBreed'] as String? ?? 'Mixed';
    final petType = pet['petType'] as String? ?? 'Pet';
    final petImage = pet['petImage'] as String? ?? '';
    final appId = (pet['id'] as num?)?.toInt() ?? 0;
    final isDark = AppTheme.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: BoxDecoration(
            color: AppTheme.getSurfaceColor(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_rounded, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        'In Loving Memory',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.getTextPrimary(ctx),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: petImage.isNotEmpty
                        ? Image.network(
                            ApiService.normalizeImageUrl(petImage),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 80,
                              height: 80,
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              child: const Icon(Icons.pets_rounded, color: Color(0xFF64748B), size: 36),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            child: const Icon(Icons.pets_rounded, color: Color(0xFF64748B), size: 36),
                          ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    petName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextPrimary(ctx),
                    ),
                  ),
                  Text(
                    shelterCode.isNotEmpty ? '$shelterCode • $petBreed • $petType' : '$petBreed • $petType',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.getTextSecondary(ctx),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: ApiService.getMyHealthUpdates(applicationId: appId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                        }

                        final updates = snapshot.data ?? [];
                        final deceasedRecord = updates.firstWhere(
                          (u) => (u['health_status']?.toString().toLowerCase().trim() == 'deceased'),
                          orElse: () => updates.isNotEmpty ? updates.first : <String, dynamic>{},
                        );

                        final checkInDate = deceasedRecord['check_in_date']?.toString() ?? 'Recorded';
                        final notes = deceasedRecord['notes']?.toString() ?? 'Official memorial recorded with CAWS.';
                        final decision = deceasedRecord['review_decision']?.toString();
                        final isInvestigation = decision == 'investigation_pending';
                        final isNeglect = decision == 'neglect_confirmed';
                        final isCleared = decision == 'cleared_accidental';

                        String badgeText = 'Recorded';
                        Color badgeBg = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                        Color badgeTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

                        if (isInvestigation) {
                          badgeText = 'On-Site Visit Requested';
                          badgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
                          badgeTextColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
                        } else if (isNeglect) {
                          badgeText = 'Review Recorded';
                          badgeBg = const Color(0xFFE11D48).withValues(alpha: 0.15);
                          badgeTextColor = isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
                        } else if (isCleared) {
                          badgeText = 'Memorial Cleared';
                          badgeBg = const Color(0xFF10B981).withValues(alpha: 0.15);
                          badgeTextColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
                        }

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Memorial Record',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.getTextPrimary(ctx),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: badgeTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Recorded Date: $checkInDate',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        color: AppTheme.getTextSecondary(ctx),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Submitted Circumstances & Tribute',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.getTextPrimary(ctx),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  notes,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (isInvestigation)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.25) : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? const Color(0xFFD97706).withValues(alpha: 0.4) : const Color(0xFFFDE68A)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.home_work_outlined, color: Color(0xFFD97706), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'CAWS shelter staff has requested an on-site consultation / home visit regarding the passing of your companion. A staff member will coordinate the visit schedule with you.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (isNeglect)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF881337).withValues(alpha: 0.25) : const Color(0xFFFFE4E6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? const Color(0xFFE11D48).withValues(alpha: 0.4) : const Color(0xFFFECDD3)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Official CAWS Record: A welfare review violation was recorded for this life event.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            color: isDark ? const Color(0xFFFECDD3) : const Color(0xFF9F1239),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.2) : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isDark ? const Color(0xFF059669).withValues(alpha: 0.4) : const Color(0xFFA7F3D0)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_outline_rounded, color: AppTheme.successColor, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Official CAWS Record: Your companion is respectfully recorded in the CAWS registry. All post-adoption check-in obligations are complete.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF475569),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

