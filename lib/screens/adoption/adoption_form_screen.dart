import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_petadopt/screens/adoption/my_applications_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/services/phone_auth_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdoptionFormScreen extends StatefulWidget {
  final Map<String, dynamic> pet;

  const AdoptionFormScreen({super.key, required this.pet});

  @override
  State<AdoptionFormScreen> createState() => _AdoptionFormScreenState();
}

class _AdoptionFormScreenState extends State<AdoptionFormScreen> {
  int _currentStep = 0;
  final _personalFormKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _reasonController = TextEditingController();
  final _otherPetsDetailsController = TextEditingController();
  final _proposedPetNameController = TextEditingController();

  String _homeType = 'House';
  bool _hasOtherPets = false;
  bool _hasExperience = false;
  String? _adopterId;

  // ignore: unused_field
  bool _isPhoneVerified = false;
  // ignore: unused_field
  bool _isSendingOtp = false;
  String? _verificationId;
  int? _resendToken;
  // ignore: unused_field
  String _verifiedPhoneNumber = '';

  XFile? _validIdImage;
  XFile? _certificateImage;

  String? _selectedIdType;
  final List<String> _validIdTypes = [
    'Philippine National ID (PhilSys)',
    'Driver\'s License',
    'Philippine Passport',
    'UMID / SSS ID',
    'Postal ID',
    'Voter\'s ID / Certificate',
    'PhilHealth ID',
    'PRC ID',
    'Student / School ID',
    'Senior Citizen / PWD ID',
    'Other Government-Issued ID',
  ];

  String? get _petImageUrl {
    final img = widget.pet['image']?.toString() ??
        widget.pet['photo_url']?.toString() ??
        widget.pet['image_url']?.toString();
    if (img != null && img.trim().isNotEmpty && img != 'null') {
      return ApiService.normalizeImageUrl(img);
    }
    final path = widget.pet['photo_path']?.toString();
    if (path != null && path.trim().isNotEmpty && path != 'null') {
      return ApiService.normalizeImageUrl(path);
    }
    return null;
  }

  String get _petDisplayName {
    final rawName = widget.pet['name']?.toString().trim();
    if (rawName != null && rawName.isNotEmpty && rawName.toLowerCase() != 'null') {
      return rawName;
    }
    final rawNo = widget.pet['pet_no'] ?? widget.pet['id'];
    return 'Pet No. $rawNo';
  }

  bool get _isFromRecommendation {
    final appSource = widget.pet['application_source']?.toString().toLowerCase();
    if (appSource == 'recommendation') return true;
    if (widget.pet['isRecommended'] == true || widget.pet['is_recommended'] == true) return true;
    final matchPct = widget.pet['match_percentage'] ?? widget.pet['compatibility_score'];
    if (matchPct != null) {
      final numVal = num.tryParse(matchPct.toString());
      if (numVal != null && numVal > 0) return true;
    }
    return false;
  }

  num? get _compatibilityScore {
    final raw = widget.pet['match_percentage'] ?? widget.pet['compatibility_score'];
    if (raw == null) return null;
    return num.tryParse(raw.toString());
  }

  final ImagePicker _picker = ImagePicker();
  final List<String> _homeTypes = ['House', 'Apartment', 'Condo', 'Farm'];

