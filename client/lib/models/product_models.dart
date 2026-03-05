class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String priceUnit; // Added field
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String categoryId;
  final String subCategoryId;
  final List<String> availableUnits;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? originalPrice;
  final double? discountPercentage;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.priceUnit = '1kg', // Added with default
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.categoryId,
    required this.subCategoryId,
    required this.availableUnits,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.originalPrice,
    this.discountPercentage,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    DateTime _parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    final dynamic rawImage =
        json['imageUrl'] ??
        json['imageURL'] ??
        json['image_url'] ??
        json['image'];
    final String imageUrl = (rawImage ?? '').toString().trim();

    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      priceUnit: json['priceUnit'] ?? '1kg',
      imageUrl: imageUrl,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      categoryId: json['categoryId'] ?? '',
      subCategoryId: json['subCategoryId'] ?? '',
      availableUnits: json['availableUnits'] != null
          ? List<String>.from(json['availableUnits'])
          : [],
      isAvailable: json['isAvailable'] ?? true,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
      discountPercentage: json['discountPercentage'] != null
          ? (json['discountPercentage'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'priceUnit': priceUnit,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'availableUnits': availableUnits,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (originalPrice != null) 'originalPrice': originalPrice,
      if (discountPercentage != null) 'discountPercentage': discountPercentage,
    };
  }
}

class Category {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String color;
  final String? iconUrl;
  final List<String> subCategoryIds;
  final DateTime createdAt;
  final int order;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.color,
    this.iconUrl,
    required this.subCategoryIds,
    required this.createdAt,
    this.order = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    DateTime _parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    // Handle subCategoryIds - could be a list or a map
    List<String> subCategoryIdsList = [];
    if (json['subCategoryIds'] != null) {
      if (json['subCategoryIds'] is List) {
        subCategoryIdsList = List<String>.from(json['subCategoryIds']);
      } else if (json['subCategoryIds'] is Map) {
        // If it's a map, extract values
        final map = json['subCategoryIds'] as Map;
        subCategoryIdsList = map.values.map((e) => e.toString()).toList();
      }
    }

    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'] ?? 'category',
      color: json['color'] ?? '#6366F1',
      iconUrl: json['iconUrl']?.toString(),
      subCategoryIds: subCategoryIdsList,
      createdAt: _parseDateTime(json['createdAt']),
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'color': color,
      'iconUrl': iconUrl,
      'subCategoryIds': subCategoryIds,
      'createdAt': createdAt.toIso8601String(),
      'order': order,
    };
  }
}

class SubCategory {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String? imageUrl;
  final List<String> productIds;
  final DateTime createdAt;

  SubCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    this.imageUrl,
    required this.productIds,
    required this.createdAt,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    DateTime _parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    // Handle productIds - could be a list or a map
    List<String> productIdsList = [];
    if (json['productIds'] != null) {
      if (json['productIds'] is List) {
        productIdsList = List<String>.from(json['productIds']);
      } else if (json['productIds'] is Map) {
        // If it's a map, extract values
        final map = json['productIds'] as Map;
        productIdsList = map.values.map((e) => e.toString()).toList();
      }
    }

    return SubCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      productIds: productIdsList,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'productIds': productIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
