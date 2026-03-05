List<String> _parseStringList(dynamic source) {
  if (source == null) return [];
  if (source is Iterable) {
    return source
        .map((e) => e?.toString())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toList();
  }
  if (source is Map) {
    return source.values
        .map((e) => e?.toString())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return [];
}

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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      priceUnit: json['priceUnit'] ?? '1kg',
      imageUrl: json['imageUrl'],
      rating: json['rating'].toDouble(),
      reviewCount: json['reviewCount'],
      categoryId: json['categoryId'],
      subCategoryId: json['subCategoryId'],
      availableUnits: _parseStringList(json['availableUnits']),
      isAvailable: json['isAvailable'] ?? true,
      createdAt: json['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : DateTime.now(),
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
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconName: json['iconName'],
      color: json['color'],
      iconUrl: json['iconUrl'],
      subCategoryIds: _parseStringList(json['subCategoryIds']),
      createdAt: json['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
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
    return SubCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      categoryId: json['categoryId'],
      imageUrl: json['imageUrl'],
      productIds: _parseStringList(json['productIds']),
      createdAt: json['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
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
