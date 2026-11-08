import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_petadopt/screens/adoption/my_applications_screen.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/services/phone_auth_service.dart';
import 'package:mobile_petadopt/widgets/connectivity_banner.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/app_confirmation_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdoptionFormScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  final List<Map<String, dynamic>>? selectedPets;

  const AdoptionFormScreen({
    super.key,
    required this.pet,
    this.selectedPets,
  });

  @override
  State<AdoptionFormScreen> createState() => _AdoptionFormScreenState();
}

class _AdoptionFormScreenState extends State<AdoptionFormScreen> {
  List<Map<String, dynamic>> get _effectiveSelectedPets {
    if (widget.selectedPets != null && widget.selectedPets!.isNotEmpty) {
      return widget.selectedPets!;
    }
    return [widget.pet];
  }

  int _currentStep = 0;
  final _personalFormKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _proposedPetNameController = TextEditingController();
  final _landlordNameController = TextEditingController();
  final _landlordPhoneController = TextEditingController();

  String _homeOwnership = 'owned';
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
    _proposedPetNameController.dispose();
    _landlordNameController.dispose();
    _landlordPhoneController.dispose();
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

    // Fetch prefill data from adoption API or saved quiz preferences
    final petId = widget.pet['id'] != null ? int.tryParse(widget.pet['id'].toString()) : null;
    Map<String, dynamic>? prefill = await ApiService.getAdoptionPrefillData(petId);
    if (prefill == null) {
      final savedPrefs = await ApiService.getSavedPreferences();
      if (savedPrefs != null) {
        prefill = savedPrefs;
      }
    }

