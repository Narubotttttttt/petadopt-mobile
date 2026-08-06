import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    try {
      final list = await ApiService.getMyApplications();
      if (mounted) {
        setState(() {
          _applications = list;
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
        automaticallyImplyLeading: false,
        title: Text(
          'My Applications',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchApplications,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _applications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchApplications,
                  color: AppTheme.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _applications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      return _ApplicationCard(application: _applications[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            'No applications yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Browse available pets and apply for adoption!',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> application;

  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final status = (application['status'] as String?) ?? 'pending';
    final scheduledAt = application['scheduledAt'] as String?;
    final isAdoptedByOther = (application['isAdoptedByOther'] as bool?) ?? false;
    final statusInfo = _getStatusInfo(status, scheduledAt != null, isAdoptedByOther);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    application['petImage'] as String,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: AppTheme.primaryLight,
                      child: const Center(
                        child: Text('🐾', style: TextStyle(fontSize: 28)),
                      ),
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
                              application['petName'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _StatusBadge(
                            label: statusInfo['label'] as String,
                            color: statusInfo['color'] as Color,
                            bgColor: statusInfo['bgColor'] as Color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${application['petBreed']} • ${application['petType']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Applied: ${application['dateApplied']}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (status == 'approved' && scheduledAt != null && scheduledAt.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🎪', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'CAWS Mall Adoption Event & Release',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            scheduledAt,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            (application['eventLocation'] as String?)?.isNotEmpty == true
                                ? (application['eventLocation'] as String)
                                : 'CAWS Adoption Event',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              (application['eventNotes'] as String?)?.isNotEmpty == true
                                  ? (application['eventNotes'] as String)
                                  : 'Please bring your Valid ID and Barangay Certificate for pet release & verification.',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isAdoptedByOther) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD8BF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🐾', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${application['petName']} Has Found a Forever Home!',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD9363E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sorry, the pet you requested (${application['petName']}) has already found a forever home with another verified applicant! Please explore our other lovable pets waiting for a home.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.popUntil(context, ModalRoute.withName('/home'));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pets_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Browse Other Pets',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
    );
  }

  Map<String, dynamic> _getStatusInfo(String status, bool isScheduled, bool isAdoptedByOther) {
    if (isAdoptedByOther) {
      return {
        'label': 'Adopted by Other 🐾',
        'color': const Color(0xFFD9363E),
        'bgColor': const Color(0xFFFFF4ED),
      };
    }

    if (isScheduled && status != 'approved' && status != 'rejected') {
      return {
        'label': 'Scheduled 📅',
        'color': AppTheme.primaryDark,
        'bgColor': AppTheme.primaryLight,
      };
    }

    switch (status) {
      case 'approved':
        return {
          'label': 'Approved 🎉',
          'color': AppTheme.successColor,
          'bgColor': const Color(0xFFE8F8F1),
        };
      case 'rejected':
        return {
          'label': 'Declined ❌',
          'color': AppTheme.errorColor,
          'bgColor': const Color(0xFFFEEEEE),
        };
      case 'under_review':
        return {
          'label': 'Reviewing 🔍',
          'color': const Color(0xFF3B82F6),
          'bgColor': const Color(0xFFEFF6FF),
        };
      default:
        return {
          'label': 'Pending ⏳',
          'color': AppTheme.warningColor,
          'bgColor': const Color(0xFFFFFBEB),
        };
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
