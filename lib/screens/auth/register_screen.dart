import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_petadopt/services/api_service.dart';
import 'package:mobile_petadopt/services/notification_service.dart';
import 'package:mobile_petadopt/services/phone_auth_service.dart';
import 'package:mobile_petadopt/theme/app_theme.dart';
import 'package:mobile_petadopt/widgets/exploration_mode_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;

  // Step 1: Personal Information & Credentials
  final _step1FormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _noMiddleName = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Step 2: Email OTP
  final _emailOtpController = TextEditingController();
  bool _isSendingEmailOtp = false;
  bool _isVerifyingEmailOtp = false;
  int _emailTimerSeconds = 60;
  Timer? _emailTimer;

  // Step 3: Phone SMS
  final _phoneController = TextEditingController();
  final _phoneOtpController = TextEditingController();
  bool _isSendingPhoneOtp = false;
  bool _isVerifyingPhoneOtp = false;
  bool _isPhoneOtpSent = false;
  String? _phoneVerificationId;
  int? _phoneResendToken;
  int _phoneTimerSeconds = 60;
  Timer? _phoneTimer;

  // Global loading
  bool _isRegistering = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailOtpController.dispose();
    _phoneController.dispose();
    _phoneOtpController.dispose();
    _emailTimer?.cancel();
    _phoneTimer?.cancel();
    super.dispose();
  }

  String get _fullName {
    final first = _firstNameController.text.trim();
    var middle = _noMiddleName ? '' : _middleNameController.text.trim();
    final last = _lastNameController.text.trim();
    if (middle.isNotEmpty) {
      if (middle.length == 1 && RegExp(r'^[a-zA-Z]$').hasMatch(middle)) {
        middle = '${middle.toUpperCase()}.';
      } else if (middle.length == 2 && middle.endsWith('.')) {
        middle = '${middle[0].toUpperCase()}.';
      }
      return '$first $middle $last';
    }
    return '$first $last';
  }

  // --- Step 1 Action ---
  Future<void> _handleStep1Submit() async {
    if (!_step1FormKey.currentState!.validate()) return;
    final email = _emailController.text.trim();

    setState(() => _isSendingEmailOtp = true);
    try {
      await ApiService.sendEmailOtp(email);
      _startEmailTimer();
      if (mounted) {
        setState(() {
          _isSendingEmailOtp = false;
          _currentStep = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to $email!', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingEmailOtp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _startEmailTimer() {
    _emailTimer?.cancel();
    setState(() => _emailTimerSeconds = 60);
    _emailTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_emailTimerSeconds > 0) {
        if (mounted) setState(() => _emailTimerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  // --- Step 2 Action ---
  Future<void> _handleStep2Verify() async {
    final otp = _emailOtpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the complete 6-digit email code', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isVerifyingEmailOtp = true);
    try {
      await ApiService.verifyEmailOtp(
        email: _emailController.text.trim(),
        otp: otp,
      );
      if (mounted) {
        setState(() {
          _isVerifyingEmailOtp = false;
          _currentStep = 2;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email verified successfully! Now set up your mobile number.', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifyingEmailOtp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _resendEmailOtp() async {
    if (_emailTimerSeconds > 0) return;
    try {
      await ApiService.sendEmailOtp(_emailController.text.trim());
      _startEmailTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New verification code sent!', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: $e', style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // --- Step 3 Actions (Phone SMS) ---
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

    setState(() => _isSendingPhoneOtp = true);

    await PhoneAuthService.sendOtp(
      phoneNumber: phone,
      forceResendingToken: _phoneResendToken,
      onCodeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() {
            _isSendingPhoneOtp = false;
            _isPhoneOtpSent = true;
            _phoneVerificationId = verificationId;
            _phoneResendToken = resendToken;
          });
          _startPhoneTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SMS code sent to $phone!', style: GoogleFonts.poppins(fontSize: 13)),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      onAutoVerified: (credential) async {
        if (mounted) {
          setState(() => _isSendingPhoneOtp = false);
          await _completeRegistration();
        }
      },
      onError: (errorMessage) {
        if (mounted) {
          setState(() => _isSendingPhoneOtp = false);
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
        if (mounted) {
          setState(() => _phoneVerificationId = verificationId);
        }
      },
    );
  }

  void _startPhoneTimer() {
    _phoneTimer?.cancel();
    setState(() => _phoneTimerSeconds = 60);
    _phoneTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_phoneTimerSeconds > 0) {
        if (mounted) setState(() => _phoneTimerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleStep3VerifyAndRegister() async {
    final smsCode = _phoneOtpController.text.trim();
    if (smsCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the 6-digit SMS code', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_phoneVerificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please request an SMS code first', style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() => _isVerifyingPhoneOtp = true);
    try {
      await PhoneAuthService.verifyOtpCode(
        verificationId: _phoneVerificationId!,
        smsCode: smsCode,
      );
      await _completeRegistration();
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifyingPhoneOtp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _completeRegistration() async {
    setState(() => _isRegistering = true);
    try {
      final res = await ApiService.register(
        name: _fullName,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      // Save verified primary phone number in SharedPreferences for the profile
      final userId = res['user'] != null ? res['user']['id'] : null;
      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_${userId}_phone', _phoneController.text.trim());
      }

      await NotificationService.setupFirebaseFCM();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to CAWS PetAdopt, $_fullName!', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        ExplorationModeDialog.show(
          context,
          onRecommendationSelected: () {
            Navigator.pushReplacementNamed(context, '/home');
            Navigator.pushNamed(context, '/match-quiz');
          },
          onManualSelected: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRegistering = false;
          _isVerifyingPhoneOtp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', ''), style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  if (_currentStep == 0) _buildStep1(),
                  if (_currentStep == 1) _buildStep2(),
                  if (_currentStep == 2) _buildStep3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 170,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A6B72), AppTheme.primary],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(44),
              bottomRight: Radius.circular(44),
            ),
          ),
        ),
        Positioned(
          right: -40,
          top: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(
          height: 170,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep--);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.pets_rounded, color: Colors.white, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            'Adopter Registration',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Step Indicator (Matches Adoption Form) ---
  Widget _buildStepIndicator() {
    final steps = ['Credentials', 'Email OTP', 'Phone SMS'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isDone = index < _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.successColor
                            : isActive
                                ? AppTheme.primary
                                : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index],
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Container(
                  width: 28,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: index < _currentStep ? AppTheme.primary : Colors.grey.shade300,
                ),
            ],
          ),
        );
      }),
    );
  }

  // --- Step 1: Credentials & Personal Info ---
  Widget _buildStep1() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_outlined, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Personal & Account Info',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
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
                const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
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

          // First Name
          _buildTextField(
            controller: _firstNameController,
            label: 'First Name *',
            hint: 'e.g. Juan',
            icon: Icons.person_outline_rounded,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter your first name';
              if (val.trim().length < 2) return 'First name is too short';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Middle Name / Initial Input (Visible by default, hidden when toggle is ON)
          if (!_noMiddleName) ...[
            _buildTextField(
              controller: _middleNameController,
              label: 'Middle Name / Initial',
              hint: 'e.g. Santos or S.',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
          ],

          // Middle Name Toggle Switch (Clean, compact, no outer box)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "I don't have a middle name",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _noMiddleName ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: _noMiddleName ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                Transform.scale(
                  scale: 0.75,
                  child: Switch.adaptive(
                    value: _noMiddleName,
                    activeColor: AppTheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() {
                        _noMiddleName = val;
                        if (val) _middleNameController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Last Name
          _buildTextField(
            controller: _lastNameController,
            label: 'Last Name *',
            hint: 'e.g. Dela Cruz',
            icon: Icons.person_outline_rounded,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter your last name';
              if (val.trim().length < 2) return 'Last name is too short';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Email Address
          _buildTextField(
            controller: _emailController,
            label: 'Email Address *',
            hint: 'e.g. juan@gmail.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter your email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Password
          _buildTextField(
            controller: _passwordController,
            label: 'Password *',
            hint: 'At least 6 characters',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppTheme.textSecondary),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please enter a password';
              if (val.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Confirm Password
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password *',
            hint: 'Re-type your password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppTheme.textSecondary),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Please confirm your password';
              if (val != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Next Button
          _isSendingEmailOtp
              ? _loadingButton()
              : _gradientButton('Next: Verify Email →', _handleStep1Submit),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account? ", style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text('Login', style: GoogleFonts.poppins(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Step 2: Email OTP ---
  Widget _buildStep2() {
    final email = _emailController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: AppTheme.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Verify Email Address',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'We sent a 6-digit verification code to\n$email',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // OTP Code Input
        TextFormField(
          controller: _emailOtpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.poppins(fontSize: 26, letterSpacing: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            hintStyle: TextStyle(letterSpacing: 10, color: Colors.grey.shade300),
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
          ),
        ),
        const SizedBox(height: 16),

        // Resend Timer Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _emailTimerSeconds > 0 ? 'Resend code in ${_emailTimerSeconds}s' : "Didn't receive code? ",
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
            ),
            if (_emailTimerSeconds == 0)
              GestureDetector(
                onTap: _resendEmailOtp,
                child: Text('Resend Code', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Action Buttons
        _isVerifyingEmailOtp
            ? _loadingButton()
            : Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('← Back', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _gradientButton('Verify & Next →', _handleStep2Verify),
                  ),
                ],
              ),
      ],
    );
  }

  // --- Step 3: Phone SMS Verification ---
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sms_rounded, color: AppTheme.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Mobile SMS Verification',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your 11-digit Philippine mobile number to receive an SMS verification code.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Primary Phone Input
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          enabled: !_isPhoneOtpSent,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            labelText: 'Primary Mobile Number *',
            hintText: '09XXXXXXXXX',
            prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppTheme.textSecondary, size: 20),
            filled: true,
            fillColor: _isPhoneOtpSent ? Colors.grey.shade100 : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
          ),
        ),
        const SizedBox(height: 14),

        if (!_isPhoneOtpSent) ...[
          _isSendingPhoneOtp
              ? _loadingButton()
              : _gradientButton('Send SMS Code', _sendPhoneOtp),
        ] else ...[
          // SMS OTP Input
          TextFormField(
            controller: _phoneOtpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.poppins(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••••',
              hintStyle: TextStyle(letterSpacing: 8, color: Colors.grey.shade300),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isPhoneOtpSent = false;
                    _phoneOtpController.clear();
                    _phoneTimer?.cancel();
                  });
                },
                child: Text('Change Number', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
              ),
              Row(
                children: [
                  Text(
                    _phoneTimerSeconds > 0 ? 'Resend in ${_phoneTimerSeconds}s' : '',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  if (_phoneTimerSeconds == 0)
                    GestureDetector(
                      onTap: _sendPhoneOtp,
                      child: Text('Resend SMS', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          _isVerifyingPhoneOtp || _isRegistering
              ? _loadingButton()
              : _gradientButton('Complete Registration', _handleStep3VerifyAndRegister),
        ],

        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentStep = 1),
            child: Text('← Back to Email Verification', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _gradientButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
        ),
      ),
    );
  }
}
