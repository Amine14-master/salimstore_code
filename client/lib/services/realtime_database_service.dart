import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/product_models.dart';

class RealtimeDatabaseService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static DatabaseReference get _categoriesRef => _database.ref('categories');
  static DatabaseReference get _productsRef => _database.ref('products');
  static DatabaseReference get _promotionsRef => _database.ref('promotions');

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
              }),
            );
          } catch (e) {
            print('Error parsing category: $e');
          }
        }
        // Sort by creation date (newest first)
        categories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
        }).toList();
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
        }).toList();
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
      // Try with index first
      try {
        final snapshot = await _promotionsRef
            .orderByChild('isActive')
            .equalTo(true)
            .get();
        if (snapshot.exists) {
          final Map<dynamic, dynamic> data =
              snapshot.value as Map<dynamic, dynamic>;
          return data.entries
              .where((entry) => entry.value != null)
              .map((entry) {
                final promoData = Map<String, dynamic>.from(entry.value as Map);
                return {'id': entry.key.toString(), ...promoData};
              })
              .where((promo) => promo['isActive'] == true)
              .toList();
        }
      } catch (e) {
        print('Index query failed, using fallback: $e');
        // Fallback: Get all promotions and filter client-side
        final snapshot = await _promotionsRef.get();
        if (snapshot.exists) {
          final Map<dynamic, dynamic> data =
              snapshot.value as Map<dynamic, dynamic>;
          return data.entries
              .where((entry) => entry.value != null)
              .map((entry) {
                final promoData = Map<String, dynamic>.from(entry.value as Map);
                return {'id': entry.key.toString(), ...promoData};
              })
              .where((promo) => promo['isActive'] == true)
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting promotions: $e');
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
              }),
            );
          } catch (e) {
            print('Error parsing category: $e');
          }
        }
        categories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
        }).toList();
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
            }).toList();
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
        }).toList();
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
            }).toList();
          }
          return [];
        });
  }
}