    // Housing & lifestyle answers are safely preserved in the adopter's Compatibility Quiz profile

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
        } else if (prefill != null && prefill['phone'] != null && prefill['phone'].toString().isNotEmpty) {
          _phoneController.text = prefill['phone'].toString();
        }
        if (secondaryPhone != null && secondaryPhone.isNotEmpty) {
          _secondaryPhoneController.text = secondaryPhone;
        }
        if (address != null && address.isNotEmpty) {
          _addressController.text = address;
        } else if (prefill != null && prefill['address'] != null && prefill['address'].toString().isNotEmpty) {
          _addressController.text = prefill['address'].toString();
        }

        if (prefill != null && prefill['home_ownership'] != null) {
          final own = prefill['home_ownership'].toString().toLowerCase().trim();
          if (own == 'rented' || own == 'rent' || own == 'tenant') {
            _homeOwnership = 'rented';
          } else if (own == 'owned' || own == 'own' || own == 'owner') {
            _homeOwnership = 'owned';
          }
        }
        if (prefill != null && prefill['landlord_name'] != null && prefill['landlord_name'].toString().isNotEmpty) {
          _landlordNameController.text = prefill['landlord_name'].toString();
        }
        if (prefill != null && prefill['landlord_phone'] != null && prefill['landlord_phone'].toString().isNotEmpty) {
          _landlordPhoneController.text = prefill['landlord_phone'].toString();
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
    final isDark = AppTheme.isDark(context);
    final title = isValidId ? 'Upload Valid Government ID' : 'Upload Barangay Certificate';
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                color: AppTheme.getTextPrimary(ctx),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
              title: Text('Take Photo with Camera', style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.getTextPrimary(ctx))),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera, isValidId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
              title: Text('Choose from Gallery', style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.getTextPrimary(ctx))),
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
      _submitForm();
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
    final isDark = AppTheme.isDark(context);
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
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primaryLight,
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
                      color: AppTheme.getTextPrimary(modalCtx),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter the 6-digit SMS code sent to\n${PhoneAuthService.formatToE164(_phoneController.text.trim())}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.getTextSecondary(modalCtx),
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
                      color: isDark ? const Color(0xFF5EEAD4) : AppTheme.primaryDark,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                      hintStyle: TextStyle(letterSpacing: 8, color: isDark ? const Color(0xFF475569) : Colors.grey.shade300),
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FA),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
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
                                    content: Text(ApiClient.formatUserErrorMessage(e), style: GoogleFonts.poppins(fontSize: 13)),
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
    if (_selectedIdType == null || _selectedIdType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a valid Government ID type',
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
            'Please upload the front of your valid ID',
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
            'Please upload your Barangay Certificate of Residency',
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

      const appSource = 'recommendation';
      final compScore = _compatibilityScore;

      final submitData = <String, dynamic>{
        'pet_id': petId,
        'full_name': fullName,
        'id_type': _selectedIdType,
        'phone': fullContactPhone,
        'address': _addressController.text.trim(),
        'city': city,
        'barangay': barangay,
        'home_ownership': _homeOwnership,
        'landlord_name': _homeOwnership == 'rented' ? _landlordNameController.text.trim() : null,
        'landlord_phone': _homeOwnership == 'rented' ? _landlordPhoneController.text.trim() : null,
        'proposed_pet_name': _proposedPetNameController.text.trim(),
        'application_source': appSource,
      };
      if (compScore != null) {
        submitData['compatibility_score'] = compScore;
      }

      if (_effectiveSelectedPets.length > 1) {
        final petIds = _effectiveSelectedPets
            .map((p) => p['pet_id'] ?? p['id'])
            .where((id) => id != null)
            .toList();
        submitData['pet_ids'] = jsonEncode(petIds);

        final scoresMap = <String, dynamic>{};
        for (final p in _effectiveSelectedPets) {
          final pid = (p['pet_id'] ?? p['id'])?.toString();
          final rawSc = p['match_percentage'] ?? p['compatibility_score'];
          if (pid != null && rawSc != null) {
            scoresMap[pid] = rawSc;
          }
        }
        if (scoresMap.isNotEmpty) {
          submitData['compatibility_scores'] = jsonEncode(scoresMap);
        }
      }

      await ApiService.submitAdoptionApplication(
        data: submitData,
        validIdPath: _validIdImage?.path,
        certificatePath: _certificateImage?.path,
      );

      if (mounted) {
        Navigator.pop(context);
        AppConfirmationDialog.show(
          context,
          barrierDismissible: false,
          icon: Icons.pets_rounded,
          iconColor: AppTheme.primary,
          iconBackgroundColor: AppTheme.primaryLight,
          title: _effectiveSelectedPets.length > 1
              ? 'Adoption Applications Submitted'
              : 'Adoption Request Submitted',
          message: _effectiveSelectedPets.length > 1
              ? 'Your adoption applications for ${_effectiveSelectedPets.map((p) => p['name'] ?? 'Pet').join(', ')} have been submitted! Please wait for approval as CAWS is verifying your documents.'
              : 'Your adoption request for $_petDisplayName has been submitted! Please wait for approval as CAWS is verifying your documents and information.',
          cancelText: 'Home',
          confirmText: 'My Applications',
          onCancel: () {
            Navigator.popUntil(context, ModalRoute.withName('/home'));
          },
          onConfirm: () {
            Navigator.popUntil(context, ModalRoute.withName('/home'));
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyApplicationsScreen(initialFilter: 'all')),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        if (ApiClient.isNetworkError(e)) {
          NetworkErrorHelper.showConnectionLostDialog(
            context,
            title: 'Connection Lost',
            message:
                'Unable to submit your adoption application because the server could not be reached. Please check your internet connection and tap Retry.',
            onRetry: () => _submitForm(),
          );
          return;
        }
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        AppConfirmationDialog.show(
          context,
          icon: Icons.block_rounded,
          iconColor: AppTheme.errorColor,
          iconBackgroundColor: const Color(0xFFFFEAEA),
          title: 'Application Restricted',
          message: errorMsg,
          confirmText: 'Understood',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(context),
        foregroundColor: AppTheme.getTextPrimary(context),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.getTextPrimary(context)),
        ),
        title: Text(
          'Adoption Application',
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimary(context),
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          _buildCompactHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentStep == 0) _buildStep1(),
                  if (_currentStep == 1) _buildStep2(),
                  const SizedBox(height: 28),
                  _buildBottomNavButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    final isDark = AppTheme.isDark(context);
    const stepTitles = [
      'Applicant Details',
      'Document Verification',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.getCardBorder(context), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _petImageUrl != null && _petImageUrl!.isNotEmpty
                    ? Image.network(
                        _petImageUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 36,
                          height: 36,
                          color: isDark ? const Color(0xFF1E293B) : AppTheme.primaryLight,
                          child: const Icon(Icons.pets_rounded, size: 18, color: AppTheme.primary),
                        ),
                      )
                    : Container(
                        width: 36,
                        height: 36,
                        color: isDark ? const Color(0xFF1E293B) : AppTheme.primaryLight,
                        child: const Icon(Icons.pets_rounded, size: 18, color: AppTheme.primary),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _effectiveSelectedPets.length > 1
                          ? 'Applying for ${_effectiveSelectedPets.length} Companions'
                          : 'Applying for $_petDisplayName',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextPrimary(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Step ${_currentStep + 1} of 2 • ${stepTitles[_currentStep]}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.getTextSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isFromRecommendation && _compatibilityScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF0E7A80).withValues(alpha: 0.5) : AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${_compatibilityScore!.truncateToDouble() == _compatibilityScore! ? _compatibilityScore!.toInt() : _compatibilityScore!.toStringAsFixed(1)}% Match',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF5EEAD4) : AppTheme.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(2, (index) {
              final isDoneOrActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 3.5,
                  margin: EdgeInsets.only(right: index < 1 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isDoneOrActive ? AppTheme.primary : (isDark ? const Color(0xFF334155) : AppTheme.cardBorder),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle, bool isRequired = false}) {
    final hasAsterisk = title.endsWith('*') || isRequired;
    final cleanTitle = title.endsWith(' *')
        ? title.substring(0, title.length - 2)
        : (title.endsWith('*') ? title.substring(0, title.length - 1) : title);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: cleanTitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.getTextPrimary(context),
            ),
            children: hasAsterisk
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]
                : const [],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.getTextSecondary(context),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardContainer({required List<Widget> children}) {
    final isDark = AppTheme.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.getCardBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  InputDecoration _minimalInputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    bool isRequired = false,
  }) {
    final isDark = AppTheme.isDark(context);
    final hasAsterisk = label.endsWith('*') || isRequired;
    final cleanLabel = label.endsWith(' *')
        ? label.substring(0, label.length - 2)
        : (label.endsWith('*') ? label.substring(0, label.length - 1) : label);

    return InputDecoration(
      label: Text.rich(
        TextSpan(
          text: cleanLabel,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.getTextSecondary(context),
          ),
          children: hasAsterisk
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              : const [],
        ),
      ),
      hintText: hint,
      alignLabelWithHint: true,
      hintStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: AppTheme.getTextSecondary(context).withValues(alpha: 0.6),
      ),
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: AppTheme.getTextSecondary(context))
          : null,
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.getCardBorder(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.getCardBorder(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  Widget _buildSelectedPetsSummaryCard() {
    if (_effectiveSelectedPets.length <= 1) return const SizedBox.shrink();
    final isDark = AppTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132D30) : AppTheme.primaryLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF0E7A80).withValues(alpha: 0.5) : AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pets_rounded, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Applying for ${_effectiveSelectedPets.length} Companions (Unified Form)',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF5EEAD4) : AppTheme.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Your identity documents and verified profile information will be automatically attached to each companion application.',
            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.getTextSecondary(context)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _effectiveSelectedPets.map((p) {
              final name = p['name']?.toString() ?? 'Pet';
              final score = p['match_percentage'] ?? p['compatibility_score'];
              return Chip(
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                avatar: CircleAvatar(
                  backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.primaryLight,
                  child: const Icon(Icons.pets, size: 12, color: AppTheme.primary),
                ),
                label: Text(
                  score != null ? '$name ($score%)' : name,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context),
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.getCardBorder(context)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final isDark = AppTheme.isDark(context);
    return Form(
      key: _personalFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectedPetsSummaryCard(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('Applicant Identity', subtitle: 'Must match your valid government ID'),
              if (_adopterId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? const Color(0xFF0E7A80).withValues(alpha: 0.5) : AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'ID: $_adopterId',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF5EEAD4) : AppTheme.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCardContainer(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _firstNameController,
                      style: GoogleFonts.poppins(color: AppTheme.getTextPrimary(context), fontSize: 13),
                      textCapitalization: TextCapitalization.words,
                      decoration: _minimalInputDecoration(
                        label: 'First Name *',
                        hint: 'e.g. Juan',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _middleNameController,
                      style: GoogleFonts.poppins(color: AppTheme.getTextPrimary(context), fontSize: 13),
                      textCapitalization: TextCapitalization.words,
                      decoration: _minimalInputDecoration(
                        label: 'Middle',
                        hint: 'Optional',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _lastNameController,
                style: GoogleFonts.poppins(color: AppTheme.getTextPrimary(context), fontSize: 13),
                textCapitalization: TextCapitalization.words,
                decoration: _minimalInputDecoration(
                  label: 'Last Name *',
                  hint: 'e.g. Dela Cruz',
                  icon: Icons.badge_outlined,
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Please enter your last name' : null,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSectionHeader('Contact & Residence', subtitle: 'For shelter notifications and home verification'),
          const SizedBox(height: 10),
          _buildCardContainer(
            children: [
              TextFormField(
                controller: _phoneController,
                style: GoogleFonts.poppins(color: AppTheme.getTextPrimary(context), fontSize: 13),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: _minimalInputDecoration(
                  label: 'Primary Phone (11 digits) *',
                  hint: '09123456789',
                  icon: Icons.phone_outlined,
                ),
                validator: (value) => PhoneAuthService.validatePhilippineNumber(value),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _secondaryPhoneController,
                style: GoogleFonts.poppins(color: AppTheme.getTextPrimary(context), fontSize: 13),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: _minimalInputDecoration(
                  label: 'Secondary Phone (Optional)',
                  hint: '09987654321',
                  icon: Icons.phone_iphone_rounded,
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
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                style: GoogleFonts.poppins(color: AppTheme.getTextPrimary(context), fontSize: 13),
                maxLines: 2,
                decoration: _minimalInputDecoration(
                  label: 'Complete Address *',
                  hint: 'Street, Barangay, City, Province',
                  icon: Icons.location_on_outlined,
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Please enter your address' : null,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSectionHeader('Residence Ownership *', subtitle: 'Shelter tenancy verification policy'),
          const SizedBox(height: 10),
          _buildCardContainer(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInteractiveChoiceCard(
                      isSelected: _homeOwnership == 'owned',
                      onTap: () => setState(() => _homeOwnership = 'owned'),
                      title: 'Own Property',
                      subtitle: 'Owner / family home',
                      icon: Icons.home_work_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInteractiveChoiceCard(
                      isSelected: _homeOwnership == 'rented',
                      onTap: () => setState(() => _homeOwnership = 'rented'),
                      title: 'Renting / Tenant',
                      subtitle: 'Leased unit or rental',
                      icon: Icons.apartment_outlined,
                    ),
                  ),
                ],
              ),
              if (_homeOwnership == 'rented') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.getCardBorder(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Landlord or Building Admin Info',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getTextPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _landlordNameController,
                        style: GoogleFonts.poppins(color: AppTheme.getTextPrimary(context), fontSize: 13),
                        textCapitalization: TextCapitalization.words,
                        decoration: _minimalInputDecoration(
                          label: 'Landlord / Admin Name *',
                          hint: 'e.g. Maria Santos',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _landlordPhoneController,
                        style: GoogleFonts.poppins(color: AppTheme.getTextPrimary(context), fontSize: 13),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: _minimalInputDecoration(
                          label: 'Landlord Contact Phone (11 digits) *',
                          hint: '09123456789',
                          icon: Icons.phone_outlined,
                        ),
                        validator: (value) {
                          if (_homeOwnership == 'rented') {
                            return PhoneAuthService.validatePhilippineNumber(value);
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          _buildSectionHeader('Adoption Details', subtitle: 'Proposed pet name for shelter records (Optional)'),
          const SizedBox(height: 10),
          _buildCardContainer(
            children: [
              TextFormField(
                controller: _proposedPetNameController,
                style: GoogleFonts.poppins(color: AppTheme.getTextPrimary(context), fontSize: 13),
                decoration: _minimalInputDecoration(
                  label: 'Proposed Pet Name (Optional)',
                  hint: 'e.g. Max, Milo, Bella',
                  icon: Icons.label_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Compatibility Quiz Connected: Your living space, schedule, other pets, and experience from your quiz will be attached automatically.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF166534),
                      height: 1.35,
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

  Widget _buildStep2() {
    final isDark = AppTheme.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Document Verification', subtitle: 'Upload photos of your ID and barangay residency certificate'),
        const SizedBox(height: 12),
        _buildCardContainer(
          children: [
            Text.rich(
              TextSpan(
                text: 'Valid Government ID Type',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextPrimary(context),
                ),
                children: const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.getCardBorder(context)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  value: _selectedIdType,
                  isExpanded: true,
                  hint: Text(
                    'Select government ID type...',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.getTextSecondary(context)),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary, size: 20),
                  items: _validIdTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppTheme.getTextPrimary(context)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedIdType = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildUploadBox(
              title: 'Photo of Valid Government ID',
              buttonText: 'Tap to upload Valid ID',
              icon: Icons.badge_outlined,
              image: _validIdImage,
              onTap: () => _showImagePickerSheet(true),
              onRemove: () => setState(() => _validIdImage = null),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCardContainer(
          children: [
            _buildUploadBox(
              title: 'Barangay Certificate of Residency',
              buttonText: 'Tap to upload Barangay Certificate',
              icon: Icons.description_outlined,
              image: _certificateImage,
              onTap: () => _showImagePickerSheet(false),
              onRemove: () => setState(() => _certificateImage = null),
            ),
          ],
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
    bool isRequired = true,
  }) {
    final isDark = AppTheme.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: title,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextPrimary(context),
            ),
            children: isRequired
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                : const [],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 125,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: image != null ? AppTheme.primary : AppTheme.getCardBorder(context),
                width: image != null ? 1.5 : 1,
              ),
            ),
            child: image != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
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
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        buttonText,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF5EEAD4) : AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveChoiceCard({
    required bool isSelected,
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isDark = AppTheme.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(11),
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppTheme.primary.withValues(alpha: 0.25) : AppTheme.primaryLight.withValues(alpha: 0.5))
              : (isDark ? const Color(0xFF0F172A) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.getCardBorder(context),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : (isDark ? const Color(0xFF1E293B) : AppTheme.surface),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 15,
                    color: isSelected ? Colors.white : AppTheme.getTextSecondary(context),
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.getCardBorder(context),
                      width: isSelected ? 4.5 : 1.5,
                    ),
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? (isDark ? const Color(0xFF5EEAD4) : AppTheme.primaryDark)
                        : AppTheme.getTextPrimary(context),
                    height: 1.25,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.getTextSecondary(context),
                    height: 1.25,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavButtons() {
    final isDark = AppTheme.isDark(context);
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppTheme.getCardBorder(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              ),
              child: Text(
                'Back',
                style: GoogleFonts.poppins(
                  color: AppTheme.getTextPrimary(context),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _currentStep == 1 ? _submitForm : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentStep == 1 ? 'Submit Application' : 'Continue to Documents',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
