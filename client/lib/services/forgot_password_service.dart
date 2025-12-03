import 'package:smssak/smssak.dart';

class ForgotPasswordService {
  static const String projectId = 'salimstore-pbuh0';
  static const String apiKey =
      'd9bef09e96e4ebab33c742b1e99d381a:de551fc323c606c5c6f9ab99159f624ab62ba343b6b61f9d0c5cd52882cf6195e78e23fb4218bdadf88f4b41fae26e074773911bd5981bb934fc19c3d9d26ec40230cdfd093e0cc22eacb227e136d14a';

  static final OTPService _otpService = OTPService();

  /// Send OTP to phone number
  /// Returns true if OTP was sent successfully
  static Future<bool> sendOTP(String phoneNumber) async {
    try {
      // Format phone number: remove leading 0 and add country code
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

      print('=== SENDING OTP ===');
      print('Phone: $cleanPhone');
      print('Project ID: $projectId');
      print('Country: dz');

      // Use smssak library to send OTP
      // The library will generate and send the OTP automatically
      final response = await _otpService.sendOtp(
        country: 'dz',
        projectId: projectId,
        phone: cleanPhone,
        key: apiKey,
      );

      print('Response: $response');
      print('Response Type: ${response.runtimeType}');

      if (response != null) {
        print('✓ OTP sent successfully!');
        print('=== END SENDING OTP ===');
        return true;
      } else {
        print('✗ Failed to send OTP - response is null');
        print('=== END SENDING OTP ===');
        return false;
      }
    } on Exception catch (e) {
      print('✗ Exception sending OTP: $e');
      print('Exception Type: ${e.runtimeType}');

      // Check for rate limit error from API
      if (e.toString().contains('Too many OTP requests')) {
        print('API Rate Limit detected - showing user-friendly message');
        // Return false to let the UI handle the error gracefully
        print('=== END SENDING OTP ===');
        return false;
      } else if (e.toString().contains('Failed to send SMS')) {
        print('SMS sending failed - check:');
        print('1. Phone number format is correct');
        print('2. Project ID is correct');
        print('3. API key is valid');
        print('4. Account has SMS credits');
        print('5. Phone number is not blacklisted');
      }
      print('=== END SENDING OTP ===');
      return false;
    } catch (e) {
      print('✗ Unexpected error sending OTP: $e');
      print('Error Type: ${e.runtimeType}');
      print('=== END SENDING OTP ===');
      return false;
    }
  }

  /// Verify OTP code
  /// Returns true if OTP is valid
  static Future<bool> verifyOTP(String phoneNumber, String otp) async {
    try {
      // Format phone number: remove leading 0 and add country code
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

      print('=== VERIFYING OTP ===');
      print('Phone: $cleanPhone');
      print('OTP Code: $otp');

      // Use smssak library to verify OTP
      final response = await _otpService.verifyOtp(
        country: 'dz',
        projectId: projectId,
        phone: cleanPhone,
        otp: otp,
        key: apiKey,
      );

      print('Response: $response');
      print('Response Type: ${response.runtimeType}');

      if (response != null) {
        print('✓ OTP verified successfully!');
        print('=== END VERIFYING OTP ===');
        return true;
      } else {
        print('✗ Failed to verify OTP - response is null');
        print('=== END VERIFYING OTP ===');
        return false;
      }
    } on Exception catch (e) {
      print('✗ Exception verifying OTP: $e');
      print('Exception Type: ${e.runtimeType}');
      print('=== END VERIFYING OTP ===');
      return false;
    } catch (e) {
      print('✗ Unexpected error verifying OTP: $e');
      print('Error Type: ${e.runtimeType}');
      print('=== END VERIFYING OTP ===');
      return false;
    }
  }

  /// Get diagnostic information
  static void printDiagnostics() {
    print('=== SMSSAK DIAGNOSTICS ===');
    print('Project ID: $projectId');
    print('API Key Length: ${apiKey.length}');
    print('API Key (first 20 chars): ${apiKey.substring(0, 20)}...');
    print('OTPService initialized: true');
    print('=== END DIAGNOSTICS ===');
  }
}
