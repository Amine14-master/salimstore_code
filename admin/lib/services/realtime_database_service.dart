import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/product_models.dart';
import '../firebase_options.dart';

class CategoryAlreadyExistsException implements Exception {
  final String message;
  CategoryAlreadyExistsException(this.message);

  @override
  String toString() => message;
}

class RealtimeDatabaseService {
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
  );

  // Cache for categories to improve loading speed
  static List<Category>? _categoriesCache;
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  // Cache for subcategories to improve loading speed
  static Map<String, List<SubCategory>>? _subCategoriesCache;
  static DateTime? _lastSubCategoriesCacheUpdate;
  static const Duration _subCategoriesCacheValidityDuration = Duration(
    minutes: 5,
  );

  // Collection references
  static DatabaseReference get _categoriesRef => _database.ref('categories');
  static DatabaseReference get _subCategoriesRef =>
      _database.ref('subCategories');
  static DatabaseReference get _productsRef => _database.ref('products');
  static DatabaseReference get _promotionsRef => _database.ref('promotions');
  static DatabaseReference get _usersRef => _database.ref('users');
  static DatabaseReference get _ordersRef => _database.ref('orders');
  static DatabaseReference get _statsRef => _database.ref('stats');

  static List<String> _stringListFrom(dynamic source) {
    if (source == null) return [];
    if (source is Iterable) {
      return source
          .map((e) => e?.toString())
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .toList();
    }
    if (source is Map) {
      return source.values
          .map((e) => e?.toString())
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .toList();
    }
    return [];
  }

  static Map<String, dynamic> _mapFromSnapshot(dynamic value, String id) {
    if (value is Map) {
      return {'id': id, ...Map<String, dynamic>.from(value)};
    }
    return {'id': id};
  }

  static Future<List<Map<String, dynamic>>> getPromotions({
    bool? isActive,
  }) async {
    try {
      DataSnapshot snapshot;
      if (isActive != null) {
        try {
          snapshot = await _promotionsRef
              .orderByChild('isActive')
              .equalTo(isActive)
              .get();
        } catch (_) {
          snapshot = await _promotionsRef.get();
        }
      } else {
        snapshot = await _promotionsRef.get();
      }

      if (!snapshot.exists) return [];

      final Map<dynamic, dynamic> raw = Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );
      final promotions = raw.entries
          .where((entry) => entry.value != null)
          .map((entry) => _mapFromSnapshot(entry.value, entry.key.toString()))
          .where((promo) => isActive == null || promo['isActive'] == isActive)
          .toList();

      return promotions;
    } catch (e) {
      print('RealtimeDatabaseService: Error getting promotions: $e');
      return [];
    }
  }

  static Future<void> addPromotion({
    required String name,
    required double price,
    required double? originalPrice,
    required String imageUrl,
    required List<String> availableUnits,
    double? discountPercentage,
    bool isActive = true,
    String? productId,
  }) async {
    try {
      final newPromotion = _promotionsRef.push();
      final computedDiscount =
          discountPercentage ??
          ((originalPrice != null && originalPrice > 0 && price > 0)
              ? ((originalPrice - price) / originalPrice) * 100
              : null);
      await newPromotion.set({
        'name': name,
        'price': price,
        'originalPrice': originalPrice,
        'imageUrl': imageUrl,
        'availableUnits': availableUnits,
        'discountPercentage': computedDiscount,
        'isActive': isActive,
        'productId': productId,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('RealtimeDatabaseService: Error adding promotion: $e');
      rethrow;
    }
  }

  static Future<void> updatePromotion({
    required String promotionId,
    required String name,
    required double price,
    required double? originalPrice,
    required String imageUrl,
    required List<String> availableUnits,
    double? discountPercentage,
    bool? isActive,
    String? productId,
  }) async {
    try {
      final computedDiscount =
          discountPercentage ??
          ((originalPrice != null && originalPrice > 0 && price > 0)
              ? ((originalPrice - price) / originalPrice) * 100
              : null);
      await _promotionsRef.child(promotionId).update({
        'name': name,
        'price': price,
        'originalPrice': originalPrice,
        'imageUrl': imageUrl,
        'availableUnits': availableUnits,
        'discountPercentage': computedDiscount,
        'isActive': isActive,
        'productId': productId,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('RealtimeDatabaseService: Error updating promotion: $e');
      rethrow;
    }
  }

  static Future<void> removePromotion(String promotionId) async {
    try {
      await _promotionsRef.child(promotionId).remove();
    } catch (e) {
      print('RealtimeDatabaseService: Error removing promotion: $e');
      rethrow;
    }
  }

  // Categories CRUD
  static String categoryIdFromName(String name) => _slugify(name);

  static Future<bool> categoryExists(String categoryId) async {
    final snapshot = await _categoriesRef.child(categoryId).get();
    return snapshot.exists;
  }

  static Future<String?> addCategory({
    required String name,
    required String description,
    required String iconName,
    required String color,
  }) async {
    try {
      print('RealtimeDatabaseService: Adding category "$name"');

      final categoryRef = _categoriesRef.push();
      await categoryRef.set({
        'name': name,
        'description': description,
        'iconName': iconName,
        'color': color,
        'subCategoryIds': <String>[],
        'createdAt': ServerValue.timestamp,
      });

      // Clear cache when categories are modified
      _clearCategoriesCache();

      print(
        'RealtimeDatabaseService: Category added with ID: ${categoryRef.key}',
      );
      return categoryRef.key;
    } catch (e) {
      print('RealtimeDatabaseService: Error adding category: $e');
      rethrow;
    }
  }

  // Add category with custom ID (slug of name+icon)
  static Future<String?> addCategoryWithCustomId({
    required String name,
    required String description,
    required String iconName,
    required String color,
    String? iconUrl,
  }) async {
    try {
      final candidate = _slugify(name);

      final exists = await _categoriesRef.child(candidate).get();
      if (exists.exists) {
        throw CategoryAlreadyExistsException(
          'Une catégorie avec ce nom existe déjà.',
        );
      }

      await _categoriesRef.child(candidate).set({
        'name': name,
        'description': description,
        'iconName': iconName,
        'color': color,
        'subCategoryIds': <String>[],
        'createdAt': ServerValue.timestamp,
        if (iconUrl != null) 'iconUrl': iconUrl,
      });

      _clearCategoriesCache();
      return candidate;
    } catch (e) {
      print(
        'RealtimeDatabaseService: Error adding category with custom id: $e',
      );
      rethrow;
    }
  }

  static String _slugify(String input) {
    final lower = input.toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final collapsed = cleaned.replaceAll(RegExp(r'-{2,}'), '-');
    final trimmed = collapsed.replaceAll(RegExp(r'^-+|-+$'), '');
    return trimmed.isEmpty ? 'category' : trimmed;
  }

  static Future<List<Category>> getCategories() async {
    try {
      // Check cache first
      if (_categoriesCache != null &&
          _lastCacheUpdate != null &&
          DateTime.now().difference(_lastCacheUpdate!) <
              _cacheValidityDuration) {
        print(
          'RealtimeDatabaseService: Returning cached categories (${_categoriesCache!.length})',
        );
        return _categoriesCache!;
      }

      print('RealtimeDatabaseService: Fetching categories from database...');
      final snapshot = await _categoriesRef.get();

      if (!snapshot.exists) {
        print('RealtimeDatabaseService: No categories found');
        _categoriesCache = [];
        _lastCacheUpdate = DateTime.now();
        return [];
      }

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      print('RealtimeDatabaseService: Found ${data.length} categories');

      final categories = <Category>[];

      for (final entry in data.entries) {
        if (entry.value == null) continue;

        try {
          final categoryData = entry.value as Map<dynamic, dynamic>;

          // Quick validation
          if (categoryData['name'] == null ||
              categoryData['name'].toString().isEmpty) {
            continue;
          }

          final category = Category.fromJson({
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
          });

          categories.add(category);
        } catch (e) {
          print(
            'RealtimeDatabaseService: Error parsing category ${entry.key}: $e',
          );
          // Remove corrupted entry asynchronously
          _categoriesRef.child(entry.key.toString()).remove().catchError((
            error,
          ) {
            print('Error removing corrupted entry: $error');
          });
        }
      }

      // Update cache
      _categoriesCache = categories;
      _lastCacheUpdate = DateTime.now();

      print(
        'RealtimeDatabaseService: Returning ${categories.length} categories',
      );
      return categories;
    } catch (e) {
      print('RealtimeDatabaseService: Error getting categories: $e');
      return _categoriesCache ?? [];
    }
  }

  // Clear cache when categories are modified
  static void _clearCategoriesCache() {
    _categoriesCache = null;
    _lastCacheUpdate = null;
    _subCategoriesCache = null;
    _lastSubCategoriesCacheUpdate = null;
  }

  // Clear subcategories cache
  static void _clearSubCategoriesCache() {
    _subCategoriesCache = null;
    _lastSubCategoriesCacheUpdate = null;
  }

  static Future<bool> updateCategory(
    String categoryId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _categoriesRef.child(categoryId).update(updates);
      _clearCategoriesCache();
      return true;
    } catch (e) {
      print('Error updating category: $e');
      return false;
    }
  }

  static Future<bool> deleteCategory(String categoryId) async {
    try {
      await _categoriesRef.child(categoryId).remove();
      _clearCategoriesCache();
      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  // Deep delete: remove subcategories and products belonging to a category, then the category
  static Future<bool> deleteCategoryDeep(String categoryId) async {
    try {
      // fetch subcategories of this category
      final subSnap = await _subCategoriesRef
          .orderByChild('categoryId')
          .equalTo(categoryId)
          .get();

      if (subSnap.exists) {
        final Map<dynamic, dynamic> subs = Map<dynamic, dynamic>.from(
          subSnap.value as Map,
        );
        for (final entry in subs.entries) {
          final subId = entry.key.toString();
          // delete products under this subcategory
          final prodSnap = await _productsRef
              .orderByChild('subCategoryId')
              .equalTo(subId)
              .get();
          if (prodSnap.exists) {
            final Map<dynamic, dynamic> prods = Map<dynamic, dynamic>.from(
              prodSnap.value as Map,
            );
            for (final p in prods.entries) {
              await _productsRef.child(p.key.toString()).remove();
            }
          }
          // delete subcategory itself
          await _subCategoriesRef.child(subId).remove();
        }
      }

      // finally remove category
      await _categoriesRef.child(categoryId).remove();
      _clearCategoriesCache();
      return true;
    } catch (e) {
      print('Error deep deleting category: $e');
      return false;
    }
  }

  // SubCategories CRUD
  static Future<String?> addSubCategory({
    required String name,
    required String description,
    required String categoryId,
  }) async {
    try {
      print('RealtimeDatabaseService: Adding subcategory "$name"');

      final subCategoryRef = _subCategoriesRef.push();
      await subCategoryRef.set({
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'productIds': <String>[],
        'createdAt': ServerValue.timestamp,
      });

      // Update category's subCategoryIds
      await _categoriesRef
          .child(categoryId)
          .child('subCategoryIds')
          .push()
          .set(subCategoryRef.key);

      // Clear subcategories cache
      _clearSubCategoriesCache();

      print(
        'RealtimeDatabaseService: Subcategory added with ID: ${subCategoryRef.key}',
      );
      return subCategoryRef.key;
    } catch (e) {
      print('RealtimeDatabaseService: Error adding subcategory: $e');
      rethrow;
    }
  }

  static Future<List<SubCategory>> getSubCategories(String categoryId) async {
    try {
      // Check cache first
      if (_subCategoriesCache != null &&
          _lastSubCategoriesCacheUpdate != null &&
          DateTime.now().difference(_lastSubCategoriesCacheUpdate!) <
              _subCategoriesCacheValidityDuration) {
        final cached = _subCategoriesCache![categoryId];
        if (cached != null) {
          print(
            'RealtimeDatabaseService: Returning cached subcategories for $categoryId',
          );
          return cached;
        }
      }

      print('RealtimeDatabaseService: Fetching subcategories for $categoryId');
      final snapshot = await _subCategoriesRef
          .orderByChild('categoryId')
          .equalTo(categoryId)
          .get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        final subcategories = data.entries
            .where((entry) => entry.value != null)
            .map((entry) {
              return SubCategory.fromJson({
                'id': entry.key,
                ...Map<String, dynamic>.from(entry.value as Map),
              });
            })
            .toList();

        // Update cache
        _subCategoriesCache ??= {};
        _subCategoriesCache![categoryId] = subcategories;
        _lastSubCategoriesCacheUpdate = DateTime.now();

        return subcategories;
      }
      return [];
    } catch (e) {
      print('Error getting subcategories: $e');
      return _subCategoriesCache?[categoryId] ?? [];
    }
  }

  // Get all subcategories at once (for hierarchical view)
  static Future<Map<String, List<SubCategory>>> getAllSubCategories() async {
    try {
      // Check if we should return from cache
      if (_subCategoriesCache != null &&
          _lastSubCategoriesCacheUpdate != null &&
          DateTime.now().difference(_lastSubCategoriesCacheUpdate!) <
              _subCategoriesCacheValidityDuration) {
        print('RealtimeDatabaseService: Returning cached all subcategories');
        return _subCategoriesCache!;
      }

      print('RealtimeDatabaseService: Fetching all subcategories');
      final snapshot = await _subCategoriesRef.get();

      if (!snapshot.exists) {
        _subCategoriesCache = {};
        _lastSubCategoriesCacheUpdate = DateTime.now();
        return {};
      }

      final Map<dynamic, dynamic> data =
          snapshot.value as Map<dynamic, dynamic>;
      final Map<String, List<SubCategory>> result = {};

      for (final entry in data.entries) {
        if (entry.value == null) continue;

        try {
          final subcategoryData = entry.value as Map<dynamic, dynamic>;
          final categoryId = subcategoryData['categoryId']?.toString();

          if (categoryId != null) {
            result.putIfAbsent(categoryId, () => []);
            result[categoryId]!.add(
              SubCategory.fromJson({
                'id': entry.key.toString(),
                ...Map<String, dynamic>.from(subcategoryData),
              }),
            );
          }
        } catch (e) {
          print('Error parsing subcategory ${entry.key}: $e');
        }
      }

      // Update cache
      _subCategoriesCache = result;
      _lastSubCategoriesCacheUpdate = DateTime.now();

      return result;
    } catch (e) {
      print('Error getting all subcategories: $e');
      return _subCategoriesCache ?? {};
    }
  }

  static Future<bool> updateSubCategory(
    String subCategoryId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _subCategoriesRef.child(subCategoryId).update(updates);
      _clearSubCategoriesCache();
      return true;
    } catch (e) {
      print('Error updating subcategory: $e');
      return false;
    }
  }

  static Future<bool> deleteSubCategory(String subCategoryId) async {
    try {
      await _subCategoriesRef.child(subCategoryId).remove();
      _clearSubCategoriesCache();
      return true;
    } catch (e) {
      print('Error deleting subcategory: $e');
      return false;
    }
  }

  // Products CRUD
  static Future<String?> addProduct({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String categoryId,
    required String subCategoryId,
    required List<String> availableUnits,
  }) async {
    try {
      print('RealtimeDatabaseService: Adding product "$name"');

      final productRef = _productsRef.push();
      await productRef.set({
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'rating': 0.0,
        'reviewCount': 0,
        'categoryId': categoryId,
        'subCategoryId': subCategoryId,
        'availableUnits': availableUnits,
        'isAvailable': true,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });

      // Update subcategory's productIds
      await _subCategoriesRef
          .child(subCategoryId)
          .child('productIds')
          .push()
          .set(productRef.key);

      print(
        'RealtimeDatabaseService: Product added with ID: ${productRef.key}',
      );
      return productRef.key;
    } catch (e) {
      print('RealtimeDatabaseService: Error adding product: $e');
      rethrow;
    }
  }

  static Future<List<Product>> getProducts(String subCategoryId) async {
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
            'id': entry.key,
            ...Map<String, dynamic>.from(entry.value as Map),
          });
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting products: $e');
      // Temporary fallback if index is missing: fetch all and filter client-side
      try {
        final all = await getAllProducts();
        return all.where((p) => p.subCategoryId == subCategoryId).toList();
      } catch (_) {
        return [];
      }
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
            'id': entry.key,
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
            'id': entry.key,
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

  static Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _productsRef.child(productId).update({
        ...updates,
        'updatedAt': ServerValue.timestamp,
      });
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  static Future<void> moveProductToSubCategory({
    required String productId,
    required String newSubCategoryId,
    required String? oldSubCategoryId,
  }) async {
    try {
      if (oldSubCategoryId != null && oldSubCategoryId.isNotEmpty) {
        final existing = await _subCategoriesRef
            .child(oldSubCategoryId)
            .child('productIds')
            .get();
        if (existing.exists && existing.value is Map) {
          final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(
            existing.value as Map,
          );
          for (final entry in data.entries) {
            if (entry.value == productId) {
              await _subCategoriesRef
                  .child(oldSubCategoryId)
                  .child('productIds')
                  .child(entry.key.toString())
                  .remove();
            }
          }
        }
      }

      await _subCategoriesRef
          .child(newSubCategoryId)
          .child('productIds')
          .push()
          .set(productId);

      _clearSubCategoriesCache();
    } catch (e) {
      print('Error moving product between subcategories: $e');
    }
  }

  static Future<bool> deleteProduct(String productId) async {
    try {
      await _productsRef.child(productId).remove();
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // Statistics
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final snapshot = await _statsRef.get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return {
        'totalUsers': 0,
        'totalProducts': 0,
        'totalOrders': 0,
        'totalRevenue': 0.0,
      };
    } catch (e) {
      print('Error getting stats: $e');
      return {
        'totalUsers': 0,
        'totalProducts': 0,
        'totalOrders': 0,
        'totalRevenue': 0.0,
      };
    }
  }

  static Future<void> updateStats() async {
    try {
      // Count users
      final usersSnapshot = await _usersRef.get();
      final totalUsers = usersSnapshot.exists
          ? (usersSnapshot.value as Map).length
          : 0;

      // Count products
      final productsSnapshot = await _productsRef.get();
      final totalProducts = productsSnapshot.exists
          ? (productsSnapshot.value as Map).length
          : 0;

      // Count orders and calculate revenue
      final ordersSnapshot = await _ordersRef.get();
      int totalOrders = 0;
      double totalRevenue = 0.0;

      if (ordersSnapshot.exists) {
        final orders = ordersSnapshot.value as Map;
        totalOrders = orders.length;
        orders.forEach((key, value) {
          if (value is Map && value['total'] != null) {
            totalRevenue += (value['total'] as num).toDouble();
          }
        });
      }

      await _statsRef.set({
        'totalUsers': totalUsers,
        'totalProducts': totalProducts,
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'lastUpdated': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating stats: $e');
    }
  }

  // Initialize default categories (MERGE: add only missing ones)
  static Future<void> initializeDefaultCategories() async {
    try {
      // Fetch current categories
      final categoriesSnapshot = await _categoriesRef.get();
      Map existingNamesIcons = {};
      if (categoriesSnapshot.exists && categoriesSnapshot.value is Map) {
        (categoriesSnapshot.value as Map).forEach((key, value) {
          if (value != null &&
              value is Map &&
              value['name'] != null &&
              value['iconName'] != null) {
            final name = value['name'].toString().trim().toLowerCase();
            final icon = value['iconName'].toString().trim().toLowerCase();
            existingNamesIcons['$name::$icon'] = true;
          }
        });
      }

      final defaultCategories = [
        {
          'name': 'Fruits',
          'description': 'Fresh fruits and seasonal produce',
          'iconName': 'fruits',
          'color': '#FF6B6B',
        },
        {
          'name': 'Légumes',
          'description': 'Fresh vegetables and greens',
          'iconName': 'vegetables',
          'color': '#4ECDC4',
        },
        {
          'name': 'Viandes',
          'description': 'Fresh meat and poultry',
          'iconName': 'meat',
          'color': '#E74C3C',
        },
        {
          'name': 'Supermarket',
          'description': 'General supermarket products',
          'iconName': 'supermarket',
          'color': '#3498DB',
        },
      ];

      for (final categoryData in defaultCategories) {
        final name = categoryData['name'].toString().trim().toLowerCase();
        final icon = categoryData['iconName'].toString().trim().toLowerCase();
        if (!existingNamesIcons.containsKey('$name::$icon')) {
          await addCategory(
            name: categoryData['name'] as String,
            description: categoryData['description'] as String,
            iconName: categoryData['iconName'] as String,
            color: categoryData['color'] as String,
          );
        }
      }
    } catch (e) {
      print('Error initializing default categories: $e');
    }
  }

  // Clean up null entries
  static Future<void> cleanupNullEntries() async {
    try {
      print('RealtimeDatabaseService: Cleaning up null entries...');
      final snapshot = await _categoriesRef.get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        final nullKeys = data.entries
            .where((entry) => entry.value == null)
            .map((entry) => entry.key)
            .toList();

        if (nullKeys.isNotEmpty) {
          print(
            'RealtimeDatabaseService: Removing ${nullKeys.length} null entries',
          );
          for (final key in nullKeys) {
            await _categoriesRef.child(key.toString()).remove();
          }
        }
      }
    } catch (e) {
      print('RealtimeDatabaseService: Error cleaning up null entries: $e');
    }
  }

  // Test connection
  static Future<bool> testConnection() async {
    try {
      print('RealtimeDatabaseService: Testing connection...');
      final testRef = _database.ref('test');
      await testRef.set({
        'test': 'connection',
        'timestamp': ServerValue.timestamp,
      });
      final snapshot = await testRef.get();
      print('RealtimeDatabaseService: Test successful: ${snapshot.value}');
      await testRef.remove();
      return true;
    } catch (e) {
      print('RealtimeDatabaseService: Test failed: $e');
      return false;
    }
  }

  // Reset all categories data
  static Future<void> resetCategoriesData() async {
    try {
      print('RealtimeDatabaseService: Resetting categories data...');
      await _categoriesRef.remove();
      print(
        'RealtimeDatabaseService: Categories data cleared - ready for manual creation',
      );
    } catch (e) {
      print('RealtimeDatabaseService: Error resetting categories data: $e');
    }
  }
}
