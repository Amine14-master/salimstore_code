import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_models.dart';

class ProductService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Categories Collection
  static const String _categoriesCollection = 'categories';
  static const String _subCategoriesCollection = 'subCategories';
  static const String _productsCollection = 'products';

  // Get all categories
  static Future<List<Category>> getCategories() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_categoriesCollection)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map(
            (doc) => Category.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Get subcategories for a category
  static Future<List<SubCategory>> getSubCategories(String categoryId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_subCategoriesCollection)
          .where('categoryId', isEqualTo: categoryId)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map(
            (doc) => SubCategory.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      print('Error getting subcategories: $e');
      return [];
    }
  }

  // Get products for a subcategory
  static Future<List<Product>> getProducts(String subCategoryId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_productsCollection)
          .where('subCategoryId', isEqualTo: subCategoryId)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map(
            (doc) => Product.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  // Get all products (admin view)
  static Future<List<Product>> getAllProducts() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_productsCollection)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map(
            (doc) => Product.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }),
          )
          .toList();
    } catch (e) {
      print('Error getting all products: $e');
      return [];
    }
  }

  // Add new category
  static Future<String?> addCategory({
    required String name,
    required String description,
    required String iconName,
    required String color,
  }) async {
    try {
      print('ProductService: Adding category "$name"');

      final docRef = await _firestore.collection(_categoriesCollection).add({
        'name': name,
        'description': description,
        'iconName': iconName,
        'color': color,
        'subCategoryIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('ProductService: Category added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('ProductService: Error adding category: $e');
      rethrow; // Re-throw to get more detailed error info
    }
  }

  // Add new subcategory
  static Future<String?> addSubCategory({
    required String name,
    required String description,
    required String categoryId,
  }) async {
    try {
      final docRef = await _firestore.collection(_subCategoriesCollection).add({
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'productIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update category's subCategoryIds
      await _firestore.collection(_categoriesCollection).doc(categoryId).update(
        {
          'subCategoryIds': FieldValue.arrayUnion([docRef.id]),
        },
      );

      return docRef.id;
    } catch (e) {
      print('Error adding subcategory: $e');
      return null;
    }
  }

  // Add new product
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
      final docRef = await _firestore.collection(_productsCollection).add({
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
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update subcategory's productIds
      await _firestore
          .collection(_subCategoriesCollection)
          .doc(subCategoryId)
          .update({
            'productIds': FieldValue.arrayUnion([docRef.id]),
          });

      return docRef.id;
    } catch (e) {
      print('Error adding product: $e');
      return null;
    }
  }

  // Update product
  static Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection(_productsCollection).doc(productId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // Delete product
  static Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_productsCollection).doc(productId).delete();
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // Get predefined units for specific categories
  static List<String> getPredefinedUnits(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'fruits':
      case 'légumes':
      case 'viandes':
        return ['200g', '500g', '1kg', '2kg', '5kg'];
      default:
        return ['1 unit', '2 units', '5 units', '10 units'];
    }
  }

  // Initialize default categories
  static Future<void> initializeDefaultCategories() async {
    try {
      // Check if categories already exist
      final categoriesSnapshot = await _firestore
          .collection(_categoriesCollection)
          .get();
      if (categoriesSnapshot.docs.isNotEmpty) return;

      // Create default categories
      final defaultCategories = [
        {
          'name': 'Fruits',
          'description': 'Fresh fruits and seasonal produce',
          'iconName': 'apple',
          'color': '#FF6B6B',
        },
        {
          'name': 'Légumes',
          'description': 'Fresh vegetables and greens',
          'iconName': 'carrot',
          'color': '#4ECDC4',
        },
        {
          'name': 'Viandes',
          'description': 'Fresh meat and poultry',
          'iconName': 'meat',
          'color': '#45B7D1',
        },
        {
          'name': 'Supermarket',
          'description': 'General supermarket products',
          'iconName': 'shopping_cart',
          'color': '#96CEB4',
        },
      ];

      for (final categoryData in defaultCategories) {
        await addCategory(
          name: categoryData['name'] as String,
          description: categoryData['description'] as String,
          iconName: categoryData['iconName'] as String,
          color: categoryData['color'] as String,
        );
      }
    } catch (e) {
      print('Error initializing default categories: $e');
    }
  }
}
