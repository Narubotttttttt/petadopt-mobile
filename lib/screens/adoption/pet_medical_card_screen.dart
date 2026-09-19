import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

class PetMedicalCardScreen extends StatefulWidget {
  final int petId;
  final int? applicationId;
  final String? petName;
  final String? petImage;

  const PetMedicalCardScreen({
    super.key,
    required this.petId,
    this.applicationId,
    this.petName,
    this.petImage,
  });

  @override
  State<PetMedicalCardScreen> createState() => _PetMedicalCardScreenState();
}

class _PetMedicalCardScreenState extends State<PetMedicalCardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _passport;

  @override
  void initState() {
    super.initState();
    _fetchPassport();
  }

  Future<void> _fetchPassport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getPetMedicalPassport(widget.petId);
      if (mounted) {
        setState(() {
          _passport = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = _passport?['pet'] as Map<String, dynamic>?;
    final guardian = _passport?['guardian'] as Map<String, dynamic>?;
    final summary = _passport?['clinical_summary'] as Map<String, dynamic>?;
    final records = (_passport?['records'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final petDisplayName = pet?['name'] as String? ?? widget.petName ?? 'Pet Health Card';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          petDisplayName.isNotEmpty ? '$petDisplayName Health Card' : 'Pet Health Card',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _fetchPassport,
            child: Text(
              'Refresh',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _fetchPassport,
                  color: AppTheme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPetCard(pet, guardian),
                        const SizedBox(height: 12),
                        _buildStatusSummary(summary),
                        const SizedBox(height: 16),
                        _buildMedicalHistory(records),
                        const SizedBox(height: 20),
                        _buildAdvisoryFooter(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Could Not Load Health Card',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Unable to retrieve clinical records.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPassport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(
    Map<String, dynamic>? pet,
    Map<String, dynamic>? guardian,
  ) {
    final registryNo = pet?['registry_number'] as String? ?? 'CAWS-PET-${widget.petId.toString().padLeft(5, '0')}';
    final petName = pet?['name'] as String? ?? widget.petName ?? 'Pet';
    final petType = pet?['type'] as String? ?? 'Pet';
    final breed = pet?['breed'] as String? ?? 'Mixed Breed';
    final age = pet?['age'] as String? ?? '';
    final gender = pet?['gender'] as String? ?? '';
    final photoUrl = pet?['photo_url'] as String? ?? widget.petImage ?? '';

    final guardianName = guardian?['name'] as String? ?? 'Adopter';
    final adopterCode = guardian?['adopter_code'] as String? ?? '';
    final guardianPhone = guardian?['phone'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Registry Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF146970),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CAWS HEALTH CARD',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
                Text(
                  registryNo,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFFB0E9ED),
                  ),
                ),
              ],
            ),
          ),

          // Pet Information
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 58,
                            height: 58,
                            color: const Color(0xFFF0FBFB),
                            alignment: Alignment.center,
                            child: Text(
                              'PET',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 58,
                          height: 58,
                          color: const Color(0xFFF0FBFB),
                          alignment: Alignment.center,
                          child: Text(
                            'PET',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        petName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '$breed • $petType',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (gender.isNotEmpty) _buildChip(gender),
                          if (gender.isNotEmpty && age.isNotEmpty) const SizedBox(width: 6),
                          if (age.isNotEmpty) _buildChip(age),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Guardian Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Guardian: $guardianName${adopterCode.isNotEmpty ? ' ($adopterCode)' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                if (guardianPhone.isNotEmpty && guardianPhone != 'N/A')
                  Text(
                    guardianPhone,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildStatusSummary(Map<String, dynamic>? summary) {
    final status = summary?['vaccine_status'] as String? ?? 'Not Vaccinated';
    final latestVac = summary?['latest_vaccine_date'] as String?;
    final latestDeworming = summary?['latest_deworming_date'] as String?;
    final totalRecords = summary?['total_records_count'] as int? ?? 0;

    Color statusColor;
    String statusLabel;

    if (status == 'Up to Date' || latestVac != null) {
      statusColor = const Color(0xFF15838B);
      statusLabel = 'PROTECTED';
    } else {
      statusColor = const Color(0xFF64748B);
      statusLabel = 'RECORDED';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CLINICAL STATUS',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: const Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricCol(
                  'Last Vaccine',
                  latestVac ?? 'None',
                  AppTheme.textPrimary,
                ),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildMetricCol(
                    'Deworming',
                    latestDeworming ?? 'Pending',
                    AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildMetricCol(
                    'Total Logs',
                    '$totalRecords',
                    AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String title, String value, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: valColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalHistory(List<Map<String, dynamic>> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Medical History',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${records.length} record${records.length == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text(
                'No medical records logged yet.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildRecordRow(records[index]);
            },
          ),
      ],
    );
  }

  Widget _buildRecordRow(Map<String, dynamic> log) {
    final category = (log['category'] as String? ?? '').toLowerCase();
    final categoryLabel = log['category_label'] as String? ?? 'Treatment';
    final vaccineName = log['vaccine_name'] as String?;
    final dateFormatted = log['date_formatted'] as String? ?? 'N/A';
    final administeredBy = log['administered_by'] as String? ?? 'Shelter Staff';

    final isVaccination = category == 'vaccination';
    final isDeworming = category == 'deworming';

    final Color badgeBg = isVaccination
        ? const Color(0xFFE6F4F5)
        : (isDeworming ? const Color(0xFFF3E8FF) : const Color(0xFFF1F5F9));
    final Color badgeColor = isVaccination
        ? const Color(0xFF15838B)
        : (isDeworming ? const Color(0xFF7E22CE) : const Color(0xFF475569));

    final primaryTitle = (vaccineName != null &&
            vaccineName.trim().isNotEmpty &&
            vaccineName.trim().toLowerCase() != category)
        ? vaccineName.trim()
        : categoryLabel;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showRecordDetails(log, primaryTitle, categoryLabel),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        categoryLabel.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    Text(
                      dateFormatted,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  primaryTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 13,
                        color: Color(0xFF15838B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Administered by: $administeredBy',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecordDetails(Map<String, dynamic> log, String title, String categoryLabel) {
    final dateFormatted = log['date_formatted'] as String? ?? 'N/A';
    final administeredBy = log['administered_by'] as String? ?? 'Shelter Staff';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Clinical Administration Record',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildDetailTile('Treatment / Dose', title),
                _buildDetailTile('Record Category', categoryLabel),
                _buildDetailTile('Administration Date', dateFormatted),
                _buildDetailTile('Administered By', administeredBy),
                _buildDetailTile('Authorized Facility', 'CDO Animal Welfare Society (CAWS)'),
                _buildDetailTile('Verification Status', 'Official Shelter Record Verified'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 18,
            color: Color(0xFF15838B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Official record of clinical care administered at CAWS. Present this card to your veterinarian during routine checkups.',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
