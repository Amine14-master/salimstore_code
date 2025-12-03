import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'cloudinary_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Lazy-loaded instances to avoid platform detection issues
  FirebaseDatabase? _database;

  FirebaseDatabase get _db {
    if (_database == null) {
      try {
        // Use the default instance to avoid multiple initialization
        _database = FirebaseDatabase.instance;
      } catch (e) {
        print('Error initializing Database: $e');
        // Fallback to default instance
        _database = FirebaseDatabase.instance;
      }
    }
    return _database!;
  }

  Future<void> _saveUserRealtimeProfile({
    required User user,
    required String name,
    required String phone,
    String? email,
    String? role,
    String? photoUrl,
    bool newUser = false,
  }) async {
    final ref = _db.ref('users').child(user.uid);

    String _trimmed(String value) => value.trim();

    final data = <String, dynamic>{
      'name': _trimmed(name),
      'displayName': _trimmed(name),
      'phone': _trimmed(phone),
      'phoneNumber': _trimmed(phone),
      'role': _trimmed(role ?? 'client'),
      'updatedAt': ServerValue.timestamp,
    };

    void addIfNotEmpty(String key, String? value) {
      if (value == null) return;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      data[key] = trimmed;
    }

    addIfNotEmpty('email', email);
    addIfNotEmpty('photoUrl', photoUrl);

    if (newUser) {
      data['createdAt'] = ServerValue.timestamp;
      await ref.set(data);
    } else {
      await ref.update(data);
    }
  }

  Future<({String? error, String? photoUrl})> updateProfilePhoto(
    File file, {
    void Function(double progress)? onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return (error: 'Utilisateur non connecté', photoUrl: null);
    }

    try {
      final uploadResult = await CloudinaryService.uploadProfileImage(
        file,
        onProgress: onProgress,
      );

      return await _finalizePhotoUpdate(user: user, uploadUrl: uploadResult);
    } catch (e) {
      print('Error updating profile photo: $e');
      return (
        error: 'Erreur lors du téléversement de la photo: ${e.toString()}',
        photoUrl: null,
      );
    }
  }

  Future<({String? error, String? photoUrl})> updateProfilePhotoFromBytes(
    Uint8List bytes, {
    String? fileName,
    void Function(double progress)? onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return (error: 'Utilisateur non connecté', photoUrl: null);
    }

    try {
      final uploadResult = await CloudinaryService.uploadProfileImageBytes(
        bytes,
        fileName: fileName,
        onProgress: onProgress,
      );

      return await _finalizePhotoUpdate(user: user, uploadUrl: uploadResult);
    } catch (e) {
      print('Error updating profile photo bytes: $e');
      return (
        error: 'Erreur lors du téléversement de la photo: ${e.toString()}',
        photoUrl: null,
      );
    }
  }

  Future<({String? error, String? photoUrl})> _finalizePhotoUpdate({
    required User user,
    required String uploadUrl,
  }) async {
    final phone = _getPhoneFromEmail(user.email);
    Map<String, dynamic>? clientData;

    if (phone != null) {
      try {
        final snapshot = await _db.ref('clients').child(phone).get();
        if (snapshot.exists) {
          clientData = Map<String, dynamic>.from(snapshot.value as Map);
        }
      } catch (e) {
        print('Error fetching client data while updating photo: $e');
      }

      await _db.ref('clients').child(phone).update({
        'photoUrl': uploadUrl,
        'updatedAt': ServerValue.timestamp,
      });
    }

    final resolvedName =
        clientData?['name']?.toString() ?? user.displayName ?? 'Client';
    final resolvedPhone = clientData?['phone']?.toString() ?? phone ?? '';
    final resolvedEmail = clientData?['email']?.toString() ?? user.email;

    await _saveUserRealtimeProfile(
      user: user,
      name: resolvedName,
      phone: resolvedPhone,
      email: resolvedEmail,
      photoUrl: uploadUrl,
    );

    await user.updatePhotoURL(uploadUrl);

    return (error: null, photoUrl: uploadUrl);
  }

  // Get phone number from user email
  String? _getPhoneFromEmail(String? email) {
    if (email == null || !email.contains('@client.salimstore.com')) return null;
    return email.replaceAll('@client.salimstore.com', '');
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up for client
  Future<String?> signUpClient({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      print('Starting signup process...');
      print('Phone: $phone');
      print('Email (auth account): $phone@client.salimstore.com');
      print('Provided email (profile): $email');

      // Create user with email (using phone as email for simplicity)
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: '$phone@client.salimstore.com',
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        print('User created successfully: ${user.uid}');

        // Update display name
        await user.updateDisplayName(name);
        print('Display name updated');

        // Save to RTDB with phone number as ID
        await _db.ref('clients').child(phone).set({
          'name': name,
          'displayName': name,
          'phone': phone,
          'phoneNumber': phone,
          'email': email,
          'role': 'client',
          if (user.photoURL != null && user.photoURL!.isNotEmpty)
            'photoUrl': user.photoURL,
          'createdAt': ServerValue.timestamp,
          'updatedAt': ServerValue.timestamp,
        });
        print('Client data saved to RTDB with phone as ID: $phone');

        // Also write to RTDB under users/<uid> for UID-keyed lookups (used by Admin app)
        await _saveUserRealtimeProfile(
          user: user,
          name: name,
          phone: phone,
          email: email,
          newUser: true,
        );
        print('User profile saved to RTDB users/${user.uid}');

        return null; // Success
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      return _getErrorMessage(e.code);
    } catch (e) {
      print('General Error: $e');
      return 'An unexpected error occurred: $e';
    }
    return 'Failed to create account';
  }

  // Sign in for client
  Future<String?> signInClient({
    required String phone,
    required String password,
  }) async {
    // Try reset variants first (they have newer passwords), then original
    final emailsToTry = [
      '${phone}_r1@client.salimstore.com',
      '${phone}_r2@client.salimstore.com',
      '${phone}_r3@client.salimstore.com',
      '$phone@client.salimstore.com', // Try original last
    ];

    String? lastError;

    for (final email in emailsToTry) {
      try {
        print('Attempting sign in with $email');
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = credential.user;
        if (user != null) {
          print('Sign in successful with $email');
          // Update client data and profile
          try {
            final clientSnapshot = await _db.ref('clients').child(phone).get();
            Map<String, dynamic> clientData = {
              'name': user.displayName ?? 'Client',
              'phone': phone,
              'email': user.email ?? '',
              'role': 'client',
              if (user.photoURL != null) 'photoUrl': user.photoURL,
            };

            if (clientSnapshot.exists) {
              final data = Map<String, dynamic>.from(
                clientSnapshot.value as Map,
              );
              clientData.addAll(data);
            } else {
              await _db.ref('clients').child(phone).set({
                ...clientData,
                'displayName': clientData['name'],
                'phoneNumber': clientData['phone'],
                'createdAt': ServerValue.timestamp,
                'updatedAt': ServerValue.timestamp,
              });
            }

            await _saveUserRealtimeProfile(
              user: user,
              name: clientData['name']?.toString() ?? 'Client',
              phone: clientData['phone']?.toString() ?? phone,
              email: clientData['email']?.toString() ?? user.email,
              photoUrl: clientData['photoUrl']?.toString(),
            );
          } catch (syncError) {
            print('Error syncing realtime profile on sign-in: $syncError');
          }
          return null; // Success
        }
      } on FirebaseAuthException catch (e) {
        // If user not found, try next variant
        if (e.code == 'user-not-found') {
          print('User not found for $email, trying next...');
          lastError = _getErrorMessage(e.code);
          continue;
        }
        // If wrong password, try next variant but don't overwrite success
        if (e.code == 'wrong-password') {
          print('Wrong password for $email, trying next...');
          lastError = _getErrorMessage(e.code);
          continue;
        }
        // For other errors (e.g. disabled, too many requests), stop and return error
        print('Fatal auth error for $email: ${e.code}');
        return _getErrorMessage(e.code);
      } catch (e) {
        print('Unexpected error for $email: $e');
        lastError = 'An unexpected error occurred';
        continue;
      }
    }

    print('All sign-in attempts failed. Last error: $lastError');
    return lastError ?? 'Authentication failed';
  }

  // Force reset password by creating a new account version
  // This is a workaround since we can't reset password without old password
  Future<String?> resetPasswordWithNewAccount({
    required String phone,
    required String newPassword,
  }) async {
    try {
      // Try to find an available email slot
      String? emailToUse;
      final variants = [
        '${phone}_r1@client.salimstore.com',
        '${phone}_r2@client.salimstore.com',
        '${phone}_r3@client.salimstore.com',
      ];

      for (final email in variants) {
        try {
          print('Trying to create reset account with email: $email');
          // Try to create user with this email
          final result = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: newPassword,
          );

          if (result.user != null) {
            emailToUse = email;
            print('Successfully created reset account with email: $email');
            break; // Success, stop looking
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            print('Email $email already exists, trying next variant...');
            continue; // Try next variant
          }
          print('Error creating reset account with $email: ${e.code}');
          rethrow;
        }
      }

      if (emailToUse == null) {
        return 'Trop de réinitialisations. Veuillez contacter le support.';
      }

      final user = _auth.currentUser;
      if (user != null) {
        print(
          'Current user after reset account creation: ${user.uid} with email: ${user.email}',
        );

        // Restore profile data from RTDB if available
        try {
          final snapshot = await _db.ref('clients').child(phone).get();
          if (snapshot.exists) {
            final data = Map<String, dynamic>.from(snapshot.value as Map);
            final name = data['name'] ?? 'Client';

            print('Restoring profile data: name=$name, phone=$phone');
            await user.updateDisplayName(name);

            // Update RTDB to reflect recent activity and track which email is now active
            await _db.ref('clients').child(phone).update({
              'updatedAt': ServerValue.timestamp,
              'passwordResetAt': ServerValue.timestamp,
              'activeAuthEmail':
                  user.email, // Track which email is currently active
              'authEmailVersion': emailToUse.contains('_r')
                  ? emailToUse.split('_r')[1].split('@')[0]
                  : 'original',
            });

            // Link this new user to the profile
            await _saveUserRealtimeProfile(
              user: user,
              name: name,
              phone: phone,
              email: data['email'],
            );

            print('Profile restoration completed successfully');
          }
        } catch (e) {
          print('Error restoring profile during reset: $e');
        }

        print(
          'Password reset completed successfully. User can now login with new password.',
        );
        return null; // Success
      }

      return 'Erreur lors de la création du nouveau compte';
    } on FirebaseAuthException catch (e) {
      print(
        'Firebase Auth error during password reset: ${e.code} - ${e.message}',
      );
      return _getErrorMessage(e.code);
    } catch (e) {
      print('Unexpected error during password reset: $e');
      return 'Une erreur inattendue est survenue: $e';
    }
  }

  // Update client profile
  Future<String?> updateProfile({
    required String name,
    required String phone,
    required String email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Utilisateur non connecté';

      final trimmedName = name.trim();
      final trimmedPhone = phone.trim();
      final trimmedEmail = email.trim();

      if (trimmedName.isEmpty || trimmedPhone.isEmpty || trimmedEmail.isEmpty) {
        return 'Veuillez fournir toutes les informations nécessaires.';
      }

      final currentPhone = _getPhoneFromEmail(user.email);
      Map<String, dynamic>? existingClientData;

      if (currentPhone != null) {
        try {
          final snapshot = await _db.ref('clients').child(currentPhone).get();
          if (snapshot.exists) {
            existingClientData = Map<String, dynamic>.from(
              snapshot.value as Map,
            );
          }
        } catch (e) {
          print('Error fetching current client data: $e');
        }
      }

      final baseData = existingClientData != null
          ? Map<String, dynamic>.from(existingClientData)
          : <String, dynamic>{};

      baseData['name'] = trimmedName;
      baseData['displayName'] = trimmedName;
      baseData['phone'] = trimmedPhone;
      baseData['phoneNumber'] = trimmedPhone;
      baseData['email'] = trimmedEmail;
      baseData['updatedAt'] = ServerValue.timestamp;
      baseData['role'] = (existingClientData?['role'] ?? 'client').toString();
      baseData.putIfAbsent('createdAt', () => ServerValue.timestamp);

      if (currentPhone != null && currentPhone != trimmedPhone) {
        await _db.ref('clients').child(currentPhone).remove();
        await _db.ref('clients').child(trimmedPhone).set(baseData);
      } else {
        await _db.ref('clients').child(trimmedPhone).set(baseData);
      }

      // Update Firebase Auth display name
      await user.updateDisplayName(trimmedName);

      try {
        await _saveUserRealtimeProfile(
          user: user,
          name: trimmedName,
          phone: trimmedPhone,
          email: trimmedEmail,
          photoUrl: baseData['photoUrl']?.toString(),
        );
      } catch (e) {
        print('Error updating realtime user profile: $e');
      }

      return null; // Success
    } catch (e) {
      print('Error updating profile: $e');
      return 'Erreur lors de la mise à jour: $e';
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Utilisateur non connecté';
      final email = user.email;
      if (email == null || email.isEmpty) {
        return 'Impossible de vérifier votre compte.';
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      try {
        await _db.ref('users').child(user.uid).update({
          'updatedAt': ServerValue.timestamp,
        });
      } catch (e) {
        print('Error updating password timestamp: $e');
      }

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          return 'Mot de passe actuel incorrect.';
        case 'weak-password':
          return 'Le nouveau mot de passe est trop faible.';
        case 'requires-recent-login':
          return 'Veuillez vous reconnecter pour modifier votre mot de passe.';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez plus tard.';
        default:
          return _getErrorMessage(e.code);
      }
    } catch (e) {
      print('Error changing password: $e');
      return 'Une erreur est survenue lors du changement de mot de passe.';
    }
  }

  // Get client data from RTDB (using phone number as ID)
  Future<Map<String, dynamic>?> getClientData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final phone = _getPhoneFromEmail(user.email);
      if (phone == null) return null;

      // Get from RTDB first (primary source)
      final snapshot = await _db.ref('clients').child(phone).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return data;
      }

      return null;
    } catch (e) {
      print('Error getting client data: $e');
      return null;
    }
  }

  // Get error message from Firebase Auth error code
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this phone number.';
      case 'user-not-found':
        return 'No user found for this phone number.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Invalid phone number format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Signing in with this method is not enabled.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
