import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Validates Philippine mobile number format (11 digits, starts with 09)
  /// and checks for common fake patterns (e.g. repeated/sequential digits).
  static String? validatePhilippineNumber(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 11) {
      return 'Phone number must be exactly 11 digits';
    }
    if (!clean.startsWith('09')) {
      return 'Philippine mobile numbers must start with 09';
    }

    // Check for obvious troll numbers (e.g. 09111111111, 09000000000)
    final digits = clean.substring(2);
    final allSame = digits.split('').every((d) => d == digits[0]);
    if (allSame) {
      return 'Please enter a valid phone number';
    }

    // Check for sequential numbers (e.g. 09123456789)
    if (clean == '09123456789' || clean == '09987654321') {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Converts standard Philippine 09XXXXXXXXX to E.164 international format (+639XXXXXXXXX)
  static String formatToE164(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('09') && clean.length == 11) {
      return '+63${clean.substring(1)}';
    }
    if (clean.startsWith('63') && clean.length == 12) {
      return '+$clean';
    }
    if (phone.startsWith('+')) {
      return phone;
    }
    return '+63$clean';
  }

  /// Initiates SMS OTP sending via Firebase
  static Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(PhoneAuthCredential credential) onAutoVerified,
    required Function(String errorMessage) onError,
    required Function(String verificationId) onTimeout,
    int? forceResendingToken,
  }) async {
    final e164Number = formatToE164(phoneNumber);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: e164Number,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken,
        verificationCompleted: (PhoneAuthCredential credential) {
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String message = e.message ?? 'Verification failed. Please try again.';
          if (e.code == 'invalid-phone-number') {
            message = 'The provided phone number is invalid.';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many requests. Please wait a few minutes before trying again.';
          } else if (e.code == 'quota-exceeded') {
            message = 'SMS quota exceeded for today. Please try again later.';
          }
          onError(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          onTimeout(verificationId);
        },
      );
    } catch (e) {
      onError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Verifies the entered 6-digit OTP code with Firebase
  static Future<bool> verifyOtpCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user != null;
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-verification-code') {
          throw Exception('The code you entered is incorrect. Please check and try again.');
        } else if (e.code == 'session-expired') {
          throw Exception('Verification code has expired. Please request a new code.');
        }
      }
      throw Exception('Verification failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}
