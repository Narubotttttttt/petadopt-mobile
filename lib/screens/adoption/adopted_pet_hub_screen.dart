import 'package:mobile_petadopt/screens/adoption/pet_medical_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/screens/adoption/submit_health_checkin_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.draw_rounded, color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Signature Required',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Please provide a signature first before downloading the contract. Your digital signature must be attached to the official CAWS adoption agreement.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _openSignatureDialog();
            },
            icon: const Icon(Icons.edit_document, size: 16, color: Colors.white),
            label: Text(
              'Sign Contract Now',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
            'Please provide a signature first before downloading the contract.',
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

  void _openSubmitScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitHealthCheckinScreen(
          applicationId: (widget.application['id'] as num?)?.toInt() ?? 0,
          petName: widget.application['petName']?.toString() ?? widget.application['adoptedPetName']?.toString() ?? 'Adopted Pet',
          petImage: widget.application['petImage']?.toString() ?? '',
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

    DateTime? nextDueDate;
    int? daysLeft;
    bool isOverdue = false;
    int overdueDays = 0;

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadHubData,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPetHeroCard(petName, petBreed, petType, petImage, dateApplied),
                    const SizedBox(height: 16),
                    _buildCheckinStatusCard(
                      isOverdue: isOverdue,
                      overdueDays: overdueDays,
                      daysLeft: daysLeft,
                      latestCheckin: latestCheckin,
                    ),
                    const SizedBox(height: 20),
                    _buildHealthJournalSection(),
                    const SizedBox(height: 20),
                    _buildVaccineSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPetHeroCard(
    String name,
    String breed,
    String type,
    String image,
    String dateApplied,
  ) {
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
                        color: const Color(0xFFE8F8F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Adopted',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.successColor,
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
                            : const Icon(Icons.download_rounded, size: 15, color: AppTheme.primary),
                        label: Text(
                          _isDownloading ? 'Downloading...' : 'Contract',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryDark,
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
            onPressed: _openSubmitScreen,
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
