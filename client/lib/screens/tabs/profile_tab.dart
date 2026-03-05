import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../config/contact_support_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pill_page_header.dart';
import '../../services/auth_service.dart';
import '../../services/address_service.dart';
import '../../services/favorites_service.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';
import '../addresses_management_screen.dart';
import '../auth_screen.dart';
import '../tabs/favorites_tab.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const ProfileTab({super.key, this.onBackToHome});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _AvatarActionButton extends StatelessWidget {
  const _AvatarActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F111827),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _clientData;
  bool _loading = true;
  bool _isSavingProfile = false;
  bool _isUpdatingPassword = false;
  bool _isUploadingPhoto = false;
  double _uploadProgress = 0;
  int _addressCount = 0;
  int _favoritesCount = 0;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // Load all data in parallel for better performance
      final results = await Future.wait([
        _authService.getClientData(),
        AddressService.getAddresses(),
        FavoritesService.getFavorites(),
      ]);

      if (!mounted) return;
      setState(() {
        _clientData = _normalizeClientData(results[0]);
        _addressCount = (results[1] as List).length;
        _favoritesCount = (results[2] as List).length;
        _loading = false;
      });
    } catch (e) {
      print('Error loading profile data: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _normalizeClientData(dynamic raw) {
    if (raw == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return {
        'name': user.displayName ?? 'Client',
        'email': _resolvePreferredEmail(null),
      };
    }

    if (raw is! Map) {
      return null;
    }

    final data = raw.map((key, value) => MapEntry(key.toString(), value));
    final normalized = Map<String, dynamic>.from(data);

    void trimIfString(String key) {
      final value = normalized[key];
      if (value is String) {
        normalized[key] = value.trim();
      }
    }

    for (final field in ['name', 'displayName', 'phone', 'phoneNumber']) {
      trimIfString(field);
    }

    final resolvedEmail = _resolvePreferredEmail(normalized);
    if (resolvedEmail != null) {
      normalized['email'] = resolvedEmail;
    } else {
      normalized.remove('email');
    }

    return normalized;
  }

  String? _getPhotoUrl() {
    final explicitPhoto = _clientData?['photoUrl']?.toString();
    if (explicitPhoto != null && explicitPhoto.trim().isNotEmpty) {
      return explicitPhoto.trim();
    }

    final user = FirebaseAuth.instance.currentUser;
    final authPhoto = user?.photoURL;
    if (authPhoto != null && authPhoto.trim().isNotEmpty) {
      return authPhoto.trim();
    }

    return null;
  }

  Future<void> _onChangeAvatarTapped() async {
    if (_isUploadingPhoto) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            // Rich card styling for avatar source options
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEEF2FF), Color(0xFFE0FBFC)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.camera_enhance_rounded,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Personnalisez votre avatar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Téléversez une photo depuis votre galerie ou capturez un nouveau selfie instantanément.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _AvatarActionButton(
                          label: 'Galerie',
                          icon: Icons.photo_library_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _pickAndUpload(ImageSource.gallery);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AvatarActionButton(
                          label: 'Caméra',
                          icon: Icons.photo_camera_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _pickAndUpload(ImageSource.camera);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    if (kIsWeb) {
      await _pickAndUploadWeb(source);
      return;
    }

    ({File file, bool shouldDelete})? materialized;

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 88,
      );

      if (pickedFile == null) return;

      materialized = await _materializePickedFile(pickedFile);
      if (!mounted) {
        await _discardIfNeeded(materialized);
        return;
      }

      setState(() {
        _isUploadingPhoto = true;
        _uploadProgress = 0;
      });

      final result = await _authService.updateProfilePhoto(
        materialized.file,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _uploadProgress = progress.clamp(0, 1));
        },
      );

      await _handleUploadResult(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de mettre à jour la photo: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (!mounted) {
        await _discardIfNeeded(materialized);
        return;
      }

      setState(() {
        _isUploadingPhoto = false;
      });

      await _discardIfNeeded(materialized);
    }
  }

  Future<void> _pickAndUploadWeb(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 88,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = true;
        _uploadProgress = 0;
      });

      final result = await _authService.updateProfilePhotoFromBytes(
        bytes,
        fileName: _resolvePickedFileName(pickedFile),
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => _uploadProgress = progress.clamp(0, 1));
        },
      );

      await _handleUploadResult(result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de mettre à jour la photo: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  Future<({File file, bool shouldDelete})> _materializePickedFile(
    XFile pickedFile,
  ) async {
    final path = pickedFile.path;
    if (path.isNotEmpty) {
      final file = File(path);
      try {
        if (await file.exists()) {
          // Attempt a lightweight operation to verify readability.
          await file.length();
          return (file: file, shouldDelete: false);
        }
      } catch (_) {
        // Fall through to create a readable copy in temp storage.
      }
    }

    final bytes = await pickedFile.readAsBytes();
    final tempDir = await Directory.systemTemp.createTemp('salim_avatar_');
    final resolvedName = _resolvePickedFileName(pickedFile);
    final tempFile = File('${tempDir.path}/$resolvedName');
    await tempFile.writeAsBytes(bytes, flush: true);

    return (file: tempFile, shouldDelete: true);
  }

  String _resolvePickedFileName(XFile pickedFile) {
    final rawName = pickedFile.name.trim();
    if (rawName.isNotEmpty && rawName != 'image_picker') {
      return rawName;
    }

    final extension = () {
      final mimeType = pickedFile.mimeType ?? '';
      final segments = mimeType.split('/');
      if (segments.length == 2 && segments.last.isNotEmpty) {
        return segments.last;
      }
      return 'jpg';
    }();

    return 'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
  }

  Future<void> _discardIfNeeded(
    ({File file, bool shouldDelete})? materialized,
  ) async {
    if (materialized == null || !materialized.shouldDelete) return;

    try {
      final dir = materialized.file.parent;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Ignore cleanup errors.
    }
  }

  Future<void> _handleUploadResult(
    ({String? error, String? photoUrl}) result,
  ) async {
    if (!mounted) return;

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    await _loadProfileData();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo de profil mise à jour avec succès !'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  String? _resolvePreferredEmail(Map<String, dynamic>? data) {
    const aliasSuffix = '@client.salimstore.com';

    String? clean(dynamic value) {
      if (value == null) return null;
      final trimmed = value.toString().trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.endsWith(aliasSuffix)) return null;
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      return emailRegex.hasMatch(trimmed) ? trimmed : null;
    }

    final candidateKeys = [
      'email',
      'contactEmail',
      'profileEmail',
      'userEmail',
      'primaryEmail',
    ];

    if (data != null) {
      for (final key in candidateKeys) {
        final resolved = clean(data[key]);
        if (resolved != null) {
          return resolved;
        }
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    final authCandidate = clean(user?.email);
    if (authCandidate != null) {
      return authCandidate;
    }

    if (user != null) {
      for (final provider in user.providerData) {
        final providerEmail = clean(provider.email);
        if (providerEmail != null) {
          return providerEmail;
        }
      }
    }

    return null;
  }

  Future<void> _showEditInfoSheet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final phoneFromEmail =
        user.email?.replaceAll('@client.salimstore.com', '') ?? '';

    final nameController = TextEditingController(
      text: _clientData?['name'] ?? user.displayName ?? '',
    );
    final phoneController = TextEditingController(
      text: _clientData?['phone'] ?? phoneFromEmail,
    );
    final emailController = TextEditingController(
      text: _clientData?['email'] ?? '',
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool saving = false;
        String? modalError;
        return StatefulBuilder(
          builder: (context, setModalState) {
            void dismissSheet(bool outcome) {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).pop(outcome);
            }

            return WillPopScope(
              onWillPop: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                return true;
              },
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 64,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Mettre à jour mes informations',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Actualisez vos coordonnées afin que nous puissions toujours vous contacter.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Nom complet',
                            prefixIcon: const Icon(
                              Icons.person_outline_rounded,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Numéro de téléphone',
                            prefixIcon: const Icon(Icons.phone_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Adresse email',
                            prefixIcon: const Icon(
                              Icons.alternate_email_rounded,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        if (modalError != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            modalError!,
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  final phone = phoneController.text.trim();
                                  final email = emailController.text.trim();

                                  if (name.isEmpty ||
                                      phone.isEmpty ||
                                      email.isEmpty) {
                                    setModalState(() {
                                      modalError =
                                          'Veuillez remplir toutes les informations.';
                                    });
                                    return;
                                  }

                                  if (!_isValidEmail(email)) {
                                    setModalState(() {
                                      modalError =
                                          'Veuillez saisir un email valide.';
                                    });
                                    return;
                                  }

                                  setModalState(() {
                                    saving = true;
                                    modalError = null;
                                  });
                                  setState(() => _isSavingProfile = true);

                                  final updateResult = await _authService
                                      .updateProfile(
                                        name: name,
                                        phone: phone,
                                        email: email,
                                      );

                                  if (!mounted) {
                                    return;
                                  }

                                  setState(() => _isSavingProfile = false);
                                  setModalState(() => saving = false);

                                  if (updateResult == null) {
                                    dismissSheet(true);
                                  } else {
                                    setModalState(() {
                                      modalError = updateResult;
                                    });
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Enregistrer',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();

    if (!mounted) return;
    if (result == true) {
      await _loadProfileData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _showChangePasswordSheet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool saving = false;
        String? modalError;
        return StatefulBuilder(
          builder: (context, setModalState) {
            void dismissSheet(bool outcome) {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.of(context).pop(outcome);
            }

            return WillPopScope(
              onWillPop: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                return true;
              },
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Icon(
                            Icons.lock_reset_rounded,
                            size: 64,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Modifier mon mot de passe',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pour sécuriser votre compte, utilisez un mot de passe unique et confidentiel.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: currentPasswordController,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe actuel',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: newPasswordController,
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Nouveau mot de passe',
                            prefixIcon: const Icon(Icons.password_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirmer le nouveau mot de passe',
                            prefixIcon: const Icon(Icons.verified_user_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        if (modalError != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            modalError!,
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final currentPassword =
                                      currentPasswordController.text.trim();
                                  final newPassword = newPasswordController.text
                                      .trim();
                                  final confirmPassword =
                                      confirmPasswordController.text.trim();

                                  if (currentPassword.isEmpty ||
                                      newPassword.isEmpty ||
                                      confirmPassword.isEmpty) {
                                    setModalState(() {
                                      modalError =
                                          'Veuillez remplir tous les champs.';
                                    });
                                    return;
                                  }

                                  if (newPassword.length < 6) {
                                    setModalState(() {
                                      modalError =
                                          'Le nouveau mot de passe doit contenir au moins 6 caractères.';
                                    });
                                    return;
                                  }

                                  if (newPassword != confirmPassword) {
                                    setModalState(() {
                                      modalError =
                                          'Les mots de passe ne correspondent pas.';
                                    });
                                    return;
                                  }

                                  setModalState(() {
                                    saving = true;
                                    modalError = null;
                                  });
                                  setState(() => _isUpdatingPassword = true);

                                  final updateResult = await _authService
                                      .changePassword(
                                        currentPassword: currentPassword,
                                        newPassword: newPassword,
                                      );

                                  if (!mounted) {
                                    return;
                                  }

                                  setState(() => _isUpdatingPassword = false);
                                  setModalState(() => saving = false);

                                  if (updateResult == null) {
                                    dismissSheet(true);
                                  } else {
                                    setModalState(() {
                                      modalError = updateResult;
                                    });
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Enregistrer',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe mis à jour avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  String _getDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    return _clientData?['name'] ?? user?.displayName ?? 'Utilisateur';
  }

  String _getPhone() {
    return _clientData?['phone'] ?? '';
  }

  String _getEmail() {
    final resolved = _clientData?['email']?.toString();
    if (resolved != null && resolved.trim().isNotEmpty) {
      return resolved.trim();
    }

    final user = FirebaseAuth.instance.currentUser;
    final authEmail = user?.email;
    if (authEmail != null && authEmail.isNotEmpty) {
      final normalizedAuth = _resolvePreferredEmail({'email': authEmail});
      if (normalizedAuth != null) {
        return normalizedAuth;
      }
    }

    if (user != null) {
      for (final provider in user.providerData) {
        final providerEmail = _resolvePreferredEmail({'email': provider.email});
        if (providerEmail != null) {
          return providerEmail;
        }
      }
    }

    return '';
  }

  String _getInitials(String name) {
    final segments = name
        .split(RegExp(r'\s+'))
        .where((segment) => segment.trim().isNotEmpty)
        .toList();
    if (segments.isEmpty) return '👤';
    if (segments.length == 1) {
      final first = segments.first.trim();
      return first.isEmpty ? '👤' : first[0].toUpperCase();
    }
    final firstInitial = segments.first.trim().isNotEmpty
        ? segments.first.trim()[0].toUpperCase()
        : '';
    final lastInitial = segments.last.trim().isNotEmpty
        ? segments.last.trim()[0].toUpperCase()
        : '';
    final joined = '$firstInitial$lastInitial'.trim();
    return joined.isEmpty ? '👤' : joined;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  Widget _buildLoadingSkeleton() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.4),
                        highlightColor: Colors.white,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.white.withOpacity(0.5),
                              highlightColor: Colors.white,
                              child: Container(
                                height: 18,
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            Shimmer.fromColors(
                              baseColor: Colors.white.withOpacity(0.4),
                              highlightColor: Colors.white,
                              child: Container(
                                height: 14,
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            Shimmer.fromColors(
                              baseColor: Colors.white.withOpacity(0.4),
                              highlightColor: Colors.white,
                              child: Container(
                                height: 14,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => Shimmer.fromColors(
                  baseColor: AppTheme.textSecondary.withOpacity(0.08),
                  highlightColor: Colors.white,
                  child: Container(
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingSkeleton();
    }

    final name = _getDisplayName();
    final phone = _getPhone();
    final email = _getEmail();
    final l10n = context.l10n;
    final localeController = context.localeController;
    final photoUrl = _getPhotoUrl();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _onChangeAvatarTapped,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 280),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.98),
                                      Colors.white.withOpacity(0.72),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 22,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: AppTheme.primaryColor
                                      .withOpacity(0.1),
                                  backgroundImage: photoUrl != null
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl == null
                                      ? Text(
                                          _getInitials(name),
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primaryColor,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              if (_isUploadingPhoto)
                                Positioned.fill(
                                  child: ClipOval(
                                    child: Shimmer.fromColors(
                                      baseColor: Colors.white.withOpacity(0.65),
                                      highlightColor: Colors.white.withOpacity(
                                        0.15,
                                      ),
                                      child: Container(
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              if (_isUploadingPhoto)
                                Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  opacity: _isUploadingPhoto ? 0.0 : 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFF22D3EE),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.24),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              if (_isUploadingPhoto)
                                Positioned(
                                  bottom: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(_uploadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    onPressed: _isSavingProfile
                                        ? null
                                        : _showEditInfoSheet,
                                    icon: const Icon(Icons.edit_rounded),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(
                                        0.18,
                                      ),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(40, 40),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (email.isNotEmpty)
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.alternate_email_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.smartphone,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      phone,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ProfileStatActionCard(
                      title: 'Modifier mes infos',
                      subtitle: 'Nom, téléphone, email',
                      count: 0,
                      countLabel: '',
                      icon: Icons.badge_rounded,
                      accentColor: AppTheme.primaryColor,
                      gradientColors: const [
                        Color(0xFFE6F0FF),
                        Color(0xFFE0F7FF),
                      ],
                      showCount: false,
                      onTap: () async {
                        if (_isSavingProfile) return;
                        await _showEditInfoSheet();
                      },
                    ),
                    const SizedBox(height: 10),
                    _ProfileStatActionCard(
                      title: 'Changer mon mot de passe',
                      subtitle: 'Sécurisez votre compte',
                      count: 0,
                      countLabel: '',
                      icon: Icons.lock_reset_rounded,
                      accentColor: AppTheme.accentColor,
                      gradientColors: const [
                        Color(0xFFF3E8FF),
                        Color(0xFFE0F2FE),
                      ],
                      showCount: false,
                      onTap: () async {
                        if (_isUpdatingPassword) return;
                        await _showChangePasswordSheet();
                      },
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isStacked = constraints.maxWidth < 360;
                        final cards = [
                          _ProfileStatActionCard(
                            title: 'Mes adresses',
                            subtitle: 'Gérez vos lieux de livraison',
                            count: _addressCount,
                            countLabel: 'Adresses',
                            icon: Icons.location_on_rounded,
                            accentColor: AppTheme.primaryColor,
                            gradientColors: const [
                              Color(0xFFE6F0FF),
                              Color(0xFFECFFF6),
                            ],
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AddressesManagementScreen(),
                                ),
                              );
                              if (!mounted) return;
                              await _loadProfileData();
                            },
                          ),
                          _ProfileStatActionCard(
                            title: 'Mes favoris',
                            subtitle: 'Retrouvez vos coups de cœur',
                            count: _favoritesCount,
                            countLabel: 'Favoris',
                            icon: Icons.favorite_rounded,
                            accentColor: AppTheme.accentColor,
                            gradientColors: const [
                              Color(0xFFEFF4FF),
                              Color(0xFFF9EDFF),
                            ],
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FavoritesTab(),
                                ),
                              );
                              if (!mounted) return;
                              await _loadProfileData();
                            },
                          ),
                        ];

                        if (isStacked) {
                          return Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 12),
                              cards[1],
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 12),
                            Expanded(child: cards[1]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF8FBFF), Color(0xFFE7F0FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(
                                    0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.support_agent,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Support et contact',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final uri = Uri(
                                      scheme: 'tel',
                                      path: '+213778029965',
                                    );
                                    final ok = await launchUrl(uri);
                                    if (!context.mounted) return;
                                    if (!ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Impossible d`ouvrir l\'application téléphone.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.phone_rounded),
                                  label: const Text('Appeler'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse(
                                      'https://livriyes.app',
                                    );
                                    final ok = await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    if (!context.mounted) return;
                                    if (!ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Impossible d\'ouvrir le site web.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.language_rounded),
                                  label: const Text('Site Web'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final uri =
                                        ContactSupportConfig.buildSupportEmailUri();
                                    final ok = await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    if (!context.mounted) return;
                                    if (!ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Impossible d\'ouvrir l\'application mail.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.alternate_email_rounded,
                                  ),
                                  label: const Text('Email'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse(
                                      'https://wa.me/213778029965',
                                    );
                                    final ok = await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    if (!context.mounted) return;
                                    if (!ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Impossible d\'ouvrir WhatsApp.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: FaIcon(FontAwesomeIcons.whatsapp),
                                  label: const Text('WhatsApp'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLanguageSelector(localeController, l10n),
                    const SizedBox(height: 20),
                    _ProfileMenuItem(
                      icon: Icons.description_outlined,
                      title: 'Conditions d\'utilisation',
                      subtitle: 'Consulter les détails',
                      onTap: () => _showTermsDialog(context),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text('Déconnexion'),
                              content: const Text(
                                'Êtes-vous sûr de vouloir vous déconnecter ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                  child: const Text('Oui, me déconnecter'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && mounted) {
                            await FirebaseAuth.instance.signOut();
                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ClientAuthScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Déconnexion'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    final messageCtrl = TextEditingController();
    bool launching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: MediaQuery.of(context).size.width * 0.86,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8FBFF), Color(0xFFE7F0FF)],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppTheme.primaryColor,
                                    child: Icon(
                                      Icons.support_agent,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Support & contact',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Une équipe dédiée est là pour vous aider rapidement. Partagez votre message ci-dessous et ouvrez votre messagerie en un clic.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 18),
                              Shimmer.fromColors(
                                baseColor: AppTheme.primaryColor.withOpacity(
                                  0.8,
                                ),
                                highlightColor: Colors.white,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.accentColor,
                                      ],
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.alternate_email,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        ContactSupportConfig.supportEmail,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: messageCtrl,
                                minLines: 4,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Décrivez votre demande, un membre de l\'équipe vous répondra rapidement.',
                                  prefixIcon: Icon(Icons.edit_note_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            height: 140,
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEEF4FF), Color(0xFFD4E6FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.support_agent,
                                size: 64,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: launching
                              ? null
                              : () async {
                                  setState(() => launching = true);
                                  final uri =
                                      ContactSupportConfig.buildSupportEmailUri(
                                        body: messageCtrl.text,
                                      );
                                  final success = await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  if (!context.mounted) return;
                                  setState(() => launching = false);
                                  if (success) {
                                    messageCtrl.clear();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Votre messagerie s\'ouvre pour finaliser l\'envoi.',
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Impossible d\'ouvrir l\'application mail.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: launching
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            launching
                                ? 'Ouverture...'
                                : 'Envoyer depuis ma messagerie',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: ContactSupportConfig.supportEmail,
                              ),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Adresse email copiée'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copier l\'adresse'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            messageCtrl.dispose();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Fermer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      // Ensure controller is disposed when dialog is closed
      messageCtrl.dispose();
    });
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Conditions d\'utilisation'),
        content: const SingleChildScrollView(
          child: Text(
            '''1. Conditions Générales d'Utilisation et de Vente (CGUV) 

Date d'entrée en vigueur : 01/01/2026 

Article 1 : Mentions Légales 

L'application LivriYes (ci-après "l'Application") est éditée et exploitée par la société : 

Dénomination sociale : LIVRIYES LLC 

Forme juridique : Limited Liability Company (LLC) 

Numéro de document : 202532904028 

Siège social : 2057 HARWITCH RD, UPPER ARLINGTON, OH 43221, USA. 

Article 2 : Objet 

Les présentes conditions régissent la vente directe de produits et les services de livraison proposés par LIVRIYES LLC via l'Application. Contrairement à une place de marché, LIVRIYES LLC est le vendeur direct des produits présentés ; il n'y a pas d'intermédiaire tiers (commerçants). 

Article 3 : Produits et Disponibilité 

Offre : Les produits régis par les présentes sont ceux qui figurent dans l'Application au jour de la consultation par le client. 

Gestion des stocks : Les produits sont gérés directement par nos soins. En cas d'indisponibilité d'un produit après passation de la commande, la politique de remplacement (voir Politique de Remplacement) s'applique immédiatement. Aucune annulation sèche n'est effectuée. 

Article 4 : Commande et Paiement 

Validation : La commande est ferme et définitive dès la validation du paiement ou la confirmation de la commande (si paiement à la livraison). 

Modification : Une fois la commande préparée par nos équipes, aucune modification n'est acceptée par le client. 

Prix : Les prix sont indiqués en devise locale et incluent les taxes applicables. Les frais de livraison sont ajoutés au total avant validation. 

Article 5 : Livraison 

Responsabilité : LIVRIYES LLC assure la livraison à l'adresse indiquée. Le client doit s'assurer de l'exactitude des coordonnées. 

Absence : En cas d'absence du client lors de la livraison, la commande sera retournée à l'entrepôt. Des frais de relivraison pourront être appliqués. 

Article 6 : Droit Applicable 

Les présentes conditions sont régies par les lois de l'État de l'Ohio (USA), lieu d'enregistrement de la société, sans préjudice des règles impératives de protection des consommateurs du pays de livraison.  

 
Contact :  

Email : contact@livriyes.app  

Téléphone : +213778029965  

Forme 

2. Politique de Remplacement et de Gestion des Commandes 

Date d'entrée en vigueur : 01/01/2026 

IMPORTANT : La société LIVRIYES LLC applique une politique de non-remboursement monétaire. En validant une commande sur l'Application, le client accepte les conditions suivantes concernant les indisponibilités ou les problèmes de commande. 

1. Absence de Remboursement 

Aucun remboursement (en espèces, virement ou retour carte bancaire) n'est effectué, que ce soit pour une annulation client, une erreur de commande ou une indisponibilité produit. Toutes les ventes sont finales. 

2. Gestion des produits indisponibles (Rupture de stock) 

Si un produit commandé se révèle indisponible au moment de la préparation, deux solutions sont appliquées, au choix de LIVRIYES LLC ou en accord avec le client : 

Option A - Remplacement : Le produit manquant est remplacé par un article de qualité et de prix équivalents ou supérieurs (sans surcoût pour le client). 

Option B - Enregistrement différé (Backorder) : La ligne de commande concernant l'article manquant reste "ouverte" et enregistrée dans notre système. L'article sera livré prioritairement dès son retour en stock (réapprovisionnement), sans frais de livraison supplémentaires pour cet envoi spécifique. 

3. Produits défectueux ou Erreurs de préparation 

En cas de réception d'un produit endommagé ou ne correspondant pas à la commande : 

Le client doit signaler le problème via l'Application sous 24h avec photo à l'appui. 

Après validation par notre support, LIVRIYES LLC procédera à : 

L'échange immédiat du produit lors de la prochaine tournée de livraison. 

OU l'enregistrement d'un crédit (avoir) sur le compte client, utilisable pour une future commande. 

4. Annulation de commande 

Toute commande validée ne peut être annulée par le client. Si le client refuse la livraison, les produits restent la propriété de LIVRIYES LLC et le montant de la commande reste dû ou conservé par la société. 
 
Contact :  

Email : contact@livriyes.app  

Téléphone : +213778029965  

Forme 

Politique de Confidentialité 

Date d'entrée en vigueur : 01/01/2026 

1. Responsable du Traitement 

Les données personnelles collectées via l'application LivriYes sont traitées par : 

Société : LIVRIYES LLC 

Siège social : 2057 HARWITCH RD, UPPER ARLINGTON, OH 43221, USA. 

Contact : contact@livriyes.app 

2. Données Collectées 

Nous collectons uniquement les données nécessaires au bon fonctionnement du service de vente et de livraison : 

Données d'identité : Nom, prénom, numéro de téléphone (obligatoire pour la livraison). 

Données de livraison : Adresse postale complète, étage, code d'accès, instructions spécifiques. 

Données de géolocalisation : Position GPS exacte lors de la sélection de l'adresse de livraison pour faciliter le trajet des livreurs. 

Données de transaction : Historique des commandes, détails des produits achetés, montant total. 

Données techniques : Adresse IP, type d'appareil, version de l'OS (pour la maintenance et la sécurité). 

Données de paiement : Nous ne stockons pas les données bancaires complètes. Les paiements sont sécurisés et traités par nos prestataires de paiement certifiés. Nous conservons uniquement un jeton d'identification de transaction. 

3. Finalités du Traitement 

Vos données sont utilisées pour : 

Exécuter le contrat : Gestion des commandes, préparation des produits par nos équipes, et livraison à votre domicile. 

Service Client : Gestion des réclamations, échanges de produits ou mise en attente (backorder). 

Amélioration du service : Analyse anonymisée des habitudes de commande pour optimiser nos stocks (gestion directe). 

Notifications : Envoi d'étapes de commande (SMS, Push, Email). 

4. Partage des Données 

Vos données ne sont jamais vendues à des tiers. Elles sont partagées uniquement avec : 

Le personnel de LIVRIYES LLC : Pour la préparation des commandes. 

Les livreurs : Nom, téléphone et adresse sont transmis au livreur assigné uniquement le temps de la mission de livraison. 

Prestataires techniques : Hébergeur de données et processeur de paiement (ex: Stripe, PayPal), soumis à des obligations strictes de confidentialité. 

Autorités légales : Si requis par la loi de l'État de l'Ohio ou du pays de livraison. 

5. Autorisations Spécifiques (Mobile) 

L'application peut demander l'accès à certaines fonctionnalités de votre téléphone : 

Position (GPS) : Pour localiser précisément l'adresse de livraison. 

Notifications : Pour vous informer de l'arrivée du livreur. 

Stockage/Caméra : Si vous devez envoyer une photo pour signaler un produit endommagé. 

6. Sécurité des Données 

Nous mettons en œuvre des mesures de sécurité techniques (chiffrement SSL/HTTPS) et organisationnelles pour protéger vos données contre l'accès non autorisé, la perte ou l'altération. Les serveurs sont sécurisés selon les standards internationaux. 

7. Vos Droits 

Conformément aux réglementations en vigueur, vous disposez des droits suivants : 

Accès et Rectification : Vous pouvez consulter et modifier vos informations personnelles directement dans l'application. 

Suppression : Vous pouvez demander la suppression de votre compte et de vos données associées en contactant le support, sous réserve des obligations légales de conservation (ex: facturation). 

8. Modifications 

LIVRIYES LLC se réserve le droit de modifier cette politique. Les utilisateurs seront informés des mises à jour majeures via l'application. L'utilisation continue du service après le 01/01/2026 vaut acceptation des nouvelles conditions 

9. Contact :  

Email : contact@livriyes.app  

Téléphone : +213778029965''',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    LocaleController controller,
    AppLocalizations l10n,
  ) {
    final currentLocale = controller.locale;
    final isFrench = currentLocale.languageCode == 'fr';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;

        Widget languageOption({
          required String label,
          required String subtitle,
          required bool selected,
          required Future<void> Function() onTap,
        }) {
          return _LanguageOptionCard(
            label: label,
            subtitle: subtitle,
            selected: selected,
            onTap: () async {
              await onTap();
              if (!mounted) return;
            },
          );
        }

        final options = isCompact
            ? Column(
                children: [
                  languageOption(
                    label: 'English',
                    subtitle: l10n.authLanguageEnglish,
                    selected: !isFrench,
                    onTap: () async {
                      await controller.updateLocale(const Locale('en'));
                      if (!mounted) return;
                      _showLanguageChangedSnack(l10n.authLanguageEnglish);
                    },
                  ),
                  const SizedBox(height: 12),
                  languageOption(
                    label: 'Français',
                    subtitle: l10n.authLanguageFrench,
                    selected: isFrench,
                    onTap: () async {
                      await controller.updateLocale(const Locale('fr'));
                      if (!mounted) return;
                      _showLanguageChangedSnack(l10n.authLanguageFrench);
                    },
                  ),
                ],
              )
            : LayoutBuilder(
                builder: (context, innerConstraints) {
                  final itemSpacing = innerConstraints.maxWidth * 0.04;
                  final clampedSpacing = itemSpacing.clamp(12.0, 20.0);
                  return Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: clampedSpacing / 2),
                          child: languageOption(
                            label: 'English',
                            subtitle: l10n.authLanguageEnglish,
                            selected: !isFrench,
                            onTap: () async {
                              await controller.updateLocale(const Locale('en'));
                              if (!mounted) return;
                              _showLanguageChangedSnack(
                                l10n.authLanguageEnglish,
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: clampedSpacing / 2),
                          child: languageOption(
                            label: 'Français',
                            subtitle: l10n.authLanguageFrench,
                            selected: isFrench,
                            onTap: () async {
                              await controller.updateLocale(const Locale('fr'));
                              if (!mounted) return;
                              _showLanguageChangedSnack(
                                l10n.authLanguageFrench,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFF2F5FF), Color(0xFFE8F8FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: AppTheme.primaryColor,
                highlightColor: Colors.white,
                child: Text(
                  l10n.profileLanguageTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.profileLanguageSubtitle,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              options,
            ],
          ),
        );
      },
    );
  }

  void _showLanguageChangedSnack(String languageName) {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.authLanguageChangedMessage(languageName)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  bool get mounted => context.mounted;
}

Widget profileQuickAction({
  required String title,
  required String description,
  required IconData icon,
  Future<void> Function()? onTap,
  required bool isBusy,
}) {
  final asyncTap = onTap;
  final VoidCallback? handleTap = asyncTap == null ? null : () => asyncTap();

  return _ProfileQuickAction(
    title: title,
    description: description,
    icon: icon,
    onTap: handleTap,
    isBusy: isBusy,
  );
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : Colors.grey.withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryColor.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.language_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF8FBFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Shimmer.fromColors(
                baseColor: AppTheme.primaryColor,
                highlightColor: Colors.white,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileQuickAction extends StatelessWidget {
  const _ProfileQuickAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.isBusy = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                description,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );

    final borderRadius = BorderRadius.circular(20);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isBusy ? 0.7 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: isBusy ? null : onTap,
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFE9F2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isBusy
                ? Shimmer.fromColors(
                    baseColor: AppTheme.primaryColor.withOpacity(0.3),
                    highlightColor: Colors.white,
                    child: cardContent,
                  )
                : cardContent,
          ),
        ),
      ),
    );
  }
}

class _ProfileStatActionCard extends StatelessWidget {
  const _ProfileStatActionCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.countLabel,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    this.showCount = true,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int count;
  final String countLabel;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final bool showCount;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(20);
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () async => onTap(),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showCount) ...[
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      count.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
