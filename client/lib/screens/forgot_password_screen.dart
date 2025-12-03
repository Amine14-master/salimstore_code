import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../services/forgot_password_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_page.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  String _fullPhoneNumber = '';
  bool _isLoading = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      setState(
        () => _errorMessage = 'Veuillez entrer votre numéro de téléphone',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user exists in Firebase first
      final db = FirebaseDatabase.instance;
      final userRef = db.ref('clients').child(_fullPhoneNumber);
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Ce numéro de téléphone n\'est pas associé à un compte client.';
        });
        return;
      }

      // If user exists, proceed to send OTP
      final success = await ForgotPasswordService.sendOTP(_fullPhoneNumber);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (success) {
          _otpSent = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code OTP envoyé avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          // Check if it's a rate limit error from the API
          // The smssak API has its own rate limiting that we can't bypass
          _errorMessage =
              'Erreur lors de l\'envoi du code. Veuillez vérifier le numéro ou réessayer plus tard.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Une erreur est survenue: ${e.toString()}';
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez entrer le code OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ForgotPasswordService.verifyOTP(
      _fullPhoneNumber,
      _otpController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) {
        _otpVerified = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code OTP vérifié avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        _errorMessage = 'Code OTP invalide';
      }
    });
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Les mots de passe ne correspondent pas');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      setState(
        () => _errorMessage =
            'Le mot de passe doit contenir au moins 6 caractères',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Clean phone number (remove country code and leading 0)
      String cleanPhone = _fullPhoneNumber
          .replaceFirst('+213', '')
          .replaceFirst('0', '');

      print('=== RESETTING PASSWORD ===');
      print('Phone: $_fullPhoneNumber');
      print('Clean Phone: $cleanPhone');

      // Get the user's email from the phone number (use full phone with country code)
      final userEmail = '$_fullPhoneNumber@client.salimstore.com';
      print('User Email: $userEmail');

      // Use a single FirebaseDatabase instance
      final FirebaseDatabase db = FirebaseDatabase.instance;
      final DatabaseReference clientsRef = db
          .ref('clients')
          .child(_fullPhoneNumber);

      // Try to get the current user first
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.email == userEmail) {
        // User is already authenticated, update password directly
        print('User already authenticated, updating password directly');
        await currentUser.updatePassword(_newPasswordController.text);

        // Update the password in RTDB as well for consistency
        await clientsRef.update({'updatedAt': ServerValue.timestamp});
      } else {
        // User is not authenticated with the correct account
        // We need to re-authenticate with their credentials first
        // Since this is a password reset flow after OTP verification,
        // we'll use a more secure approach

        print('User not authenticated, attempting to reset password');

        // First, try to sign in with the new password to see if the account exists
        print('Attempting to authenticate with new password');
        final signInError = await _authService.signInClient(
          phone: _fullPhoneNumber,
          password: _newPasswordController.text,
        );

        if (signInError != null) {
          // If sign in fails, the account exists but password is different
          // We use the force reset method which creates a new account version
          print('Sign in failed: $signInError');
          print('Attempting force reset with new account version...');

          final resetError = await _authService.resetPasswordWithNewAccount(
            phone: _fullPhoneNumber,
            newPassword: _newPasswordController.text,
          );

          if (resetError != null) {
            throw Exception(resetError);
          }

          print('Force reset successful, user is now authenticated');
        }

        // If sign in successful, update Firebase Auth password
        currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await currentUser.updatePassword(_newPasswordController.text);
          print('Firebase Auth password updated successfully');

          // Update the user record in RTDB
          await clientsRef.update({
            'updatedAt': ServerValue.timestamp,
            'passwordResetAt': ServerValue.timestamp,
          });
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe réinitialisé avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      // Navigate directly to home screen since user is now authenticated
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LivriYESHomePage()),
        (route) => false,
      );

      print('=== PASSWORD RESET SUCCESSFUL ===');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      print('Firebase Auth Error: ${e.code} - ${e.message}');

      String userMessage = 'Erreur lors de la réinitialisation du mot de passe';
      switch (e.code) {
        case 'requires-recent-login':
          userMessage =
              'Veuillez vous reconnecter avant de réinitialiser votre mot de passe';
          break;
        case 'weak-password':
          userMessage = 'Le nouveau mot de passe est trop faible';
          break;
        case 'user-not-found':
          userMessage =
              'Compte non trouvé. Veuillez vérifier votre numéro de téléphone';
          break;
        case 'too-many-requests':
          userMessage = 'Trop de tentatives. Veuillez réessayer plus tard';
          break;
        default:
          userMessage = 'Erreur: ${e.message}';
      }

      setState(() => _errorMessage = userMessage);
    } catch (e) {
      if (!mounted) return;
      print('Error resetting password: $e');
      setState(() => _errorMessage = 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.secondaryColor.withOpacity(0.05),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                _buildHeader(),
                const SizedBox(height: 40),
                // Form
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: AppTheme.primaryColor,
                size: 50,
              ),
            )
            .animate()
            .scale(
              duration: 600.ms,
              curve: Curves.elasticOut,
              begin: const Offset(0.8, 0.8),
            )
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 24),
        Text(
              'Réinitialiser le mot de passe',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: -0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          _otpVerified
              ? 'Entrez votre nouveau mot de passe'
              : _otpSent
              ? 'Entrez le code OTP reçu par SMS'
              : 'Entrez votre numéro de téléphone',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_otpSent) ...[
                // Phone number input
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    counterText: '',
                  ),
                  initialCountryCode: 'DZ',
                  onChanged: (phone) {
                    _fullPhoneNumber = phone.completeNumber;
                  },
                  flagsButtonPadding: const EdgeInsets.only(left: 16),
                  dropdownTextStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  style: TextStyle(fontSize: 16, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 24),
              ] else if (!_otpVerified) ...[
                // OTP input
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    labelText: 'Code OTP',
                    prefixIcon: const Icon(Icons.security_rounded),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    counterText: '',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _sendOTP,
                  child: const Text('Renvoyer le code'),
                ),
                const SizedBox(height: 12),
              ] else ...[
                // New password input
                TextField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 24),
                // Confirm password input
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                ),
                const SizedBox(height: 24),
              ],
              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Action button
              Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (!_otpSent) {
                                _sendOTP();
                              } else if (!_otpVerified) {
                                _verifyOTP();
                              } else {
                                _resetPassword();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              !_otpSent
                                  ? 'Envoyer le code OTP'
                                  : !_otpVerified
                                  ? 'Vérifier le code'
                                  : 'Réinitialiser le mot de passe',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  )
                  .animate()
                  .slideY(delay: 600.ms, begin: 0.3, end: 0, duration: 400.ms)
                  .fadeIn(delay: 600.ms),
            ],
          ),
        )
        .animate()
        .slideX(delay: 400.ms, begin: -0.2, end: 0, duration: 500.ms)
        .fadeIn(delay: 400.ms);
  }
}
