import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up for admin
  Future<String?> signUpAdmin({
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      print('Starting admin signup process...');
      print('Phone: $phone');
      print('Email: $phone@admin.salimstore.com');

      // Create user with email (using phone as email for simplicity)
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: '$phone@admin.salimstore.com',
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        print('Admin user created successfully: ${user.uid}');

        // Update display name
        await user.updateDisplayName(name);
        print('Display name updated');

        // Save admin data to Firestore
        await _firestore.collection('admins').doc(user.uid).set({
          'name': name,
          'phone': phone,
          'email': '$phone@admin.salimstore.com',
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Admin data saved to Firestore');

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

  // Sign in for admin
  Future<String?> signInAdmin({
    required String phone,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: '$phone@admin.salimstore.com',
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'An unexpected error occurred';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
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
