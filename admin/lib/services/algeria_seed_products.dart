import 'package:admin/services/realtime_database_service.dart';

class AlgeriaSeedProducts {
  static Future<void> seed() async {
    // Create base categories commonly used in Algerian markets
    final categories = [
      {'icon': 'fruits', 'label': 'Fruits', 'color': '#FF6B6B'},
      {'icon': 'vegetables', 'label': 'Légumes', 'color': '#4ECDC4'},
      {'icon': 'meat', 'label': 'Viandes', 'color': '#E74C3C'},
      {'icon': 'bakery', 'label': 'Boulangerie', 'color': '#F59E0B'},
      {'icon': 'drinks', 'label': 'Boissons', 'color': '#3B82F6'},
      {'icon': 'supermarket', 'label': 'Supermarché', 'color': '#3498DB'},
    ];

    final Map<String, String> categoryIdByIcon = {};

    for (final c in categories) {
      final id = await RealtimeDatabaseService.addCategoryWithCustomId(
        name: c['label']!,
        description: c['label']!,
        iconName: c['icon']!,
        color: c['color']!,
      );
      if (id != null) categoryIdByIcon[c['icon']!] = id;
    }

    // Subcategories
    final subs = [
      {'name': 'Pommes', 'desc': 'Pomme locale', 'cat': 'fruits'},
      {'name': 'Bananes', 'desc': 'Banane importée', 'cat': 'fruits'},
      {'name': 'Tomates', 'desc': 'Tomates fraîches', 'cat': 'vegetables'},
      {'name': 'Pommes de terre', 'desc': 'PDT', 'cat': 'vegetables'},
      {'name': 'Poulet', 'desc': 'Poulet frais', 'cat': 'meat'},
      {'name': 'Bœuf', 'desc': 'Viande bovine', 'cat': 'meat'},
      {'name': 'Pain', 'desc': 'Pain traditionnel', 'cat': 'bakery'},
      {'name': 'Lait', 'desc': 'Lait', 'cat': 'drinks'},
      {'name': 'Eau', 'desc': 'Eau minérale', 'cat': 'drinks'},
    ];

    final Map<String, String> subIdByName = {};
    for (final s in subs) {
      final catId = categoryIdByIcon[s['cat']!]!;
      final subId = await RealtimeDatabaseService.addSubCategory(
        name: s['name']!,
        description: s['desc']!,
        categoryId: catId,
      );
      if (subId != null) subIdByName[s['name']!] = subId;
    }

    // Products (sample)
    final products = [
      {
        'name': 'Pomme Golden 1kg',
        'desc': 'Pomme locale Golden',
        'price': 220.0,
        'sub': 'Pommes',
        'cat': 'fruits',
      },
      {
        'name': 'Tomate 1kg',
        'desc': 'Tomates de saison',
        'price': 150.0,
        'sub': 'Tomates',
        'cat': 'vegetables',
      },
      {
        'name': 'Poulet entier 1kg',
        'desc': 'Poulet fermier',
        'price': 450.0,
        'sub': 'Poulet',
        'cat': 'meat',
      },
      {
        'name': 'Pain baguette',
        'desc': 'Baguette traditionnelle',
        'price': 20.0,
        'sub': 'Pain',
        'cat': 'bakery',
      },
      {
        'name': 'Eau minérale 1.5L',
        'desc': 'Bouteille d\'eau',
        'price': 50.0,
        'sub': 'Eau',
        'cat': 'drinks',
      },
    ];

    for (final p in products) {
      final catId = categoryIdByIcon[p['cat']!]!;
      final subId = subIdByName[p['sub']!]!;
      await RealtimeDatabaseService.addProduct(
        name: p['name'] as String,
        description: p['desc'] as String,
        price: p['price'] as double,
        imageUrl: '',
        categoryId: catId,
        subCategoryId: subId,
        availableUnits: const ['1kg'],
      );
    }
  }
}
