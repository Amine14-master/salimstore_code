import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

class ClientAuthScreen extends StatefulWidget {
  const ClientAuthScreen({super.key});

  @override
  State<ClientAuthScreen> createState() => _ClientAuthScreenState();
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.currentLocale,
    required this.onChanged,
  });

  final Locale currentLocale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isFrench = currentLocale.languageCode == 'fr';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.12),
            AppTheme.accentColor.withOpacity(0.12),
          ],
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Lottie.asset(
              'lib/assets/animations/language_switch.json',
              repeat: true,
              fit: BoxFit.contain,
              onLoaded: (composition) {},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: AppTheme.primaryColor,
                  highlightColor: Colors.white,
                  child: Text(
                    l10n.authLanguageLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.authLanguageSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  _LanguageChip(
                    label: 'EN',
                    selected: !isFrench,
                    onTap: () => onChanged(const Locale('en')),
                  ),
                  const SizedBox(width: 8),
                  _LanguageChip(
                    label: 'FR',
                    selected: isFrench,
                    onTap: () => onChanged(const Locale('fr')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? AppTheme.primaryGradient
              : const LinearGradient(
                  colors: [Colors.transparent, Colors.transparent],
                ),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppTheme.primaryColor.withOpacity(0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ClientAuthScreenState extends State<ClientAuthScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Phone number
  String _fullPhoneNumber = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final l10n = context.l10n;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? error;

    if (_isSignUp) {
      error = await _authService.signUpClient(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _fullPhoneNumber,
        password: _passwordController.text,
      );
    } else {
      error = await _authService.signInClient(
        phone: _fullPhoneNumber,
        password: _passwordController.text,
      );
    }

    setState(() => _isLoading = false);

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSignUp ? l10n.authSuccessSignUp : l10n.authSuccessSignIn,
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
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
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildAuthForm(),
                const SizedBox(height: 30),
                _buildToggleAuth(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = context.l10n;
    final localeController = context.localeController;
    final currentLocale = localeController.locale;

    return Column(
      children: [
        // Logo with beautiful container
        Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'lib/assets/images/store_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 50,
                      ),
                    );
                  },
                ),
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
              l10n.appTitle,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: -0.2, end: 0),
        const SizedBox(height: 8),
        Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isSignUp ? l10n.authChipRegister : l10n.authChipLogin,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms)
            .scale(begin: const Offset(0.9, 0.9)),
        const SizedBox(height: 24),
        _LanguageSelector(
          currentLocale: currentLocale,
          onChanged: (locale) async {
            await localeController.updateLocale(locale);
            if (!mounted) return;
            final selectedName = locale.languageCode == 'fr'
                ? l10n.authLanguageFrench
                : l10n.authLanguageEnglish;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.authLanguageChangedMessage(selectedName)),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAuthForm() {
    final l10n = context.l10n;

    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isSignUp) ...[
                    _buildTextField(
                      controller: _nameController,
                      label: l10n.authNameLabel,
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.authNameEmpty;
                        }
                        if (value.trim().length < 2) {
                          return l10n.authNameShort;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _emailController,
                      label: l10n.authEmailLabel,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.authEmailEmpty;
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return l10n.authEmailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildPhoneField(),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _passwordController,
                    label: l10n.authPasswordLabel,
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.authPasswordEmpty;
                      }
                      if (value.length < 6) {
                        return l10n.authPasswordShort;
                      }
                      return null;
                    },
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: l10n.authConfirmPasswordLabel,
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirmPassword,
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.authConfirmPasswordEmpty;
                        }
                        if (value != _passwordController.text) {
                          return l10n.authConfirmPasswordMismatch;
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
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
                          onPressed: _isLoading ? null : _handleAuth,
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
                                  _isSignUp
                                      ? l10n.authPrimaryButtonSignUp
                                      : l10n.authPrimaryButtonSignIn,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )
                      .animate()
                      .slideY(
                        delay: 600.ms,
                        begin: 0.3,
                        end: 0,
                        duration: 400.ms,
                      )
                      .fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        )
        .animate()
        .slideX(delay: 400.ms, begin: -0.2, end: 0, duration: 500.ms)
        .fadeIn(delay: 400.ms);
  }

  Widget _buildPhoneField() {
    final l10n = context.l10n;

    return IntlPhoneField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: l10n.authPhoneLabel,
        filled: true,
        fillColor: AppTheme.backgroundColor,
        counterText: '',
      ),
      initialCountryCode: 'DZ',
      onChanged: (phone) {
        _fullPhoneNumber = phone.completeNumber;
      },
      validator: (phone) {
        if (phone == null || phone.number.isEmpty) {
          return l10n.authPhoneEmpty;
        }
        if (phone.number.length < 9) {
          return l10n.authPhoneInvalid;
        }
        return null;
      },
      flagsButtonPadding: const EdgeInsets.only(left: 16),
      dropdownTextStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      style: TextStyle(fontSize: 16, color: AppTheme.textPrimary),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.backgroundColor,
      ),
    );
  }

  Widget _buildToggleAuth() {
    final l10n = context.l10n;

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUp
                    ? l10n.authToggleQuestionSignUp
                    : l10n.authToggleQuestionSignIn,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    _nameController.clear();
                    _phoneController.clear();
                    _passwordController.clear();
                    _confirmPasswordController.clear();
                    _fullPhoneNumber = '';
                  });
                },
                child: Text(
                  _isSignUp
                      ? l10n.authToggleActionSignUp
                      : l10n.authToggleActionSignIn,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 800.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0, delay: 800.ms);
  }
}
