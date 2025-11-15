import 'package:admin/services/realtime_database_service.dart';

class AlgeriaMarketSeeder {
  // High-level dataset: categories → subcategories → products with sample offers and images
  static final List<Map<String, dynamic>> _data = [
    {
      'categoryIcon': 'fruits',
      'categoryName': 'Fruits',
      'color': '#FF6B6B',
      'subs': [
        {
          'name': 'Pommes',
          'desc': 'Pomme locale',
          'products': [
            {
              'name': 'Pomme Golden 1kg',
              'desc': 'Pomme Golden locale 1kg',
              'offers': [200.0, 230.0, 240.0],
              'image':
                  'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?w=800',
            },
            {
              'name': 'Pomme Rouge 1kg',
              'desc': 'Pomme rouge 1kg',
              'offers': [220.0, 250.0],
              'image':
                  'https://images.unsplash.com/photo-1570913149827-d2ac84ab3f9a?w=800',
            },
          ],
        },
        {
          'name': 'Bananes',
          'desc': 'Banane importée',
          'products': [
            {
              'name': 'Banane 1kg',
              'desc': 'Banane importée 1kg',
              'offers': [240.0, 260.0, 280.0],
              'image':
                  'https://images.unsplash.com/photo-1571772805064-207c8435df79?w=800',
            },
          ],
        },
      ],
    },
    {
      'categoryIcon': 'vegetables',
      'categoryName': 'Légumes',
      'color': '#4ECDC4',
      'subs': [
        {
          'name': 'Tomates',
          'desc': 'Tomates fraîches',
          'products': [
            {
              'name': 'Tomate 1kg',
              'desc': 'Tomate de saison 1kg',
              'offers': [120.0, 150.0, 180.0],
              'image':
                  'https://images.unsplash.com/photo-1546470427-e26264be0df7?w=800',
            },
          ],
        },
        {
          'name': 'Pommes de terre',
          'desc': 'PDT',
          'products': [
            {
              'name': 'Pomme de terre 1kg',
              'desc': 'PDT 1kg',
              'offers': [80.0, 90.0, 100.0],
              'image':
                  'https://images.unsplash.com/photo-1604908554007-9e8b7b9b5e3f?w=800',
            },
          ],
        },
      ],
    },
    {
      'categoryIcon': 'meat',
      'categoryName': 'Viandes',
      'color': '#E74C3C',
      'subs': [
        {
          'name': 'Poulet',
          'desc': 'Poulet frais',
          'products': [
            {
              'name': 'Poulet entier 1kg',
              'desc': 'Poulet fermier',
              'offers': [420.0, 450.0, 480.0],
              'image':
                  'https://images.unsplash.com/photo-1604908554027-4517bb274507?w=800',
            },
          ],
        },
        {
          'name': 'Bœuf',
          'desc': 'Viande bovine',
          'products': [
            {
              'name': 'Viande hachée 1kg',
              'desc': 'Bœuf haché',
              'offers': [1200.0, 1300.0, 1250.0],
              'image':
                  'https://images.unsplash.com/photo-1558036117-15d82a90b9b6?w=800',
            },
          ],
        },
      ],
    },
    {
      'categoryIcon': 'bakery',
      'categoryName': 'Boulangerie',
      'color': '#F59E0B',
      'subs': [
        {
          'name': 'Pain',
          'desc': 'Pain traditionnel',
          'products': [
            {
              'name': 'Baguette',
              'desc': 'Baguette traditionnelle',
              'offers': [15.0, 20.0],
              'image':
                  'https://images.unsplash.com/photo-1608198093002-ad4e005484ec?w=800',
            },
          ],
        },
        {
          'name': 'Viennoiseries',
          'desc': 'Douceurs',
          'products': [
            {
              'name': 'Croissant',
              'desc': 'Croissant beurre',
              'offers': [40.0, 50.0],
              'image':
                  'https://images.unsplash.com/photo-1541599188778-b4d7e3f7c4a9?w=800',
            },
          ],
        },
      ],
    },
    {
      'categoryIcon': 'drinks',
      'categoryName': 'Boissons',
      'color': '#3B82F6',
      'subs': [
        {
          'name': 'Eau',
          'desc': 'Eau minérale',
          'products': [
            {
              'name': 'Eau minérale 1.5L',
              'desc': 'Bouteille d\'eau',
              'offers': [40.0, 50.0, 60.0],
              'image':
                  'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=800',
            },
          ],
        },
        {
          'name': 'Lait',
          'desc': 'Lait',
          'products': [
            {
              'name': 'Lait 1L',
              'desc': 'Lait pasteurisé 1L',
              'offers': [45.0, 55.0],
              'image':
                  'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800',
            },
          ],
        },
      ],
    },
  ];

  static double _mean(List<num> values) {
    if (values.isEmpty) return 0.0;
    final sum = values.fold<num>(0, (a, b) => a + b).toDouble();
    return sum / values.length;
  }

  // Idempotent seeding: creates categories/subcategories/products if missing
  static Future<void> seedAll() async {
    final existing = await RealtimeDatabaseService.getCategories();
    if (existing.isNotEmpty) {
      print('Seeder: Categories already present, skipping seeding.');
      return;
    }

    final Map<String, String> categoryIdByIcon = {};
    final Map<String, String> subIdByKey = {};

    for (final cat in _data) {
      final catId = await RealtimeDatabaseService.addCategoryWithCustomId(
        name: cat['categoryName'] as String,
        description: cat['categoryName'] as String,
        iconName: cat['categoryIcon'] as String,
        color: cat['color'] as String,
      );
      final categoryId = catId ?? '';
      categoryIdByIcon[cat['categoryIcon'] as String] = categoryId;

      // Subcategories
      for (final sub in (cat['subs'] as List)) {
        final subId = await RealtimeDatabaseService.addSubCategory(
          name: sub['name'] as String,
          description: sub['desc'] as String,
          categoryId: categoryId,
        );
        final subKey = '${cat['categoryIcon']}:${sub['name']}';
        subIdByKey[subKey] = subId ?? '';

        // Products with mean price and images
        for (final p in (sub['products'] as List)) {
          final meanPrice = _mean((p['offers'] as List).cast<num>());
          await RealtimeDatabaseService.addProduct(
            name: p['name'] as String,
            description: p['desc'] as String,
            price: meanPrice,
            imageUrl: p['image'] as String,
            categoryId: categoryId,
            subCategoryId: subIdByKey[subKey]!,
            availableUnits: const ['1kg'],
          );
        }
      }
    }
  }
}
