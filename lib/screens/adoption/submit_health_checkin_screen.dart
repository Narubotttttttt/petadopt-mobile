import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';

class SubmitHealthCheckinScreen extends StatefulWidget {
  final int applicationId;
  final String petName;
  final String petImage;
  final bool isDeceasedReport;

  const SubmitHealthCheckinScreen({
    super.key,
    required this.applicationId,
    required this.petName,
    required this.petImage,
    this.isDeceasedReport = false,
  });

  @override
  State<SubmitHealthCheckinScreen> createState() => _SubmitHealthCheckinScreenState();
}

class _SubmitHealthCheckinScreenState extends State<SubmitHealthCheckinScreen> {
  File? _photo;
  late String _healthStatus;
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _clinicCtrl = TextEditingController();
  DateTime? _passingDate;
  String _deceasedCause = 'Natural Causes / Old Age';
  String? _notesError;
  bool _isSubmitting = false;

  final List<String> _deceasedCauses = [
    'Natural Causes / Old Age',
    'Severe Illness / Medical Condition',
    'Accident / Trauma',
    'Humane Euthanasia (Veterinary Advice)',
    'Sudden Illness / Unknown Cause',
    'Other (specified in notes)',
  ];

  @override
  void initState() {
    super.initState();
    _healthStatus = widget.isDeceasedReport ? 'deceased' : 'healthy';
    _passingDate = DateTime.now();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    _clinicCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => _photo = File(picked.path));
    }
  }

  Future<void> _pickPassingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _passingDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF475569),
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _passingDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    final isDeceased = _healthStatus == 'deceased';

    if (!isDeceased && _photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please capture or select a recent photo of your pet.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (isDeceased) {
      final reasonText = _notesCtrl.text.trim();
      if (reasonText.isEmpty) {
        setState(() {
          _notesError = 'Please explain what happened to your pet. This reason is required.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please explain what happened to your pet. The explanation field is required.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      if (reasonText.length < 10) {
        setState(() {
          _notesError = 'Please provide a more detailed explanation of what happened (at least 10 characters).';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Explanation is too short. Please provide at least 10 characters explaining what happened.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      setState(() => _notesError = null);

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.favorite_border_rounded, color: Color(0xFF475569), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Confirm Life Event Report',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to officially report that ${widget.petName} has passed away? This will update CAWS organization records and close recurring monthly check-ins for this pet.',
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF475569),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Confirm & Submit',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    final weight = isDeceased ? null : double.tryParse(_weightCtrl.text.trim());
    setState(() => _isSubmitting = true);

    String formattedNotes;
    if (isDeceased) {
      final passDateStr = _passingDate != null
          ? '${_passingDate!.year}-${_passingDate!.month.toString().padLeft(2, '0')}-${_passingDate!.day.toString().padLeft(2, '0')}'
          : 'Recent';
      final clinic = _clinicCtrl.text.trim();
      formattedNotes = '[PET LIFE EVENT: DECEASED REPORT]\n'
          'Date of Passing: $passDateStr\n'
          'Cause Category: $_deceasedCause\n'
          '${clinic.isNotEmpty ? 'Attending Vet / Clinic: $clinic\n' : ''}'
          'Reason & Circumstances: ${_notesCtrl.text.trim()}';
    } else {
      formattedNotes = _notesCtrl.text.trim();
    }

    try {
      await ApiService.submitHealthUpdate(
        applicationId: widget.applicationId,
        photo: _photo,
        healthStatus: _healthStatus,
        weight: weight,
        notes: formattedNotes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDeceased
                  ? 'Deceased notification received. CAWS records have been respectfully updated.'
                  : 'Monthly health report submitted successfully.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: isDeceased ? const Color(0xFF475569) : AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDeceased = _healthStatus == 'deceased';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          isDeceased ? 'Report Pet Passing' : 'Monthly Health Check-in',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPetHeader(),
                  const SizedBox(height: 20),
                  _buildPhotoSection(),
                  const SizedBox(height: 20),
                  if (isDeceased)
                    _buildDeceasedDetailsSection()
                  else ...[
                    _buildHealthConditionSection(),
                    const SizedBox(height: 20),
                    _buildWeightAndNotesSection(),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomSubmitBar(),
        ],
      ),
    );
  }

  Widget _buildPetHeader() {
    final isDeceased = _healthStatus == 'deceased';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.petImage,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 52,
                height: 52,
                color: AppTheme.primaryLight,
                child: const Icon(Icons.pets_rounded, color: AppTheme.primary, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.petName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  isDeceased
                      ? 'Official Notification of Pet Passing'
                      : 'Post-Adoption Monthly Health Report',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    final isDeceased = _healthStatus == 'deceased';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isDeceased ? '1. Memorial Photo or Document' : '1. Recent Pet Photo',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDeceased ? const Color(0xFFF1F5F9) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDeceased ? const Color(0xFFCBD5E1) : const Color(0xFFF87171),
                  width: 0.8,
                ),
              ),
              child: Text(
                isDeceased ? 'OPTIONAL' : 'REQUIRED',
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: isDeceased ? const Color(0xFF475569) : const Color(0xFFDC2626),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isDeceased
              ? 'Upload a memorial photo of your pet, or an official veterinary document / death certificate if available.'
              : 'Take or upload a clear, current photo of your pet.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),

        if (_photo != null)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDeceased ? const Color(0xFF475569) : AppTheme.primary, width: 1.5),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.file(
                    _photo!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Photo Selected',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _pickPhoto(ImageSource.camera),
                            child: Text(
                              'Retake',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDeceased ? const Color(0xFF475569) : AppTheme.primary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _pickPhoto(ImageSource.gallery),
                            child: Text(
                              'Gallery',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDeceased ? const Color(0xFF475569) : AppTheme.primary,
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
          )
        else
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickPhoto(ImageSource.camera),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDeceased ? const Color(0xFFF1F5F9) : AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: isDeceased ? const Color(0xFF475569) : AppTheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Take Photo',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Use Camera',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickPhoto(ImageSource.gallery),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDeceased ? const Color(0xFFF1F5F9) : AppTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.photo_library_outlined,
                            color: isDeceased ? const Color(0xFF475569) : AppTheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Choose Gallery',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Select from Device',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildHealthConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. General Health Condition',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select the option that best describes your pet current status.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _conditionOption(
          'healthy',
          'Healthy & Active',
          'Eating well, playful, alert, and active.',
          Icons.favorite_border_rounded,
          AppTheme.successColor,
          const Color(0xFFE8F8F1),
        ),
        const SizedBox(height: 8),
        _conditionOption(
          'minor_issue',
          'Minor Issue / Observation',
          'Mild allergy, minor appetite change, or observing symptoms.',
          Icons.healing_outlined,
          AppTheme.warningColor,
          const Color(0xFFFFFBEB),
        ),
        const SizedBox(height: 8),
        _conditionOption(
          'under_treatment',
          'Under Veterinary Treatment',
          'Currently receiving medical care or taking medication.',
          Icons.medical_services_outlined,
          AppTheme.errorColor,
          const Color(0xFFFEEEEE),
        ),
      ],
    );
  }

  Widget _conditionOption(
    String key,
    String title,
    String description,
    IconData icon,
    Color accentColor,
    Color bgColor,
  ) {
    final isSelected = _healthStatus == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          _healthStatus = key;
          _notesError = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withValues(alpha: 0.15) : AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: isSelected ? accentColor : AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // ignore: deprecated_member_use
            Radio<String>(
              value: key,
              // ignore: deprecated_member_use
              groupValue: _healthStatus,
              // ignore: deprecated_member_use
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _healthStatus = val;
                    _notesError = null;
                  });
                }
              },
              activeColor: accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeceasedDetailsSection() {
    final passDateStr = _passingDate != null
        ? '${_passingDate!.year}-${_passingDate!.month.toString().padLeft(2, '0')}-${_passingDate!.day.toString().padLeft(2, '0')}'
        : 'Select Date of Passing';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. Pet Passing Details',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Please share the circumstances to help CAWS update their records respectfully.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF475569), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Submitting this report will officially notify CAWS shelter staff that ${widget.petName} has passed away and will permanently complete your monthly check-in obligations.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Date of Passing *',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickPassingDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF475569)),
                          const SizedBox(width: 10),
                          Text(
                            passDateStr,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _passingDate != null ? AppTheme.textPrimary : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Change',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Primary Cause of Passing *',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _deceasedCause,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF475569)),
                    items: _deceasedCauses.map((cause) {
                      return DropdownMenuItem<String>(
                        value: cause,
                        child: Text(
                          cause,
                          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _deceasedCause = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Attending Veterinarian or Clinic (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _clinicCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. City Vet Animal Clinic or Dr. Reyes',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF475569), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reason Why Pet Died (Explanation) *',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF87171), width: 0.8),
                    ),
                    child: Text(
                      'REQUIRED',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFDC2626),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Please explain in detail what happened to your pet (symptoms, timeline, accident, or veterinary findings) so CAWS can record it respectfully.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 5,
                onChanged: (val) {
                  if (_notesError != null) {
                    setState(() => _notesError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Describe what happened in detail (e.g. When did symptoms start? What medical care or veterinary diagnosis was given? What led to their passing?)...',
                  hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade400),
                  errorText: _notesError,
                  errorMaxLines: 3,
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _notesError != null ? AppTheme.errorColor : Colors.grey.shade300,
                      width: _notesError != null ? 1.5 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _notesError != null ? AppTheme.errorColor : const Color(0xFF475569),
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.errorColor, width: 2.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightAndNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3. Additional Details (Optional)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Weight (kg)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'e.g. 12.5',
                  suffixText: 'kg',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Observations / Notes',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share how your pet is adapting, appetite, favorite activities, or any recent vet check-ups...',
                  fillColor: const Color(0xFFF8FAFC),
                  filled: true,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSubmitBar() {
    final isDeceased = _healthStatus == 'deceased';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
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
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeceased ? const Color(0xFF475569) : AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    isDeceased
                        ? 'Submit Deceased Notification'
                        : 'Submit Monthly Health Report',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
