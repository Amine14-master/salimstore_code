import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'cart_service.dart';
import 'city_service.dart';
import 'wilaya_geo_service.dart';

class OrderService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
  );

  static DatabaseReference get _ordersRef => _db.ref('orders');
  static DatabaseReference get _orderCounterRef => _db.ref('orderCounter');

  /// Generate order ID in format: YYWW-BCXXXXX
  /// YY = Year (last 2 digits)
  /// WW = Wilaya code (2 digits)
  /// BC = Bon de Commande prefix
  /// XXXXX = Sequential order number (5 digits)
  static Future<String> _generateOrderId(String wilayaCode) async {
    try {
      // Get last 2 digits of current year
      final year = DateTime.now().year.toString().substring(2);

      // Get or create order counter for this wilaya
      final counterRef = _orderCounterRef.child('${year}_$wilayaCode');
      final counterSnap = await counterRef.get();

      int orderNumber = 1;
      if (counterSnap.exists) {
        final currentValue = counterSnap.value;
        if (currentValue is int) {
          orderNumber = currentValue + 1;
        } else if (currentValue is num) {
          orderNumber = currentValue.toInt() + 1;
        }
      }

      // Update counter
      await counterRef.set(orderNumber);

      // Format: YYWW-BCXXXXX
      final wilayaCodePadded = wilayaCode.padLeft(2, '0');
      final orderNumberPadded = orderNumber.toString().padLeft(5, '0');

      return '$year$wilayaCodePadded-BC$orderNumberPadded';
    } catch (e) {
      print('Error generating order ID: $e');
      // Fallback: use timestamp-based ID
      final year = DateTime.now().year.toString().substring(2);
      final wilayaCodePadded = wilayaCode.padLeft(2, '0');
      final timestamp = DateTime.now().millisecondsSinceEpoch
          .toString()
          .substring(7);
      return '$year$wilayaCodePadded-BC$timestamp';
    }
  }

  /// Get wilaya code from address (default: 06 for Béjaïa)
  static String _getWilayaCode({
    String? wilaya,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    String? code;

    if (latitude != null && longitude != null && WilayaGeoService.isLoaded()) {
      final match = WilayaGeoService.findByCoordinates(latitude, longitude);
      if (match != null && match.code.isNotEmpty) {
        code = match.code;
      }
    }

    if (code == null && wilaya != null && wilaya.isNotEmpty) {
      if (CityService.isLoaded()) {
        final normalized = CityService.getWilayaCode(wilaya);
        if (normalized != null && normalized.isNotEmpty) {
          code = normalized.toString();
        }
      }

      if (code == null) {
        final match = RegExp(r'\d+').firstMatch(wilaya);
        if (match != null) {
          code = match.group(0);
        }
      }
    }

    if (code == null && address != null && address.isNotEmpty) {
      final addressLower = address.toLowerCase();
      if (addressLower.contains('béjaïa') || addressLower.contains('bejaia')) {
        code = '06';
      } else if (addressLower.contains('alger') ||
          addressLower.contains('الجزائر')) {
        code = '16';
      } else if (addressLower.contains('oran')) {
        code = '31';
      } else if (addressLower.contains('tizi') ||
          addressLower.contains('ouzou')) {
        code = '15';
      }
    }

    code ??= '06';
    return code.padLeft(2, '0');
  }

  static Future<String?> createOrder({
    required List<CartItem> items,
    required double cartTotal,
    required double deliveryFee,
    required bool expressDelivery,
    required double expressFee,
    required double tip,
    required double total,
    String? deliveryAddress,
    String? deliveryLabel,
    String? wilaya,
    double? latitude,
    double? longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    await WilayaGeoService.ensureLoaded();

    // Generate order ID
    final wilayaCode = _getWilayaCode(
      wilaya: wilaya,
      address: deliveryAddress,
      latitude: latitude,
      longitude: longitude,
    );
    final orderId = await _generateOrderId(wilayaCode);

    final itemsData = items
        .map(
          (item) => {
            'productId': item.productId,
            'productName': item.productName,
            'quantity': item.quantity,
            'unit': item.unit,
            'unitPrice': item.unitPrice,
            'totalPrice': item.totalPrice,
            if (item.originalPrice != null) 'originalPrice': item.originalPrice,
            if (item.discountPercentage != null)
              'discountPercentage': item.discountPercentage,
          },
        )
        .toList();

    // Create order with generated ID
    final ref = _ordersRef.child(orderId);

    await ref.set({
      'orderId': orderId,
      'userId': user.uid,
      'items': itemsData,
      'cartTotal': cartTotal,
      'deliveryFee': deliveryFee,
      'expressDelivery': expressDelivery,
      'expressFee': expressFee,
      'tip': tip,
      'total': total,
      'currency': 'EUR',
      'status': 'pending',
      'deliveryAddress': deliveryAddress ?? 'Non spécifiée',
      if (deliveryLabel != null && deliveryLabel.isNotEmpty)
        'deliveryLabel': deliveryLabel,
      'wilaya': wilaya ?? '',
      'wilayaCode': wilayaCode,
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    });

    return orderId;
  }
}
