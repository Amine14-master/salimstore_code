import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'auth_service.dart';
import 'address_service.dart';

class ReceiverService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  static DatabaseReference _receiversRef(String userId) {
    return _db.ref('users/$userId/receivers');
  }

  static Future<List<Map<String, dynamic>>> getReceivers() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snap = await _receiversRef(user.uid).get();
    if (!snap.exists || snap.value == null) return [];

    final raw = Map<dynamic, dynamic>.from(snap.value as Map);
    final list = <Map<String, dynamic>>[];
    raw.forEach((key, value) {
      if (value is Map) {
        list.add({'id': key.toString(), ...Map<String, dynamic>.from(value)});
      }
    });
    list.sort((a, b) {
      final at = (a['createdAt'] ?? 0) as int;
      final bt = (b['createdAt'] ?? 0) as int;
      return bt.compareTo(at);
    });
    return list;
  }

  static Stream<List<Map<String, dynamic>>> receiversStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _receiversRef(user.uid).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final raw = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      final list = <Map<String, dynamic>>[];
      raw.forEach((key, value) {
        if (value is Map) {
          list.add({'id': key.toString(), ...Map<String, dynamic>.from(value)});
        }
      });
      list.sort((a, b) {
        final at = (a['createdAt'] ?? 0) as int;
        final bt = (b['createdAt'] ?? 0) as int;
        return bt.compareTo(at);
      });
      return list;
    });
  }

  static Future<String?> addReceiver({
    required String name,
    required String phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final ref = _receiversRef(user.uid).push();
    await ref.set({
      'name': name.trim(),
      'phone': phone.trim(),
      'createdAt': ServerValue.timestamp,
    });
    return ref.key;
  }

  static Future<void> updateReceiver(
    String id, {
    String? name,
    String? phone,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (phone != null) updates['phone'] = phone.trim();
    if (updates.isEmpty) return;
    await _receiversRef(user.uid).child(id).update(updates);
  }

  static Future<void> removeReceiver(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _receiversRef(user.uid).child(id).remove();
  }

  // Create default destinataire from user profile and default address
  static Future<String?> createDefaultReceiver() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Get user profile data
      final authService = AuthService();
      final clientData = await authService.getClientData();

      if (clientData == null) {
        print('No client data found');
        return null;
      }

      // Get default address
      final defaultAddress = await AddressService.getDefaultAddress();

      final userName =
          clientData['name']?.toString() ?? user.displayName ?? 'Utilisateur';
      final userPhone = clientData['phone']?.toString() ?? '';

      if (userPhone.isEmpty) {
        print('No phone number found for user');
        return null;
      }

      // Check if default receiver already exists
      final receivers = await getReceivers();
      final existingDefault = receivers
          .where(
            (r) =>
                r['name']?.toString() == userName &&
                r['phone']?.toString() == userPhone,
          )
          .firstOrNull;

      if (existingDefault != null) {
        print('Default receiver already exists');
        return existingDefault['id']?.toString();
      }

      // Create new default receiver
      final ref = _receiversRef(user.uid).push();
      final receiverData = {
        'name': userName,
        'phone': userPhone,
        'isDefault': true,
        'createdAt': ServerValue.timestamp,
      };

      // Add address info if available
      if (defaultAddress != null) {
        receiverData['address'] =
            defaultAddress['fullAddress']?.toString() ?? '';
        receiverData['addressLabel'] =
            defaultAddress['label']?.toString() ?? 'Domicile';
      }

      await ref.set(receiverData);
      return ref.key;
    } catch (e) {
      print('Error creating default receiver: $e');
      return null;
    }
  }

  // Set receiver as default
  static Future<void> setDefaultReceiver(String receiverId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get all receivers
      final receivers = await getReceivers();

      // Set all receivers to non-default, then set the target as default
      for (var receiver in receivers) {
        await _receiversRef(user.uid).child(receiver['id']).update({
          'isDefault': receiver['id'] == receiverId,
        });
      }
    } catch (e) {
      print('Error setting default receiver: $e');
    }
  }

  // Get default receiver
  static Future<Map<String, dynamic>?> getDefaultReceiver() async {
    final receivers = await getReceivers();
    return receivers.where((r) => r['isDefault'] == true).firstOrNull;
  }
}
