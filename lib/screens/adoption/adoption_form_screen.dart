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
import 'package:mobile_petadopt/widgets/app_confirmation_dialog.dart';
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
  final _landlordNameController = TextEditingController();
  final _landlordPhoneController = TextEditingController();

  String? _homeType;
  String? _homeOwnership;
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

    String? resolvedHomeType;
    bool? resolvedHasOtherPets;
    bool? resolvedHasExperience;

    if (prefill != null) {
      final rawLiving = (prefill['living_environment'] ?? prefill['home_type'])?.toString().toLowerCase() ?? '';
      if (rawLiving.contains('apartment')) {
        resolvedHomeType = 'Apartment';
      } else if (rawLiving.contains('condo')) {
        resolvedHomeType = 'Condo';
      } else if (rawLiving.contains('house')) {
        resolvedHomeType = 'House';
      } else if (rawLiving.contains('farm')) {
        resolvedHomeType = 'Farm';
      } else if (_homeTypes.contains(prefill['home_type'])) {
        resolvedHomeType = prefill['home_type'].toString();
      }

      if (prefill['has_other_pets'] != null) {
        resolvedHasOtherPets = prefill['has_other_pets'] is bool
            ? prefill['has_other_pets'] as bool
            : prefill['has_other_pets'].toString() == '1' || prefill['has_other_pets'].toString() == 'true';
      }

      if (prefill['has_experience'] != null) {
        resolvedHasExperience = prefill['has_experience'] is bool
            ? prefill['has_experience'] as bool
            : ['1', 'true', 'yes', 'experienced'].contains(prefill['has_experience'].toString().toLowerCase().trim()) ||
                prefill['has_experience'].toString().toLowerCase().contains('experienc');
      } else if (prefill['pet_experience'] != null) {
        final expStr = prefill['pet_experience'].toString().toLowerCase().trim();
        resolvedHasExperience = expStr == 'experienced' || expStr.contains('experienc') || expStr == 'yes' || expStr == 'true';
      }
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

        if (resolvedHomeType != null && _homeType == null) {
          _homeType = resolvedHomeType;
        }
        if (prefill != null && prefill['home_ownership'] != null) {
          final own = prefill['home_ownership'].toString().toLowerCase().trim();
          if (own == 'rented' || own == 'rent') {
            _homeOwnership = 'rented';
          } else if (own == 'owned' || own == 'own') {
            _homeOwnership = 'owned';
          }
        }
        if (prefill != null && prefill['landlord_name'] != null && prefill['landlord_name'].toString().isNotEmpty) {
          _landlordNameController.text = prefill['landlord_name'].toString();
        }
        if (prefill != null && prefill['landlord_phone'] != null && prefill['landlord_phone'].toString().isNotEmpty) {
          _landlordPhoneController.text = prefill['landlord_phone'].toString();
        }
        if (resolvedHasOtherPets != null) {
          _hasOtherPets = resolvedHasOtherPets;
        }
        if (resolvedHasExperience != null) {
          _hasExperience = resolvedHasExperience;
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
    if (_homeType == null || _homeType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select your Type of Home',
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

    if (_homeOwnership == null || _homeOwnership!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select whether you own or rent your home',
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

    if (_homeOwnership == 'rented') {
      if (_landlordNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please provide your landlord or building administrator name',
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
      if (_landlordPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please provide your landlord or building contact phone number',
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
        'home_type': _homeType,
        'home_ownership': _homeOwnership,
        'landlord_name': _homeOwnership == 'rented' ? _landlordNameController.text.trim() : null,
        'landlord_phone': _homeOwnership == 'rented' ? _landlordPhoneController.text.trim() : null,
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
        AppConfirmationDialog.show(
          context,
          barrierDismissible: false,
          icon: Icons.pets_rounded,
          iconColor: AppTheme.primary,
          iconBackgroundColor: AppTheme.primaryLight,
          title: 'Adoption Request Submitted',
          message:
              'Your adoption request for $_petDisplayName has been submitted! Please wait for approval as CAWS is verifying your documents and information.',
          cancelText: 'Home',
          confirmText: 'My Applications',
          onCancel: () {
            Navigator.popUntil(context, ModalRoute.withName('/home'));
          },
          onConfirm: () {
            Navigator.popUntil(context, ModalRoute.withName('/home'));
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text(
          'Adoption Application',
          style: GoogleFonts.poppins(
            fontSize: 16.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
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
                  if (_currentStep == 2) _buildStep3(),
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
    const stepTitles = [
      'Personal Information',
      'Document Verification',
      'Lifestyle & Housing',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
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
                          color: AppTheme.primaryLight,
                          child: const Icon(Icons.pets_rounded, size: 18, color: AppTheme.primary),
                        ),
                      )
                    : Container(
                        width: 36,
                        height: 36,
                        color: AppTheme.primaryLight,
                        child: const Icon(Icons.pets_rounded, size: 18, color: AppTheme.primary),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applying for $_petDisplayName',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Step ${_currentStep + 1} of 3 • ${stepTitles[_currentStep]}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
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
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${_compatibilityScore!.toInt()}% Match',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (index) {
              final isDoneOrActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 3.5,
                  margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isDoneOrActive ? AppTheme.primary : AppTheme.cardBorder,
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

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardContainer({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
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
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: AppTheme.textSecondary,
      ),
      hintStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: AppTheme.textSecondary.withValues(alpha: 0.6),
      ),
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: AppTheme.textSecondary)
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  Widget _buildSegmentedSelector<T>({
    required List<T> options,
    required T? selected,
    required String Function(T) getLabel,
    required ValueChanged<T> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = selected == opt;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  getLabel(opt),
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
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
              _buildSectionHeader('Applicant Identity', subtitle: 'Must match your valid government ID'),
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
          _buildCardContainer(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _firstNameController,
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
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Document Verification', subtitle: 'Upload photos of your ID and barangay residency certificate'),
        const SizedBox(height: 12),
        _buildCardContainer(
          children: [
            Text(
              'Valid Government ID Type *',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedIdType,
                  isExpanded: true,
                  hint: Text(
                    'Select government ID type...',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary, size: 20),
                  items: _validIdTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 125,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: image != null ? AppTheme.primary : AppTheme.cardBorder,
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
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryLight,
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
        _buildSectionHeader('Residence & Housing', subtitle: 'Helps match pet size and shelter home policies'),
        const SizedBox(height: 10),
        _buildCardContainer(
          children: [
            Text(
              'Type of Home *',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildSegmentedSelector<String>(
              options: _homeTypes,
              selected: _homeType,
              getLabel: (t) => t,
              onSelected: (val) => setState(() => _homeType = val),
            ),
            const SizedBox(height: 14),
            Text(
              'Home Ownership *',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please prepare a written Landlord Consent Letter (or lease agreement copy) to bring to your meet-and-greet screening.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _landlordNameController,
                      decoration: _minimalInputDecoration(
                        label: 'Landlord / Admin Name *',
                        hint: 'e.g. Maria Santos',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (val) {
                        if (_homeOwnership == 'rented' && (val == null || val.trim().isEmpty)) {
                          return 'Please enter landlord name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _landlordPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _minimalInputDecoration(
                        label: 'Landlord Contact Phone *',
                        hint: 'e.g. 0917 123 4567',
                        icon: Icons.phone_outlined,
                      ),
                      validator: (val) {
                        if (_homeOwnership == 'rented' && (val == null || val.trim().isEmpty)) {
                          return 'Please enter landlord contact number';
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
        _buildSectionHeader('Household & Experience', subtitle: 'Your pet background and current environment'),
        const SizedBox(height: 10),
        _buildCardContainer(
          children: [
            _buildChoiceCardGroup(
              title: 'Other Pets at Home *',
              selectedValue: _hasOtherPets,
              onChanged: (val) => setState(() => _hasOtherPets = val),
              firstTitle: 'No Other Pets',
              firstSubtitle: 'First or solo pet',
              firstIcon: Icons.home_outlined,
              secondTitle: 'Yes, Have Pets',
              secondSubtitle: 'Dogs, cats, etc.',
              secondIcon: Icons.pets_rounded,
            ),
            if (_hasOtherPets) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _otherPetsDetailsController,
                decoration: _minimalInputDecoration(
                  label: 'Details of Other Pets *',
                  hint: 'e.g. 1 Aspin dog, 1 Persian cat',
                  icon: Icons.pets_rounded,
                ),
                validator: (val) {
                  if (_hasOtherPets && (val == null || val.trim().isEmpty)) {
                    return 'Please specify other pets';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            _buildChoiceCardGroup(
              title: 'Pet Care Experience *',
              selectedValue: _hasExperience,
              onChanged: (val) => setState(() => _hasExperience = val),
              firstTitle: 'First-time Owner',
              firstSubtitle: 'New to pet parenting',
              firstIcon: Icons.favorite_border_rounded,
              secondTitle: 'Experienced Owner',
              secondSubtitle: 'Cared for pets before',
              secondIcon: Icons.verified_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildSectionHeader('Adoption Intent', subtitle: 'Proposed pet name and message for CAWS shelter'),
        const SizedBox(height: 10),
        _buildCardContainer(
          children: [
            TextFormField(
              controller: _proposedPetNameController,
              decoration: _minimalInputDecoration(
                label: 'Proposed Pet Name (Optional)',
                hint: 'e.g. Max, Milo, Bella',
                icon: Icons.label_outline_rounded,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: _minimalInputDecoration(
                label: 'Why do you want to adopt $_petDisplayName?',
                hint: 'Tell us why you are the right fit...',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChoiceCardGroup({
    required String title,
    required bool selectedValue,
    required ValueChanged<bool> onChanged,
    required String firstTitle,
    required String firstSubtitle,
    required IconData firstIcon,
    required String secondTitle,
    required String secondSubtitle,
    required IconData secondIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInteractiveChoiceCard(
                isSelected: !selectedValue,
                onTap: () => onChanged(false),
                title: firstTitle,
                subtitle: firstSubtitle,
                icon: firstIcon,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInteractiveChoiceCard(
                isSelected: selectedValue,
                onTap: () => onChanged(true),
                title: secondTitle,
                subtitle: secondSubtitle,
                icon: secondIcon,
              ),
            ),
          ],
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(11),
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight.withValues(alpha: 0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.08),
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
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 15,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                      width: isSelected ? 4.5 : 1.5,
                    ),
                    color: Colors.white,
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
                    color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
                    height: 1.25,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
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
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white,
              ),
              child: Text(
                'Back',
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
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
            onPressed: _currentStep == 2 ? _submitForm : _nextStep,
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
              _currentStep == 2 ? 'Submit Application' : 'Continue',
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