  @override
  void initState() {
    super.initState();
    ApiService.getProfile().then((user) {
      if (user != null && (user['status'] == 'blacklisted' || user['status'] == 'restricted')) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                user['status'] == 'blacklisted'
                    ? 'Your account is banned from CAWS. You cannot submit adoption requests.'
                    : 'Your account is restricted by CAWS administration.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
    _loadUserAndAddress();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _addressController.dispose();
    _reasonController.dispose();
    _otherPetsDetailsController.dispose();
    _proposedPetNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndAddress() async {
    final user = await ApiService.getProfile();
    final userId = user != null ? user['id'] : 'guest';
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('user_${userId}_full_address') ?? (user != null ? user['address'] as String? : null);
    final phone = prefs.getString('user_${userId}_phone') ?? (user != null ? user['phone'] as String? : null);
    final secondaryPhone = prefs.getString('user_${userId}_secondary_phone');
    if (address != null && address.trim().isNotEmpty && userId != 'guest') {
      await prefs.setString('user_${userId}_full_address', address.trim());
    }
    if (phone != null && phone.trim().isNotEmpty && userId != 'guest') {
      await prefs.setString('user_${userId}_phone', phone.trim());
    }

    if (mounted) {
      setState(() {
        if (userId != null && userId != 'guest') {
          _adopterId = 'ADP-${userId.toString().padLeft(4, '0')}';
        }
        if (user != null && user['name'] != null) {
          final parts = (user['name'] as String).trim().split(RegExp(r'\s+'));
          if (parts.length == 1) {
            _firstNameController.text = parts[0];
          } else if (parts.length == 2) {
            _firstNameController.text = parts[0];
            _lastNameController.text = parts[1];
          } else if (parts.length >= 3) {
            _firstNameController.text = parts[0];
            _middleNameController.text = parts.sublist(1, parts.length - 1).join(' ');
            _lastNameController.text = parts.last;
          }
        }
        if (phone != null && phone.isNotEmpty) {
          _phoneController.text = phone;
        }
        if (secondaryPhone != null && secondaryPhone.isNotEmpty) {
          _secondaryPhoneController.text = secondaryPhone;
        }
        if (address != null && address.isNotEmpty) {
          _addressController.text = address;
        }
      });
    }
  }

  Future<void> _savePhoneNumberLocally() async {
    final phone = _phoneController.text.trim();
    final secondary = _secondaryPhoneController.text.trim();
    final user = await ApiService.getUser();
    final userId = user != null ? user['id'] : 'guest';
    final prefs = await SharedPreferences.getInstance();
    if (phone.isNotEmpty) {
      await prefs.setString('user_${userId}_phone', phone);
    }
    if (secondary.isNotEmpty) {
      await prefs.setString('user_${userId}_secondary_phone', secondary);
    } else {
      await prefs.remove('user_${userId}_secondary_phone');
    }
  }

  Future<void> _pickImage(ImageSource source, bool isValidId) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          if (isValidId) {
            _validIdImage = picked;
          } else {
            _certificateImage = picked;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showImagePickerSheet(bool isValidId) {
    if (isValidId && (_selectedIdType == null || _selectedIdType!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select your Valid ID Type first before uploading.',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    final title = isValidId ? 'Upload Valid Government ID' : 'Upload Barangay Certificate';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: Text('Take Photo with Camera', style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera, isValidId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
              title: Text('Choose from Gallery', style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery, isValidId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_personalFormKey.currentState!.validate()) return;
      _savePhoneNumberLocally();
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (_selectedIdType == null || _selectedIdType!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select your Valid ID Type',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
      if (_validIdImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please upload a photo of your Valid Government ID',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
      if (_certificateImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please upload a photo of your Barangay Certificate',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _sendPhoneOtp() async {
    final phone = _phoneController.text.trim();
    final validationError = PhoneAuthService.validatePhilippineNumber(phone);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError, style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    await PhoneAuthService.sendOtp(
      phoneNumber: phone,
      forceResendingToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() {
            _isSendingOtp = false;
            _verificationId = verificationId;
            _resendToken = resendToken;
          });
          _openOtpDialog();
        }
      },
      onAutoVerified: (credential) {
        if (mounted) {
          setState(() {
            _isSendingOtp = false;
            _isPhoneVerified = true;
            _verifiedPhoneNumber = phone;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phone number auto-verified via SMS.', style: GoogleFonts.poppins(fontSize: 13)),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      onError: (errorMessage) {
        if (mounted) {
          setState(() => _isSendingOtp = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, style: GoogleFonts.poppins(fontSize: 13)),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      onTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _openOtpDialog() {
    final otpController = TextEditingController();
    bool isVerifying = false;
    int secondsRemaining = 60;
    Timer? countdownTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
              if (secondsRemaining > 0) {
                if (modalCtx.mounted) setModalState(() => secondsRemaining--);
              } else {
                timer.cancel();
              }
            });

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 28,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sms_rounded, color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verify Phone Number',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter the 6-digit SMS code sent to\n${PhoneAuthService.formatToE164(_phoneController.text.trim())}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      hintStyle: TextStyle(letterSpacing: 8, color: Colors.grey.shade300),
                      fillColor: const Color(0xFFF6F8FA),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  isVerifying
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                      : ElevatedButton(
                          onPressed: () async {
                            final code = otpController.text.trim();
                            if (code.length != 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please enter all 6 digits', style: GoogleFonts.poppins(fontSize: 13)),
                                  backgroundColor: AppTheme.warningColor,
                                ),
                              );
                              return;
                            }
                            setModalState(() => isVerifying = true);
                            try {
                              if (_verificationId != null) {
                                await PhoneAuthService.verifyOtpCode(
                                  verificationId: _verificationId!,
                                  smsCode: code,
                                );
                                countdownTimer?.cancel();
                                if (mounted) {
                                  setState(() {
                                    _isPhoneVerified = true;
                                    _verifiedPhoneNumber = _phoneController.text.trim();
                                  });
                                }
                                if (modalCtx.mounted) Navigator.pop(modalCtx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Phone number verified successfully.', style: GoogleFonts.poppins(fontSize: 13)),
                                      backgroundColor: AppTheme.successColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              setModalState(() => isVerifying = false);
                              if (modalCtx.mounted) {
                                ScaffoldMessenger.of(modalCtx).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.poppins(fontSize: 13)),
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            'Verify Code',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        secondsRemaining > 0
                            ? 'Resend code in ${secondsRemaining}s'
                            : "Didn't receive the SMS? ",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (secondsRemaining == 0)
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(modalCtx);
                            _sendPhoneOtp();
                          },
                          child: Text(
                            'Resend',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      countdownTimer?.cancel();
    });
  }

  Future<void> _submitForm() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );

    try {
      final petId = widget.pet['id'] ?? widget.pet['pet_id'];
      final user = await ApiService.getUser();
      final userId = user != null ? user['id'] : 'guest';
      final prefs = await SharedPreferences.getInstance();
      final city = prefs.getString('user_${userId}_city') ?? '';
      final barangay = prefs.getString('user_${userId}_barangay') ?? '';

      final middle = _middleNameController.text.trim();
      final fullName = [
        _firstNameController.text.trim(),
        if (middle.isNotEmpty) middle,
        _lastNameController.text.trim(),
      ].join(' ');

      final primaryPhone = _phoneController.text.trim();
      final secondaryPhone = _secondaryPhoneController.text.trim();
      final fullContactPhone = secondaryPhone.isNotEmpty ? '$primaryPhone / $secondaryPhone' : primaryPhone;

      await _savePhoneNumberLocally();

      final isFromRec = _isFromRecommendation;
      final appSource = isFromRec ? 'recommendation' : 'manual_browsing';
      final compScore = isFromRec ? _compatibilityScore : null;

      final submitData = <String, dynamic>{
        'pet_id': petId,
        'full_name': fullName,
        'id_type': _selectedIdType,
        'phone': fullContactPhone,
        'address': _addressController.text.trim(),
        'city': city,
        'barangay': barangay,
        'home_type': _homeType,
        'has_other_pets': _hasOtherPets,
        'other_pets_details': _hasOtherPets ? _otherPetsDetailsController.text.trim() : null,
        'has_experience': _hasExperience,
        'proposed_pet_name': _proposedPetNameController.text.trim(),
        'reason': _reasonController.text.trim(),
        'application_source': appSource,
      };
      if (compScore != null) {
        submitData['compatibility_score'] = compScore;
      }

      await ApiService.submitAdoptionApplication(
        data: submitData,
        validIdPath: _validIdImage?.path,
        certificatePath: _certificateImage?.path,
      );

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.pets_rounded, color: AppTheme.primary, size: 34),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Adoption Request Submitted',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your adoption request for $_petDisplayName has been submitted! Please wait for approval as CAWS is verifying your documents and information.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.popUntil(context, ModalRoute.withName('/home'));
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppTheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Home',
                            style: GoogleFonts.poppins(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.popUntil(context, ModalRoute.withName('/home'));
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyApplicationsScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'My Applications',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEAEA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.block_rounded, color: AppTheme.errorColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Application Restricted',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              errorMsg,
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(
          'Adoption Application',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPetSummary(),
                  const SizedBox(height: 24),
                  if (_currentStep == 0) _buildStep1(),
                  if (_currentStep == 1) _buildStep2(),
                  if (_currentStep == 2) _buildStep3(),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _prevStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Back',
                              style: GoogleFonts.poppins(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _currentStep == 2 ? _submitForm : _nextStep,
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryDark, AppTheme.primary],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _currentStep == 2 ? 'Submit Application' : 'Next',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Personal Info', 'Documents', 'Lifestyle'];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorder),
        ),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isDone = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDone || isActive
                            ? AppTheme.primary
                            : AppTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone || isActive
                              ? AppTheme.primary
                              : AppTheme.cardBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: index < _currentStep
                          ? AppTheme.primary
                          : AppTheme.cardBorder,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPetSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _petImageUrl != null && _petImageUrl!.isNotEmpty
                ? Image.network(
                    _petImageUrl!,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 54,
                      height: 54,
                      color: AppTheme.primaryLight,
                      child: const Center(
                        child: Icon(Icons.pets_rounded, size: 24, color: AppTheme.primary),
                      ),
                    ),
                  )
                : Container(
                    width: 54,
                    height: 54,
                    color: AppTheme.primaryLight,
                    child: const Center(
                      child: Icon(Icons.pets_rounded, size: 24, color: AppTheme.primary),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applying for $_petDisplayName',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    if (widget.pet['breed'] != null && widget.pet['breed'].toString().isNotEmpty && widget.pet['breed'].toString().toLowerCase() != 'null') widget.pet['breed'].toString(),
                    if (widget.pet['age'] != null && widget.pet['age'].toString().isNotEmpty && widget.pet['age'].toString().toLowerCase() != 'null') widget.pet['age'].toString(),
                    if (widget.pet['gender'] != null && widget.pet['gender'].toString().isNotEmpty && widget.pet['gender'].toString().toLowerCase() != 'null') widget.pet['gender'].toString(),
                  ].join(' • '),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_isFromRecommendation) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _compatibilityScore != null
                          ? 'AI Recommended Match (${_compatibilityScore!.toInt()}%)'
                          : 'AI Recommended Match',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

  Widget _buildStep1() {
    return Form(
      key: _personalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Information',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_adopterId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'ID: $_adopterId',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reminder: Please enter your exact real full name as it appears on your Government ID for adoption verification.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF1E40AF),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    hintText: 'e.g. Juan',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: AppTheme.textSecondary, size: 20),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _middleNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Middle (Opt)',
                    hintText: 'e.g. M.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              hintText: 'e.g. Dela Cruz',
              prefixIcon: Icon(Icons.badge_outlined,
                  color: AppTheme.textSecondary, size: 20),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Please enter your last name' : null,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Primary Mobile Number *',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (_phoneController.text.isNotEmpty)
                Text(
                  'Auto-filled',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: const InputDecoration(
              labelText: 'Primary Phone (11 digits)',
              hintText: '09123456789',
              prefixIcon: Icon(Icons.phone_outlined,
                  color: AppTheme.textSecondary, size: 20),
            ),
            validator: (value) => PhoneAuthService.validatePhilippineNumber(value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _secondaryPhoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            decoration: const InputDecoration(
              labelText: 'Secondary / Backup Phone (Optional)',
              hintText: '09987654321',
              prefixIcon: Icon(Icons.phone_iphone_rounded,
                  color: AppTheme.textSecondary, size: 20),
            ),
            validator: (val) {
              if (val != null && val.trim().isNotEmpty) {
                final err = PhoneAuthService.validatePhilippineNumber(val);
                if (err != null) return err;
                if (val.trim() == _phoneController.text.trim()) {
                  return 'Must be different from primary number';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved Residence Location',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final res = await Navigator.pushNamed(context, '/edit-address');
                  if (res == true && mounted) {
                    _loadUserAndAddress();
                  }
                },
                child: Text(
                  'Change',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _addressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Complete Address',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on_outlined,
                    color: AppTheme.textSecondary, size: 20),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Please set your location' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Verification',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Please select your government ID type and upload clear photos for adoption verification.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Valid ID Type *',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedIdType,
              isExpanded: true,
              hint: Row(
                children: [
                  const Icon(Icons.credit_card_rounded, size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Choose ID Type (e.g. National ID, Driver\'s License)...',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
              items: _validIdTypes.map((String type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card_rounded, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          type,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedIdType = newValue);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildUploadBox(
          title: 'Valid Government ID',
          buttonText: 'Tap to upload Valid ID',
          icon: Icons.badge_outlined,
          image: _validIdImage,
          onTap: () => _showImagePickerSheet(true),
          onRemove: () => setState(() => _validIdImage = null),
        ),
        const SizedBox(height: 16),
        _buildUploadBox(
          title: 'Barangay Certificate',
          buttonText: 'Tap to upload Barangay Certificate',
          icon: Icons.description_outlined,
          image: _certificateImage,
          onTap: () => _showImagePickerSheet(false),
          onRemove: () => setState(() => _certificateImage = null),
        ),
      ],
    );
  }

  Widget _buildUploadBox({
    required String title,
    required String buttonText,
    required IconData icon,
    required XFile? image,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 135,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: image != null ? AppTheme.primary : AppTheme.cardBorder,
                width: image != null ? 2 : 1,
              ),
            ),
            child: image != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: kIsWeb
                            ? Image.network(image.path, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                            : Image.file(File(image.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        buttonText,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Lifestyle & Preferences',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Proposed New Name for ${widget.pet['name']} (Optional)',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _proposedPetNameController,
          decoration: const InputDecoration(
            hintText: 'e.g. Max, Milo, Bella',
            prefixIcon: Icon(
              Icons.label_outline_rounded,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Type of Home',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _homeTypes.map((type) {
            final isSelected = _homeType == type;
            return GestureDetector(
              onTap: () => setState(() => _homeType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                  ),
                ),
                child: Text(
                  type,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _toggleItem(
          'Do you have other pets at home?',
          _hasOtherPets,
          (val) => setState(() => _hasOtherPets = val),
        ),
        if (_hasOtherPets) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextFormField(
              controller: _otherPetsDetailsController,
              decoration: const InputDecoration(
                labelText: 'Details of Other Pets',
                hintText: 'e.g. 2 dogs (1 Shih Tzu, 1 Aspin), 1 Cat',
                prefixIcon: Icon(
                  Icons.pets_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              validator: (val) {
                if (_hasOtherPets && (val == null || val.trim().isEmpty)) {
                  return 'Please specify how many and what kind of pets';
                }
                return null;
              },
            ),
          ),
        ],
        const SizedBox(height: 10),
        _toggleItem(
          'Do you have experience owning pets?',
          _hasExperience,
          (val) => setState(() => _hasExperience = val),
        ),
        const SizedBox(height: 16),
        Text(
          'Why do you want to adopt $_petDisplayName?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tell us why you are the right fit...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.cardBorder),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleItem(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }
}
