import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class AdminPaymentService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
  );

  static DatabaseReference _adminRef(String uid) =>
      _db.ref('users').child(uid).child('paymentMethods');
  static DatabaseReference _defaultRef(String uid) =>
      _db.ref('users').child(uid).child('paymentDefault');
  static DatabaseReference _publicInfoRef(String uid) =>
      _db.ref('users').child(uid).child('paymentsPublic');

  static Future<List<Map<String, dynamic>>> getMethods() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    final snap = await _adminRef(uid).get();
    if (!snap.exists) return [];
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    return map.entries
        .map(
          (e) => {
            'id': e.key.toString(),
            ...Map<String, dynamic>.from(e.value as Map),
          },
        )
        .toList();
  }

  static Future<String?> getDefaultMethodId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _defaultRef(uid).get();
    if (!snap.exists) return null;
    return snap.value?.toString();
  }

  static Future<void> setDefaultMethod(String methodId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _defaultRef(uid).set(methodId);
  }

  // Placeholder linkers (replace with real Stripe/PayPal onboarding)
  static Future<void> linkStripeTest() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _adminRef(uid).push();
    await ref.set({
      'provider': 'stripe',
      'brand': 'Visa',
      'last4': '4242',
      'createdAt': ServerValue.timestamp,
    });
  }

  static Future<void> addStripeCard({
    required String brand,
    required String last4,
    String holder = '',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _adminRef(uid).push();
    await ref.set({
      'provider': 'stripe',
      'brand': brand,
      'last4': last4,
      'holder': holder,
      'createdAt': ServerValue.timestamp,
    });
  }

  static Future<void> linkPayPalSandbox() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _adminRef(uid).push();
    await ref.set({
      'provider': 'paypal',
      'brand': 'PayPal',
      'last4': 'PP',
      'createdAt': ServerValue.timestamp,
    });
  }

  static Future<void> addPayPalEmail({required String email}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _adminRef(uid).push();
    await ref.set({
      'provider': 'paypal',
      'brand': 'PayPal',
      'last4': email,
      'createdAt': ServerValue.timestamp,
    });
  }

  // Public info for routing payouts (non-secret):
  // stripeAccountId (acct_..), stripePublishableKey, paypalMerchantId, paypalEmail
  static Future<Map<String, String>> getPublicInfo() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};
    final snap = await _publicInfoRef(uid).get();
    if (!snap.exists) return {};
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    return map.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  static Future<void> savePublicInfo({
    String? stripeAccountId,
    String? stripePublishableKey,
    String? paypalMerchantId,
    String? paypalEmail,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final update = <String, String>{};
    if (stripeAccountId != null) update['stripeAccountId'] = stripeAccountId;
    if (stripePublishableKey != null) {
      update['stripePublishableKey'] = stripePublishableKey;
    }
    if (paypalMerchantId != null) update['paypalMerchantId'] = paypalMerchantId;
    if (paypalEmail != null) update['paypalEmail'] = paypalEmail;
    await _publicInfoRef(uid).update(update);
  }

  static Future<void> unlink(String methodId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _adminRef(uid).child(methodId).remove();
  }
}
