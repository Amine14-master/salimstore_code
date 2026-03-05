import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smssak/smssak.dart';

class ForgotPasswordService {
  static const String projectId = 'livriyes-jtnhh';
  static const String apiKey =
      '161dda8c8ec1ab38878a49118739b337:72539a888193c72bd7df43ba41b9210dad306c86a3fd3af36c0986892dabc650a66d887ec7ecd4a4fffa629f45a365261777555fd53fcb2c053b067e9ffb62a65d11e922de220be7b06380bb8474e568';

  static final OTPService _otpService = OTPService();
  static String? _verificationId;
  static PhoneAuthCredential? _autoVerifiedCredential;

  /// Send OTP to phone number
  /// Returns null if OTP was sent successfully, otherwise returns error message
  static Future<String?> sendOTP(String phoneNumber) async {
    // Check if Algerian number
    bool isAlgerian = false;
    if (phoneNumber.startsWith('+213')) {
      isAlgerian = true;
    } else if (!phoneNumber.startsWith('+') &&
        (phoneNumber.startsWith('05') ||
            phoneNumber.startsWith('06') ||
            phoneNumber.startsWith('07'))) {
      isAlgerian = true;
    }

    if (isAlgerian) {
      final success = await _sendSmssakOTP(phoneNumber);
      return success ? null : 'Échec de l\'envoi du SMS via le service local.';
    } else {
      return _sendFirebaseOTP(phoneNumber);
    }
  }

  static Future<bool> _sendSmssakOTP(String phoneNumber) async {
    try {
      // Format phone number: remove leading 0 and add country code if needed
      String cleanPhone = phoneNumber;
      if (cleanPhone.startsWith('+')) {
        if (cleanPhone.startsWith('+2130')) {
          cleanPhone = cleanPhone.replaceFirst('+2130', '+213');
        }
      } else {
        if (cleanPhone.startsWith('0')) {
          cleanPhone = cleanPhone.substring(1);
        }
        cleanPhone = '+213$cleanPhone';
      }

      print('=== SENDING OTP (SMSSAK) ===');
      print('Phone: $cleanPhone');
      print('Project ID: $projectId');

      final response = await _otpService.sendOtp(
        country: 'dz',
        projectId: projectId,
        phone: cleanPhone,
        key: apiKey,
      );

      print('Response: $response');

      if (response != null) {
        print('✓ OTP sent successfully via SMSSAK!');
        return true;
      } else {
        print('✗ Failed to send OTP via SMSSAK');
        return false;
      }
    } catch (e) {
      print('✗ Exception sending OTP via SMSSAK: $e');
      return false;
    }
  }

  static Future<String?> _sendFirebaseOTP(String phoneNumber) async {
    print('=== SENDING OTP (FIREBASE) ===');
    print('Phone: $phoneNumber');

    Completer<String?> completer = Completer<String?>();
    _verificationId = null;
    _autoVerifiedCredential = null;

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          print('Firebase Auto Verification Completed');
          _autoVerifiedCredential = credential;
          if (!completer.isCompleted) completer.complete(null); // Success
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Firebase Verification Failed: ${e.code} - ${e.message}');
          if (!completer.isCompleted) {
            completer.complete(
              e.message ?? 'Erreur de vérification Firebase (${e.code})',
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Firebase Code Sent. Verification ID: $verificationId');
          _verificationId = verificationId;
          if (!completer.isCompleted) completer.complete(null); // Success
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print(
            'Firebase Auto Retrieval Timeout. Verification ID: $verificationId',
          );
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('Error initiating Firebase OTP: $e');
      return 'Erreur inattendue: ${e.toString()}';
    }

    return completer.future;
  }

  /// Verify OTP code
  /// Returns true if OTP is valid
  static Future<bool> verifyOTP(String phoneNumber, String otp) async {
    bool isAlgerian = phoneNumber.startsWith('+213');
    // Also check local format if + is missing
    if (!phoneNumber.startsWith('+') &&
        (phoneNumber.startsWith('05') ||
            phoneNumber.startsWith('06') ||
            phoneNumber.startsWith('07'))) {
      isAlgerian = true;
    }

    if (isAlgerian) {
      return _verifySmssakOTP(phoneNumber, otp);
    } else {
      return _verifyFirebaseOTP(otp);
    }
  }

  static Future<bool> _verifySmssakOTP(String phoneNumber, String otp) async {
    try {
      String cleanPhone = phoneNumber;
      if (cleanPhone.startsWith('+')) {
        if (cleanPhone.startsWith('+2130')) {
          cleanPhone = cleanPhone.replaceFirst('+2130', '+213');
        }
      } else {
        if (cleanPhone.startsWith('0')) {
          cleanPhone = cleanPhone.substring(1);
        }
        cleanPhone = '+213$cleanPhone';
      }

      print('=== VERIFYING OTP (SMSSAK) ===');

      final response = await _otpService.verifyOtp(
        country: 'dz',
        projectId: projectId,
        phone: cleanPhone,
        otp: otp,
        key: apiKey,
      );

      if (response != null) {
        print('✓ OTP verified successfully via SMSSAK!');
        return true;
      } else {
        print('✗ Failed to verify OTP via SMSSAK');
        return false;
      }
    } catch (e) {
      print('✗ Exception verifying OTP via SMSSAK: $e');
      return false;
    }
  }

  static Future<bool> _verifyFirebaseOTP(String otp) async {
    print('=== VERIFYING OTP (FIREBASE) ===');

    try {
      PhoneAuthCredential credential;

      if (_autoVerifiedCredential != null) {
        print('Using auto-verified credential');
        credential = _autoVerifiedCredential!;
      } else if (_verificationId != null) {
        print('Creating credential from verification ID and OTP');
        credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otp,
        );
      } else {
        print('No verification ID found');
        return false;
      }

      // Sign in to verify the credential is valid
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        print('✓ Firebase OTP verified successfully (User signed in)');
        // We don't want to stay signed in as the phone user,
        // as the app uses email/password auth for the main account.
        // But we need to be careful not to sign out if we were already signed in?
        // Actually, ForgotPassword flow usually starts when user is NOT signed in.
        // If they were signed in, signInWithCredential might have linked or replaced?
        // signInWithCredential signs in the user.

        // We'll sign out to clean up, as the main flow will handle sign in / password reset
        // using the email/password account.
        await FirebaseAuth.instance.signOut();
        return true;
      } else {
        print('✗ Firebase sign in failed');
        return false;
      }
    } catch (e) {
      print('✗ Exception verifying OTP via Firebase: $e');
      return false;
    }
  }

  /// Get diagnostic information
  static void printDiagnostics() {
    print('=== SMSSAK DIAGNOSTICS ===');
    print('Project ID: $projectId');
    print('API Key Length: ${apiKey.length}');
    print('=== END DIAGNOSTICS ===');
  }
}
