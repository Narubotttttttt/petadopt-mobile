import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/screens/adoption/adopted_pet_hub_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/sign_contract_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String _selectedFilter = 'approved';

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    try {
      final list = await ApiService.getMyApplications();
      final user = await ApiService.getUser();
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'user_${user["id"]}_last_viewed_applications_time',
          DateTime.now().toIso8601String(),
        );
      }
      if (mounted) {
        setState(() {
          _applications = list;
          _isLoading = false;
          final hasApproved = list.any((app) {
            final status = (app['status'] as String? ?? '').toLowerCase();
            return status == 'approved' || status == 'adopted';
          });
          final hasPending = list.any((app) {
            final status = (app['status'] as String? ?? '').toLowerCase();
            return status == 'pending' || status == 'under_review';
          });
          if (!hasApproved && hasPending && _selectedFilter == 'approved') {
            _selectedFilter = 'pending';
          }
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
    final filteredList = _filteredApplications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'My Applications',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchApplications,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B), size: 20),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
          : Column(
              children: [
                // Filter Tabs: Approved first, then Pending, then Declined (No "All")
                if (_applications.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip('approved', 'Approved', _countForFilter('approved')),
                          const SizedBox(width: 8),
                          _buildFilterChip('pending', 'Pending', _countForFilter('pending')),
                          const SizedBox(width: 8),
                          _buildFilterChip('declined', 'Declined', _countForFilter('declined')),
                        ],
                      ),
                    ),
                  ),

                Expanded(
                  child: _applications.isEmpty
                      ? _buildEmptyState(isTotalEmpty: true)
                      : filteredList.isEmpty
                          ? _buildEmptyState(isTotalEmpty: false)
                          : RefreshIndicator(
                              onRefresh: _fetchApplications,
                              color: AppTheme.primary,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredList.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return _ApplicationCard(
                                    application: filteredList[index],
                                    onRefresh: _fetchApplications,
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String key, String label, int count) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool isTotalEmpty}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 26,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isTotalEmpty ? 'No applications yet' : 'No $_selectedFilter applications',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isTotalEmpty
                  ? 'Browse adoptable pets and submit your adoption request.'
                  : 'You have no applications under $_selectedFilter status.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredApplications {
    if (_selectedFilter == 'approved') {
      return _applications.where((app) {
        final status = (app['status'] as String? ?? '').toLowerCase();
        return status == 'approved' || status == 'adopted';
      }).toList();
    }
    if (_selectedFilter == 'pending') {
      return _applications.where((app) {
        final status = (app['status'] as String? ?? '').toLowerCase();
        return status == 'pending' || status == 'under_review';
      }).toList();
    }
    if (_selectedFilter == 'declined') {
      return _applications.where((app) {
        final status = (app['status'] as String? ?? '').toLowerCase();
        final isAdoptedByOther = app['isAdoptedByOther'] == true;
        return status == 'rejected' || isAdoptedByOther;
      }).toList();
    }
    return _applications;
  }

  int _countForFilter(String filter) {
    if (filter == 'approved') {
      return _applications.where((app) {
        final status = (app['status'] as String? ?? '').toLowerCase();
        return status == 'approved' || status == 'adopted';
      }).length;
    }
    if (filter == 'pending') {
      return _applications.where((app) {
        final status = (app['status'] as String? ?? '').toLowerCase();
        return status == 'pending' || status == 'under_review';
      }).length;
    }
    if (filter == 'declined') {
      return _applications.where((app) {
        final status = (app['status'] as String? ?? '').toLowerCase();
        final isAdoptedByOther = app['isAdoptedByOther'] == true;
        return status == 'rejected' || isAdoptedByOther;
      }).length;
    }
    return 0;
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;
  final VoidCallback onRefresh;

  const _ApplicationCard({
    required this.application,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final status = (application['status'] as String? ?? 'pending').toLowerCase();
    final isAdoptedByOther = application['isAdoptedByOther'] as bool? ?? false;
    final scheduledAt = application['scheduledAt'] as String?;
    final eventLocation = application['eventLocation'] as String?;
    final eventNotes = application['eventNotes'] as String?;
    final rejectionReason = (application['rejection_reason'] ?? application['rejectionReason'])?.toString();

    final isScheduled = scheduledAt != null && scheduledAt.isNotEmpty;
    final isSigned = application['is_signed'] == true ||
        (application['signature_url'] != null && application['signature_url'].toString().isNotEmpty);
    final isContractUnlocked = application['contract_unlocked'] == true ||
        application['contractUnlocked'] == true ||
        application['is_finalized'] == true;
    final signedAt = application['signed_at']?.toString();
    final signatureUrl = application['signature_url']?.toString();

    final shelterId = application['shelterPetId'] ?? application['pet_id'] ?? application['petId'] ?? application['pet']?['id'];
    final shelterCode = application['shelterPetCode']?.toString() ?? (shelterId != null ? 'Pet no. $shelterId' : 'Pet');

    String adoptedName = (application['adoptedPetName'] ?? application['proposedName'] ?? application['petName'])?.toString() ?? 'Adopted Pet';
    final petBreed = (application['petBreed'] ?? '').toString().trim();
    if (adoptedName.isEmpty || (petBreed.isNotEmpty && adoptedName.toLowerCase() == petBreed.toLowerCase())) {
      final proposed = application['proposedName']?.toString();
      adoptedName = (proposed != null && proposed.isNotEmpty) ? proposed : 'Adopted Pet';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Pet Image, Info, and Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ApiService.normalizeImageUrl(application['petImage'] as String?),
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 58,
                      height: 58,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(Icons.pets_rounded, color: Color(0xFF94A3B8), size: 22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    adoptedName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(status, isScheduled, isAdoptedByOther),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shelterCode,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((application['application_source'] ?? application['applicationSource']) == 'recommendation' ||
                              application['compatibility_score'] != null ||
                              application['compatibilityScore'] != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Text(
                                (application['compatibility_score'] ?? application['compatibilityScore']) != null
                                    ? 'AI Match ${((application['compatibility_score'] ?? application['compatibilityScore']) as num).toInt()}%'
                                    : 'AI Match',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF047857),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Applied: ${application['dateApplied'] ?? 'Recently'}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Scheduled Pickup Info (if approved and scheduled)
            if (status == 'approved' && isScheduled) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_available_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pickup: $scheduledAt',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (eventLocation != null && eventLocation.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              eventLocation,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (eventNotes != null && eventNotes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        eventNotes,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Action Row / States
            if (status == 'approved' && !isSigned) ...[
              // Action: Contract Signing Required
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => SignContractDialog(
                        application: application,
                        onSigned: onRefresh,
                      ),
                    );
                  },
                  icon: const Icon(Icons.draw_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'Pre-Sign Adoption Agreement',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Pre-signing saves time at your scheduled event',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFB45309)),
                ),
              ),
            ] else if ((status == 'approved' || status == 'adopted') && isSigned) ...[
              // State: Signed & Health Hub Access
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                  [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          isContractUnlocked ? Icons.verified_rounded : Icons.schedule_rounded,
                          size: 14,
                          color: isContractUnlocked ? const Color(0xFF059669) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            isContractUnlocked
                                ? (signedAt != null && signedAt.isNotEmpty
                                    ? 'Handover Finalized · Contract Unlocked ($signedAt)'
                                    : 'Handover Finalized · Contract Unlocked')
                                : 'Pre-Signed · Pending Venue Verification',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isContractUnlocked ? const Color(0xFF059669) : const Color(0xFFD97706),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (signatureUrl != null && signatureUrl.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showSignatureDialog(context, signatureUrl),
                      child: Text(
                        'View Pre-Signature',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
              if (!isContractUnlocked) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFB45309)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Note: This is only a pre-signing step. Please bring the original copies of your uploaded Valid ID and Barangay Certificate on your scheduled date. You can only download the adoption contract after CAWS verifies your identification.',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: const Color(0xFF92400E),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Show 'Name Your Pet' if pet has no custom name, otherwise show Health Hub
              Builder(builder: (context) {
                final hasCustomName = adoptedName.isNotEmpty &&
                    adoptedName.toLowerCase() != 'adopted pet' &&
                    adoptedName.toLowerCase() != 'rescued pet';

                if (!hasCustomName) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditNameDialog(context, application, adoptedName, onRefresh),
                      icon: const Icon(Icons.drive_file_rename_outline_rounded, size: 15, color: Colors.white),
                      label: Text(
                        'Name Your Adopted Pet First',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF199CA4),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdoptedPetHubScreen(application: application),
                        ),
                      ).then((_) => onRefresh());
                    },
                    icon: const Icon(Icons.pets_rounded, size: 15, color: AppTheme.primary),
                    label: Text(
                      'View Adopted Pet Health Hub',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                );
              }),
            ] else if (status == 'rejected' && rejectionReason != null && rejectionReason.isNotEmpty) ...[
              // State: Declined Note
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: Text(
                  'Note: $rejectionReason',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF991B1B),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(
    BuildContext context,
    Map<String, dynamic> application,
    String currentName,
    VoidCallback onRefresh,
  ) {
    final petId = (application['shelterPetId'] ?? application['pet_id'] ?? application['petId'] ?? application['pet']?['id']) as int?;
    if (petId == null) return;

    final isDefault = currentName.toLowerCase() == 'adopted pet' || currentName.toLowerCase() == 'rescued pet';
    final controller = TextEditingController(text: isDefault ? '' : currentName);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.drive_file_rename_outline_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isDefault ? 'Name Your Adopted Pet' : 'Change Pet Name',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isDefault
                          ? 'Enter your decided name for this pet. This name will appear on your health records and shelter documents.'
                          : 'You may rename this pet or leave the field empty to keep the current name.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'e.g. Bella, Milo, Rocky',
                        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.pets_rounded, size: 18, color: AppTheme.primary),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final entered = controller.text.trim();
                                    // If the pet already has a real name and the field is empty,
                                    // the user chose not to rename — just close the dialog.
                                    if (entered.isEmpty) {
                                      if (!isDefault) Navigator.pop(dialogContext);
                                      return;
                                    }
                                    setDialogState(() => isSaving = true);
                                    try {
                                      await ApiService.updatePetName(
                                        petId: petId,
                                        name: entered,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(dialogContext);
                                        onRefresh();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Pet name updated to "$entered"',
                                              style: GoogleFonts.poppins(fontSize: 13),
                                            ),
                                            backgroundColor: AppTheme.successColor,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setDialogState(() => isSaving = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString().replaceAll('Exception: ', ''),
                                              style: GoogleFonts.poppins(fontSize: 13),
                                            ),
                                            backgroundColor: const Color(0xFFDC2626),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Save Name',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, bool isScheduled, bool isAdoptedByOther) {
    Color dotColor;
    Color bgColor;
    String label;

    if (isAdoptedByOther) {
      label = 'Adopted by Other';
      dotColor = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEF2F2);
    } else if (isScheduled && status != 'approved' && status != 'rejected') {
      label = 'Scheduled';
      dotColor = const Color(0xFF0284C7);
      bgColor = const Color(0xFFF0F9FF);
    } else {
      switch (status) {
        case 'approved':
          label = 'Approved';
          dotColor = const Color(0xFF059669);
          bgColor = const Color(0xFFECFDF5);
          break;
        case 'rejected':
          label = 'Declined';
          dotColor = const Color(0xFFDC2626);
          bgColor = const Color(0xFFFEF2F2);
          break;
        case 'under_review':
          label = 'Reviewing';
          dotColor = const Color(0xFF2563EB);
          bgColor = const Color(0xFFEFF6FF);
          break;
        default:
          label = 'Pending';
          dotColor = const Color(0xFFD97706);
          bgColor = const Color(0xFFFFFBEB);
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showSignatureDialog(BuildContext context, String signatureUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Adopter Digital Signature',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Image.network(
                  ApiService.normalizeImageUrl(signatureUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Text('Signature on file', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
