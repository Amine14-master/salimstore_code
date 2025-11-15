import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class PaymentService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
  );

  static DatabaseReference _userRef(String uid) =>
      _db.ref('users').child(uid).child('paymentMethods');
  static DatabaseReference _defaultRef(String uid) =>
      _db.ref('users').child(uid).child('paymentDefault');

  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snap = await _userRef(user.uid).get();
    if (!snap.exists) return [];
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    return map.entries.map((e) {
      final v = Map<String, dynamic>.from(e.value as Map);
      return {
        'id': e.key.toString(),
        'provider': v['provider']?.toString() ?? 'unknown',
        'brand': v['brand']?.toString() ?? '',
        'last4': v['last4']?.toString() ?? '',
        'createdAt': v['createdAt'],
        'holder': v['holder']?.toString() ?? '',
      };
    }).toList();
  }

  static Future<String?> getDefaultMethodId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await _defaultRef(user.uid).get();
    if (!snap.exists) return null;
    return snap.value?.toString();
  }

  static Future<void> setDefaultMethod(String methodId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _defaultRef(user.uid).set(methodId);
  }

  // Placeholder: In a real app this would open Stripe/PayPal flows and return a token.
  static Future<bool> linkStripeTestCard() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final ref = _userRef(user.uid).push();
    await ref.set({
      'provider': 'stripe',
      'brand': 'Visa',
      'last4': '4242',
      'createdAt': ServerValue.timestamp,
    });
    return true;
  }

  static Future<bool> addStripeCard({
    required String brand,
    required String last4,
    String holder = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final ref = _userRef(user.uid).push();
    await ref.set({
      'provider': 'stripe',
      'brand': brand,
      'last4': last4,
      'holder': holder,
      'createdAt': ServerValue.timestamp,
    });
    return true;
  }

  static Future<bool> linkPayPalSandbox() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final ref = _userRef(user.uid).push();
    await ref.set({
      'provider': 'paypal',
      'brand': 'PayPal',
      'last4': 'PP',
      'createdAt': ServerValue.timestamp,
    });
    return true;
  }

  static Future<bool> addPayPalEmail({required String email}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final ref = _userRef(user.uid).push();
    await ref.set({
      'provider': 'paypal',
      'brand': 'PayPal',
      'last4': email,
      'createdAt': ServerValue.timestamp,
    });
    return true;
  }

  static Future<void> unlink(String methodId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _userRef(user.uid).child(methodId).remove();
  }
}
