import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/product_models.dart';

class RealtimeDatabaseService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static DatabaseReference get _categoriesRef => _database.ref('categories');
  static DatabaseReference get _productsRef => _database.ref('products');
  static DatabaseReference get _promotionsRef => _database.ref('promotions');
  static DatabaseReference get _settingsRef => _database.ref('settings');

  static Map<String, dynamic> _normalizeSnapshotMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    if (value is List) {
      final result = <String, dynamic>{};
      for (var i = 0; i < value.length; i++) {
        final item = value[i];
        if (item != null) {
          result[i.toString()] = item;
        }
      }
      return result;
    }
    return {};
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  static Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _categoriesRef.get();
      if (snapshot.exists) {
        final data = _normalizeSnapshotMap(snapshot.value);
        final categories = <Category>[];
        for (final entry in data.entries) {
          if (entry.value == null) continue;
          try {
            final categoryData = _asMap(entry.value);
            if (categoryData['name'] == null ||
                categoryData['name'].toString().isEmpty)
              continue;
            categories.add(
              Category.fromJson({
                'id': entry.key.toString(),
                'name': categoryData['name']?.toString() ?? '',
                'description': categoryData['description']?.toString() ?? '',
                'iconName': categoryData['iconName']?.toString() ?? 'category',
                'color': categoryData['color']?.toString() ?? '#6366F1',
                'iconUrl': categoryData['iconUrl']?.toString(),
                'subCategoryIds': categoryData['subCategoryIds'] ?? [],
                'createdAt':
                    categoryData['createdAt'] ??
                    DateTime.now().millisecondsSinceEpoch,
                'order': categoryData['order'] ?? 0,
              }),
            );
          } catch (e) {
            print('Error parsing category: $e');
          }
        }
        // Sort by order ascending
        categories.sort((a, b) => a.order.compareTo(b.order));
        print('Client: Loaded ${categories.length} categories');
        return categories;
      }
      return [];
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  static Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _productsRef.get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        return data.entries.where((entry) => entry.value != null).map((entry) {
          return Product.fromJson({
            'id': entry.key.toString(),
            ...Map<String, dynamic>.from(entry.value as Map),
          });
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return [];
    } catch (e) {
      print('Error getting all products: $e');
      return [];
    }
  }

  static Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final snapshot = await _productsRef
          .orderByChild('categoryId')
          .equalTo(categoryId)
          .get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        return data.entries.where((entry) => entry.value != null).map((entry) {
          return Product.fromJson({
            'id': entry.key.toString(),
            ...Map<String, dynamic>.from(entry.value as Map),
          });
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return [];
    } catch (e) {
      print('Error getting products by category: $e');
      // Fallback if index missing
      try {
        final all = await getAllProducts();
        return all.where((p) => p.categoryId == categoryId).toList();
      } catch (_) {
        return [];
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getPromotions() async {
    try {
      print('RealtimeDatabaseService(Client): Fetching active promotions...');
      final snapshot = await _promotionsRef.get();

      if (!snapshot.exists) {
        print('RealtimeDatabaseService(Client): No promotions table found');
        return [];
      }

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;

      final activePromotions = data.entries
          .where((entry) => entry.value != null)
          .map((entry) {
            final promoData = Map<String, dynamic>.from(entry.value as Map);
            return {'id': entry.key.toString(), ...promoData};
          })
          .where((promo) {
            // Be resilient: default to active if null to avoid disappearing items
            final bool isActive = promo['isActive'] ?? true;
            return isActive == true;
          })
          .toList();

      print(
        'RealtimeDatabaseService(Client): Found ${activePromotions.length} active promotions',
      );
      return activePromotions;
    } catch (e) {
      print('RealtimeDatabaseService(Client): Error getting promotions: $e');
      return [];
    }
  }

  // Real-time stream methods
  static Stream<List<Category>> categoriesStream() {
    return _categoriesRef.onValue.map((event) {
      if (event.snapshot.exists) {
        final data = _normalizeSnapshotMap(event.snapshot.value);
        final categories = <Category>[];
        for (final entry in data.entries) {
          if (entry.value == null) continue;
          try {
            final categoryData = _asMap(entry.value);
            if (categoryData['name'] == null ||
                categoryData['name'].toString().isEmpty)
              continue;
            categories.add(
              Category.fromJson({
                'id': entry.key.toString(),
                'name': categoryData['name']?.toString() ?? '',
                'description': categoryData['description']?.toString() ?? '',
                'iconName': categoryData['iconName']?.toString() ?? 'category',
                'color': categoryData['color']?.toString() ?? '#6366F1',
                'iconUrl': categoryData['iconUrl']?.toString(),
                'subCategoryIds': categoryData['subCategoryIds'] ?? [],
                'createdAt':
                    categoryData['createdAt'] ??
                    DateTime.now().millisecondsSinceEpoch,
                'order': categoryData['order'] ?? 0,
              }),
            );
          } catch (e) {
            print('Error parsing category: $e');
          }
        }
        categories.sort((a, b) => a.order.compareTo(b.order));
        return categories;
      }
      return [];
    });
  }

  static Stream<List<Product>> productsStream() {
    return _productsRef.onValue.map((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        return data.entries.where((entry) => entry.value != null).map((entry) {
          return Product.fromJson({
            'id': entry.key.toString(),
            ...Map<String, dynamic>.from(entry.value as Map),
          });
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return [];
    });
  }

  static Stream<List<Product>> productsByCategoryStream(String categoryId) {
    return _productsRef
        .orderByChild('categoryId')
        .equalTo(categoryId)
        .onValue
        .handleError((error) {
          print('Error in productsByCategoryStream: $error');
          // Fallback: return empty list on error
        })
        .map((event) {
          if (event.snapshot.exists) {
            final Map<dynamic, dynamic> data =
                event.snapshot.value as Map<dynamic, dynamic>;
            return data.entries.where((entry) => entry.value != null).map((
              entry,
            ) {
              return Product.fromJson({
                'id': entry.key.toString(),
                ...Map<String, dynamic>.from(entry.value as Map),
              });
            }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
          return [];
        });
  }

  static Stream<List<Map<String, dynamic>>> promotionsStream() {
    return _promotionsRef.onValue.map((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;
        return data.entries
            .where((entry) => entry.value != null)
            .map((entry) {
              final promoData = Map<String, dynamic>.from(entry.value as Map);
              return {'id': entry.key.toString(), ...promoData};
            })
            .where((promo) => promo['isActive'] == true)
            .toList();
      }
      return [];
    });
  }

  static DatabaseReference get _subCategoriesRef =>
      _database.ref('subCategories');

  // ... existing methods ...

  static Future<List<SubCategory>> getSubCategoriesByIds(
    List<String> ids,
  ) async {
    try {
      if (ids.isEmpty) return [];

      final futures = ids.map((id) => _subCategoriesRef.child(id).get());
      final snapshots = await Future.wait(futures);

      final subCategories = <SubCategory>[];
      for (final snapshot in snapshots) {
        if (snapshot.exists && snapshot.value != null) {
          try {
            final data = _asMap(snapshot.value);
            subCategories.add(
              SubCategory.fromJson({'id': snapshot.key.toString(), ...data}),
            );
          } catch (e) {
            print('Error parsing subcategory ${snapshot.key}: $e');
          }
        }
      }
      return subCategories;
    } catch (e) {
      print('Error getting subcategories: $e');
      return [];
    }
  }

  static Future<List<SubCategory>> getSubCategoriesByCategoryId(
    String categoryId,
  ) async {
    try {
      final snapshot = await _subCategoriesRef
          .orderByChild('categoryId')
          .equalTo(categoryId)
          .get();

      if (snapshot.exists) {
        final data = _normalizeSnapshotMap(snapshot.value);
        final subCategories = <SubCategory>[];
        for (final entry in data.entries) {
          if (entry.value == null) continue;
          try {
            final subCatData = _asMap(entry.value);
            subCategories.add(
              SubCategory.fromJson({'id': entry.key.toString(), ...subCatData}),
            );
          } catch (e) {
            print('Error parsing subcategory ${entry.key}: $e');
          }
        }
        return subCategories;
      }
      return [];
    } catch (e) {
      print('Error getting subcategories by category: $e');
      return [];
    }
  }

  static Future<List<Product>> getProductsBySubCategory(
    String subCategoryId,
  ) async {
    try {
      final snapshot = await _productsRef
          .orderByChild('subCategoryId')
          .equalTo(subCategoryId)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        return data.entries.where((entry) => entry.value != null).map((entry) {
          return Product.fromJson({
            'id': entry.key.toString(),
            ...Map<String, dynamic>.from(entry.value as Map),
          });
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      return [];
    } catch (e) {
      print('Error getting products by subcategory: $e');
      // Fallback: fetch all and filter
      try {
        final all = await getAllProducts();
        return all.where((p) => p.subCategoryId == subCategoryId).toList();
      } catch (_) {
        return [];
      }
    }
  }

  static Stream<List<Product>> productsBySubCategoryStream(
    String subCategoryId,
  ) {
    return _productsRef
        .orderByChild('subCategoryId')
        .equalTo(subCategoryId)
        .onValue
        .handleError((error) {
          print('Error in productsBySubCategoryStream: $error');
        })
        .map((event) {
          if (event.snapshot.exists) {
            final Map<dynamic, dynamic> data =
                event.snapshot.value as Map<dynamic, dynamic>;
            return data.entries.where((entry) => entry.value != null).map((
              entry,
            ) {
              return Product.fromJson({
                'id': entry.key.toString(),
                ...Map<String, dynamic>.from(entry.value as Map),
              });
            }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
          return [];
        });
  }

  static Future<Map<String, dynamic>> getDeliveryPrices() async {
    try {
      final snapshot = await _settingsRef.child('deliveryPrices').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return {'bejaiaCityFee': 3.49, 'otherWilayaFee': 8.99};
    } catch (e) {
      print('Error getting delivery prices: $e');
      return {'bejaiaCityFee': 3.49, 'otherWilayaFee': 8.99};
    }
  }

  static Stream<Map<String, dynamic>> deliveryPricesStream() {
    return _settingsRef.child('deliveryPrices').onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {'bejaiaCityFee': 3.49, 'otherWilayaFee': 8.99};
    });
  }
}
