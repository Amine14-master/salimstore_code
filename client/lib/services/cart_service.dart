import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final double
  unitPrice; // Price used for calculation (promotional or original)
  final double quantity;
  final String unit;
  final double? originalPrice; // Original price before promotion
  final double? discountPercentage; // Discount percentage if on promotion

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.unit,
    this.originalPrice,
    this.discountPercentage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'productImageUrl': productImageUrl,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'unit': unit,
    if (originalPrice != null) 'originalPrice': originalPrice,
    if (discountPercentage != null) 'discountPercentage': discountPercentage,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] ?? '',
    productId: json['productId'] ?? '',
    productName: json['productName'] ?? '',
    productImageUrl: json['productImageUrl'] ?? '',
    unitPrice: (json['unitPrice'] ?? 0).toDouble(),
    quantity: (json['quantity'] ?? 1).toDouble(),
    unit: json['unit'] ?? '',
    originalPrice: json['originalPrice'] != null
        ? (json['originalPrice'] as num).toDouble()
        : null,
    discountPercentage: json['discountPercentage'] != null
        ? (json['discountPercentage'] as num).toDouble()
        : null,
  );

  double get totalPrice => unitPrice * quantity;

  bool get isOnPromotion => originalPrice != null && discountPercentage != null;
}

class CartService {
  static const String _cartKey = 'user_cart';
  static final _cartController = StreamController<List<CartItem>>.broadcast();

  static Stream<List<CartItem>> cartStream() {
    // Initial load
    getCartItems().then((items) {
      _cartController.add(items);
    });
    return _cartController.stream;
  }

  static void _notifyCartChanged(List<CartItem> items) {
    _cartController.add(items);
  }

  static Future<List<CartItem>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    if (cartJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cartJson);
        return decoded
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error parsing cart: $e');
        return [];
      }
    }
    return [];
  }

  static Future<void> addToCart({
    required String productId,
    required String productName,
    required String productImageUrl,
    required double unitPrice,
    required double quantity,
    required String unit,
    double? originalPrice,
    double? discountPercentage,
  }) async {
    final items = await getCartItems();

    // Check if same product with same unit already exists
    final existingIndex = items.indexWhere(
      (item) => item.productId == productId && item.unit == unit,
    );

    if (existingIndex != -1) {
      // Update quantity
      items[existingIndex] = CartItem(
        id: items[existingIndex].id,
        productId: productId,
        productName: productName,
        productImageUrl: productImageUrl,
        unitPrice: unitPrice,
        quantity: items[existingIndex].quantity + quantity,
        unit: unit,
        originalPrice: originalPrice,
        discountPercentage: discountPercentage,
      );
    } else {
      // Add new item
      items.add(
        CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: productId,
          productName: productName,
          productImageUrl: productImageUrl,
          unitPrice: unitPrice,
          quantity: quantity,
          unit: unit,
          originalPrice: originalPrice,
          discountPercentage: discountPercentage,
        ),
      );
    }

    await _saveCart(items);
    _notifyCartChanged(items);
  }

  static Future<void> updateQuantity(String itemId, double newQuantity) async {
    final items = await getCartItems();
    final index = items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      if (newQuantity <= 0) {
        items.removeAt(index);
      } else {
        final existingItem = items[index];
        items[index] = CartItem(
          id: existingItem.id,
          productId: existingItem.productId,
          productName: existingItem.productName,
          productImageUrl: existingItem.productImageUrl,
          unitPrice: existingItem.unitPrice,
          quantity: newQuantity,
          unit: existingItem.unit,
          originalPrice: existingItem.originalPrice,
          discountPercentage: existingItem.discountPercentage,
        );
      }
      await _saveCart(items);
    }
  }

  static Future<void> removeFromCart(String itemId) async {
    final items = await getCartItems();
    items.removeWhere((item) => item.id == itemId);
    await _saveCart(items);
    _notifyCartChanged(items);
  }

  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
    _notifyCartChanged([]);
  }

  static Future<double> getTotal() async {
    final items = await getCartItems();
    return items.fold<double>(0, (sum, item) => sum + item.totalPrice);
  }

  static Future<void> _saveCart(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_cartKey, cartJson);
  }
}
