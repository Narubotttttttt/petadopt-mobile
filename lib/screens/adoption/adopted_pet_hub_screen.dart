import 'package:mobile_petadopt/screens/adoption/pet_medical_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/screens/adoption/submit_health_checkin_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/app_confirmation_dialog.dart';
import 'package:mobile_petadopt/widgets/sign_contract_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class AdoptedPetHubScreen extends StatefulWidget {
  final Map<String, dynamic> application;

  const AdoptedPetHubScreen({
    super.key,
    required this.application,
  });

  @override
  State<AdoptedPetHubScreen> createState() => _AdoptedPetHubScreenState();
}

class _AdoptedPetHubScreenState extends State<AdoptedPetHubScreen> {
  bool _isLoading = true;
  bool _isDownloading = false;
  List<Map<String, dynamic>> _healthUpdates = [];
  List<Map<String, dynamic>> _vaccineReminders = [];

  @override
  void initState() {
    super.initState();
    _loadHubData();
  }

  Future<void> _loadHubData() async {
    final isFinalized = widget.application['is_finalized'] == true ||
        widget.application['isFinalized'] == true ||
        widget.application['contract_unlocked'] == true;
    if (!isFinalized) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final appId = (widget.application['id'] as num?)?.toInt() ?? 0;
    try {
      final updates = await ApiService.getMyHealthUpdates(applicationId: appId);
      final reminders = await ApiService.getVaccineReminders();
      if (mounted) {
        setState(() {
          _healthUpdates = updates;
          _vaccineReminders = reminders;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openSignatureDialog() {
    showDialog(
      context: context,
      builder: (_) => SignContractDialog(
        application: widget.application,
        onSigned: () {
          setState(() {
            widget.application['is_signed'] = true;
            widget.application['signature_url'] = 'signed';
          });
          _loadHubData();
        },
      ),
    );
  }

  void _showSignatureRequiredDialog() {
    AppConfirmationDialog.show(
      context,
      icon: Icons.draw_rounded,
      iconColor: const Color(0xFFD97706),
      iconBackgroundColor: const Color(0xFFFEF3C7),
      title: 'Signature Required',
      message:
          'Please provide a signature first before downloading the contract. Your digital signature must be attached to the official CAWS adoption agreement.',
      cancelText: 'Cancel',
      confirmText: 'Sign Contract Now',
      confirmColor: const Color(0xFFD97706),
      onConfirm: () => _openSignatureDialog(),
    );
  }

  void _showContractLockedDialog() {
    AppConfirmationDialog.show(
      context,
      icon: Icons.lock_clock_rounded,
      iconColor: const Color(0xFFD97706),
      iconBackgroundColor: const Color(0xFFFEF3C7),
      title: 'Contract Locked',
      confirmText: 'Understood',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adoption agreement pre-signed!',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              'Note: This is only a pre-signing step. Please bring the original copies of your uploaded Valid ID and Barangay Certificate on your scheduled date. You can only download the adoption contract after CAWS verifies your identification.',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF92400E), height: 1.4),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Please bring your original Valid ID and Barangay Certificate to the venue on your scheduled date to finalize your adoption.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownloadContract() async {
    final isSigned = widget.application['is_signed'] == true || 
        (widget.application['signature_url'] != null && widget.application['signature_url'].toString().isNotEmpty);

    if (!isSigned) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please provide a pre-signature first before downloading the contract.',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Sign Now',
            textColor: Colors.white,
            onPressed: _openSignatureDialog,
          ),
        ),
      );

      _showSignatureRequiredDialog();
      return;
    }

    final isContractUnlocked = widget.application['contract_unlocked'] == true ||
        widget.application['contractUnlocked'] == true ||
        widget.application['is_finalized'] == true;

    if (!isContractUnlocked) {
      _showContractLockedDialog();
      return;
    }

    final appId = (widget.application['id'] as num?)?.toInt() ?? 0;
    setState(() => _isDownloading = true);

    try {
      final downloadUrl = await ApiService.getContractDownloadUrl(appId);
      if (downloadUrl != null) {
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      throw Exception('Could not open browser to download the contract.');
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        final isSignatureError = errorMsg.toLowerCase().contains('signature') || errorMsg.toLowerCase().contains('sign');

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSignatureError ? 'Please provide a signature first before downloading the contract.' : errorMsg,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: isSignatureError ? const Duration(seconds: 6) : const Duration(seconds: 4),
            action: isSignatureError
                ? SnackBarAction(
                    label: 'Sign Now',
                    textColor: Colors.white,
                    onPressed: _openSignatureDialog,
                  )
                : null,
          ),
        );

        if (isSignatureError) {
          _showSignatureRequiredDialog();
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _openSubmitScreen({bool isDeceasedReport = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitHealthCheckinScreen(
          applicationId: (widget.application['id'] as num?)?.toInt() ?? 0,
          petName: widget.application['petName']?.toString() ?? widget.application['adoptedPetName']?.toString() ?? 'Adopted Pet',
          petImage: widget.application['petImage']?.toString() ?? '',
          isDeceasedReport: isDeceasedReport,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadHubData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final petName = widget.application['petName'] as String? ?? 'Adopted Pet';
    final petBreed = widget.application['petBreed'] as String? ?? 'Mixed';
    final petType = widget.application['petType'] as String? ?? 'Pet';
    final petImage = widget.application['petImage'] as String? ?? '';
    final dateApplied = widget.application['dateApplied'] as String? ?? '';

    final latestCheckin = _healthUpdates.isNotEmpty ? _healthUpdates.first : null;
    final isDeceased = _healthUpdates.any((u) => (u['health_status'] as String?)?.toLowerCase() == 'deceased') ||
        (widget.application['pet_status'] as String?)?.toLowerCase() == 'deceased' ||
        (widget.application['status'] as String?)?.toLowerCase() == 'deceased';

    final deceasedCheckin = _healthUpdates.cast<Map<String, dynamic>?>().firstWhere(
      (u) => (u?['health_status'] as String?)?.toLowerCase() == 'deceased',
      orElse: () => null,
    );

    DateTime? nextDueDate;
    int? daysLeft;
    bool isOverdue = false;
    int overdueDays = 0;

    if (!isDeceased) {
      if (latestCheckin != null && latestCheckin['check_in_date'] != null) {
        try {
          final lastDate = DateTime.parse(latestCheckin['check_in_date'].toString());
          nextDueDate = lastDate.add(const Duration(days: 30));
        } catch (_) {}
      } else if (dateApplied.isNotEmpty) {
        try {
          final applied = DateTime.parse(dateApplied);
          nextDueDate = applied.add(const Duration(days: 30));
        } catch (_) {}
      }

      if (nextDueDate != null) {
        final now = DateTime.now();
        if (now.isAfter(nextDueDate)) {
          isOverdue = true;
          overdueDays = now.difference(nextDueDate).inDays;
        } else {
          daysLeft = nextDueDate.difference(now).inDays;
        }
      }
    }

    final isFinalized = widget.application['is_finalized'] == true ||
        widget.application['isFinalized'] == true ||
        widget.application['contract_unlocked'] == true;

    if (!isFinalized) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(
            petName,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    size: 56,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Health Hub Locked',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'The Pet Health Hub unlocks once CAWS staff physically verifies your identification documents and completes the pet handover at the scheduled event.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'Back to Applications',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final petId = (widget.application['pet_id'] ??
        widget.application['petId'] ??
        widget.application['pet']?['id'] ??
        widget.application['shelterPetId']) as int? ?? 0;

    return PetMedicalCardScreen(
      petId: petId,
      applicationId: (widget.application['id'] as num?)?.toInt(),
      petName: petName,
      petImage: petImage,
    );
  }

  Widget _buildPetHeroCard(
    String name,
    String breed,
    String type,
    String image,
    String dateApplied, {
    bool isDeceased = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.network(
              image,
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: double.infinity,
                height: 190,
                color: AppTheme.primaryLight,
                child: const Center(
                  child: Icon(Icons.pets_rounded, size: 48, color: AppTheme.primary),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '$breed • $type',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDeceased ? const Color(0xFFF1F5F9) : const Color(0xFFE8F8F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isDeceased ? 'Passed Away' : 'Adopted',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDeceased ? const Color(0xFF475569) : AppTheme.successColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isDownloading ? null : _handleDownloadContract,
                        icon: _isDownloading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                              )
                            : Icon(
                                (widget.application['contract_unlocked'] == true || widget.application['contractUnlocked'] == true || widget.application['is_finalized'] == true)
                                    ? Icons.download_rounded
                                    : Icons.lock_outline_rounded,
                                size: 15,
                                color: (widget.application['contract_unlocked'] == true || widget.application['contractUnlocked'] == true || widget.application['is_finalized'] == true)
                                    ? AppTheme.primary
                                    : const Color(0xFFD97706),
                              ),
                        label: Text(
                          _isDownloading
                              ? 'Downloading...'
                              : ((widget.application['contract_unlocked'] == true || widget.application['contractUnlocked'] == true || widget.application['is_finalized'] == true)
                                  ? 'Contract'
                                  : 'Contract (Locked)'),
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: (widget.application['contract_unlocked'] == true || widget.application['contractUnlocked'] == true || widget.application['is_finalized'] == true)
                                ? AppTheme.primaryDark
                                : const Color(0xFFB45309),
                            height: 1.2,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final petId = (widget.application['pet_id'] ?? widget.application['petId'] ?? widget.application['pet']?['id']) as int?;
                          if (petId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PetMedicalCardScreen(
                                  petId: petId,
                                  applicationId: widget.application['id'] as int?,
                                  petName: name,
                                  petImage: image,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.medical_services_outlined, size: 15, color: Colors.white),
                        label: Text(
                          'Pet Card',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size.fromHeight(44),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinStatusCard({
    required bool isOverdue,
    required int overdueDays,
    required int? daysLeft,
    required Map<String, dynamic>? latestCheckin,
  }) {
    final String statusTitle;
    final String statusSubtitle;
    final String badgeText;
    final Color badgeBg;
    final Color badgeTextColor;

    if (isOverdue) {
      statusTitle = 'Monthly Report Overdue';
      statusSubtitle = 'Overdue by $overdueDays day${overdueDays == 1 ? '' : 's'}. Please submit an update to keep your Active standing with CAWS.';
      badgeText = 'Overdue (${overdueDays}d)';
      badgeBg = const Color(0xFFFFEAEA);
      badgeTextColor = AppTheme.errorColor;
    } else if (latestCheckin != null) {
      statusTitle = 'Monthly Check-in (Active)';
      statusSubtitle = daysLeft != null
          ? 'Next monthly update due in $daysLeft day${daysLeft == 1 ? '' : 's'}.'
          : 'Up to date with monthly updates.';
      badgeText = daysLeft != null ? 'Due in ${daysLeft}d' : 'Up to Date';
      badgeBg = const Color(0xFFE8F8F1);
      badgeTextColor = AppTheme.successColor;
    } else {
      statusTitle = 'First Monthly Check-in';
      statusSubtitle = daysLeft != null
          ? 'First 30-day update due in $daysLeft day${daysLeft == 1 ? '' : 's'}.'
          : 'First monthly update due in 30 days.';
      badgeText = daysLeft != null ? 'Due in ${daysLeft}d' : 'Active (New)';
      badgeBg = const Color(0xFFE6F6F7);
      badgeTextColor = AppTheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue ? AppTheme.errorColor.withValues(alpha: 0.3) : AppTheme.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverdue ? AppTheme.errorColor.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isOverdue ? AppTheme.errorColor : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusSubtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => _openSubmitScreen(),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
              backgroundColor: isOverdue ? AppTheme.errorColor : AppTheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Submit Monthly Check-in',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () => _openSubmitScreen(isDeceasedReport: true),
            icon: const Icon(Icons.favorite_border_rounded, size: 16, color: Colors.white),
            label: Text(
              'Report Pet Passing / Life Event',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              backgroundColor: const Color(0xFF475569),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorialCard(String petName, Map<String, dynamic>? deceasedUpdate) {
    final passingDate = deceasedUpdate?['check_in_date']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFF64748B),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In Loving Memory of $petName',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'CAWS Records Concluded & Archived',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'In Memoriam',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Text(
            'You have officially informed CAWS that $petName has passed away. All monthly health check-in obligations have been respectfully fulfilled and permanently concluded. CAWS extends its gratitude for the loving home and warmth you provided.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          if (passingDate.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_note_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'Notification Date: $passingDate',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthJournalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health Check-in Journal',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '${_healthUpdates.length} Reports',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_healthUpdates.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Center(
              child: Text(
                'No health reports submitted yet.\nTap the button above to upload your first monthly update.',
                textAlign: TextAlign.center,
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
            itemCount: _healthUpdates.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final item = _healthUpdates[idx];
              final photoUrl = item['photo_url'] as String? ?? '';
              final date = item['check_in_date'] as String? ?? '';
              final status = item['health_status'] as String? ?? 'healthy';
              final weight = item['weight'];
              final notes = item['notes'] as String? ?? '';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        photoUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
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
                              Text(
                                date,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              _buildConditionBadge(status),
                            ],
                          ),
                          if (weight != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Weight: $weight kg',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ],
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              notes,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildVaccineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shelter Medical Records',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            InkWell(
              onTap: () {
                final petId = (widget.application['pet_id'] ?? widget.application['petId'] ?? widget.application['pet']?['id']) as int?;
                if (petId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PetMedicalCardScreen(
                        petId: petId,
                        applicationId: widget.application['id'] as int?,
                        petName: widget.application['petName'] as String? ?? 'Adopted Pet',
                        petImage: widget.application['petImage'] as String? ?? '',
                      ),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Pet Card',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_vaccineReminders.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Text(
              'No upcoming medical reminders recorded by CAWS.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vaccineReminders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final rem = _vaccineReminders[idx];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.vaccines_outlined, size: 18, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          rem['category'] as String? ?? 'Medical Care',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Due: ${rem['next_due_label'] ?? ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildConditionBadge(String status) {
    String label = 'Healthy & Active';
    Color color = AppTheme.successColor;
    Color bg = const Color(0xFFE8F8F1);

    if (status == 'minor_issue') {
      label = 'Minor Issue';
      color = AppTheme.warningColor;
      bg = const Color(0xFFFFFBEB);
    } else if (status == 'under_treatment') {
      label = 'In Treatment';
      color = AppTheme.errorColor;
      bg = const Color(0xFFFEEEEE);
    } else if (status == 'deceased') {
      label = 'Passed Away';
      color = const Color(0xFF475569);
      bg = const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
