import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';

class AddressService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
  );

  static DatabaseReference _addressesRef(String userId) {
    return _database.ref('users/$userId/addresses');
  }

  static Future<String?> addAddress(Map<String, dynamic> addressData) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final ref = _addressesRef(user.uid).push();
    await ref.set({
      ...addressData,
      'createdAt': ServerValue.timestamp,
      'isDefault': false,
    });
    return ref.key;
  }

  static Future<List<Map<String, dynamic>>> getAddresses() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _addressesRef(user.uid).get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          return {
            'id': entry.key.toString(),
            ...Map<String, dynamic>.from(entry.value as Map),
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting addresses: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getDefaultAddress() async {
    final addresses = await getAddresses();
    final defaultAddr = addresses.firstWhere(
      (addr) => addr['isDefault'] == true,
      orElse: () => addresses.isNotEmpty ? addresses.first : {},
    );
    return defaultAddr.isEmpty ? null : defaultAddr;
  }

  static Future<void> setDefaultAddress(
    String? addressId, {
    String? fullAddress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final addresses = await getAddresses();
    String? targetId;

    if (addressId != null) {
      // Use ID if provided
      targetId = addressId;
    } else if (fullAddress != null) {
      // Find by fullAddress if ID not provided
      final targetAddress = addresses.firstWhere(
        (addr) => addr['fullAddress'] == fullAddress,
        orElse: () => addresses.isNotEmpty ? addresses.first : {},
      );
      if (targetAddress.isEmpty) {
        print('Address not found for: $fullAddress');
        return;
      }
      targetId = targetAddress['id'];
    }

    if (targetId == null) {
      print('No address ID or fullAddress provided');
      return;
    }

    // Set all addresses to non-default, then set the target as default
    for (var addr in addresses) {
      await _addressesRef(
        user.uid,
      ).child(addr['id']).update({'isDefault': addr['id'] == targetId});
    }

    // Update local storage
    final defaultAddr = addresses.firstWhere(
      (addr) => addr['id'] == targetId,
      orElse: () => {},
    );
    if (defaultAddr.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'delivery_address',
        defaultAddr['fullAddress'] ?? '',
      );
      await prefs.setString(
        'delivery_address_label',
        (defaultAddr['label'] as String?)?.trim().isNotEmpty == true
            ? (defaultAddr['label'] as String).trim()
            : _deriveLabelFromAddress(defaultAddr['fullAddress'] as String?),
      );
    }
  }

  static String _deriveLabelFromAddress(String? fullAddress) {
    if (fullAddress == null || fullAddress.trim().isEmpty) {
      return 'Adresse';
    }
    final parts = fullAddress.split(',');
    if (parts.isNotEmpty) {
      final firstPart = parts.first.trim();
      if (firstPart.isNotEmpty) {
        return firstPart;
      }
    }
    return fullAddress.trim();
  }

  static Stream<Map<String, dynamic>?> defaultAddressStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _addressesRef(user.uid).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final addresses = data.entries.map((entry) {
        return {
          'id': entry.key.toString(),
          ...Map<String, dynamic>.from(entry.value as Map),
        };
      }).toList();

      final defaultAddr = addresses.firstWhere(
        (addr) => addr['isDefault'] == true,
        orElse: () =>
            addresses.isNotEmpty ? addresses.first : <String, dynamic>{},
      );

      if (defaultAddr.isEmpty) {
        return null;
      }

      return defaultAddr;
    });
  }

  static Future<void> updateAddress(
    String addressId,
    Map<String, dynamic> updates,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _addressesRef(user.uid).child(addressId).update(updates);
  }

  static Future<void> removeAddress(String addressId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _addressesRef(user.uid).child(addressId).remove();
  }

  static Future<bool> hasAddresses() async {
    final addresses = await getAddresses();
    return addresses.isNotEmpty;
  }
}
