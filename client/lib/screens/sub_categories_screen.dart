import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/product_models.dart';
import '../services/realtime_database_service.dart';
import '../theme/app_theme.dart';
import 'category_products_screen.dart';
import '../widgets/category_icon_view.dart';

class SubCategoriesScreen extends StatefulWidget {
  final Category category;

  const SubCategoriesScreen({super.key, required this.category});

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  bool _loading = true;
  List<SubCategory> _subCategories = [];

  @override
  void initState() {
    super.initState();
    _loadSubCategories();
  }

  Future<void> _loadSubCategories() async {
    setState(() => _loading = true);
    try {
      // Try fetching by categoryId first (more reliable if subCategoryIds list is missing)
      var subCats = await RealtimeDatabaseService.getSubCategoriesByCategoryId(
        widget.category.id,
      );

      // Fallback to IDs list if query returns empty but we have IDs
      if (subCats.isEmpty && widget.category.subCategoryIds.isNotEmpty) {
        subCats = await RealtimeDatabaseService.getSubCategoriesByIds(
          widget.category.subCategoryIds,
        );
      }

      if (mounted) {
        setState(() {
          _subCategories = subCats;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading subcategories: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _subCategories.isEmpty) {
      return CategoryProductsScreen(category: widget.category);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.9),
                      AppTheme.primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.category.description.isNotEmpty)
                            Text(
                              widget.category.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _iconForName(widget.category.iconName),
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
              ),

              // Subcategories Grid
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _subCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune sous-catégorie disponible',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1,
                            ),
                        itemCount: _subCategories.length,
                        itemBuilder: (context, index) {
                          final subCategory = _subCategories[index];
                          return _buildSubCategoryCard(
                            subCategory,
                            index,
                            AppTheme.primaryColor,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryCard(
    SubCategory subCategory,
    int index,
    Color categoryColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsScreen(
              category: widget.category,
              subCategory: subCategory,
            ),
          ),
        );
      },
      child:
          Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon centered in the card
                    Expanded(
                      child: Center(
                        child: CategoryIconView(
                          iconUrl: subCategory.imageUrl,
                          fallbackIcon: Icons.subdirectory_arrow_right_rounded,
                          size: 56,
                          fallbackColor: categoryColor,
                          borderRadius: 12,
                          showLoader: false,
                          overlayColor: Colors.transparent,
                          expandToFill: false,
                        ),
                      ),
                    ),
                    // Title at the bottom
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Text(
                        subCategory.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .fade(duration: 260.ms, delay: (index * 50).ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }

  IconData _iconForName(String iconName) {
    // Reuse the logic from home_tab or similar
    // For simplicity, using a basic mapping or the same function if I can extract it.
    // Since I cannot easily extract it right now without modifying other files, I'll copy a simplified version or the full one.
    // Better to copy the full one for consistency.
    switch (iconName.toLowerCase()) {
      case 'fruits':
      case 'fruit':
      case 'apple':
        return Icons.apple_rounded;
      case 'vegetables':
      case 'vegetable':
      case 'légumes':
      case 'legumes':
      case 'carrot':
      case 'carottes':
        return Icons.eco_rounded;
      case 'meat':
      case 'viandes':
      case 'viande':
        return Icons.set_meal_rounded;
      case 'seafood':
      case 'fruits de mer':
      case 'poisson':
        return Icons.water_drop_rounded;
      case 'bakery':
      case 'boulangerie':
      case 'bread':
      case 'pain':
        return Icons.bakery_dining_rounded;
      case 'dairy':
      case 'laiterie':
      case 'lait':
        return Icons.local_dining_rounded;
      case 'drinks':
      case 'drink':
      case 'boissons':
      case 'boisson':
        return Icons.local_drink_rounded;
      case 'coffee':
      case 'café':
      case 'cafe':
        return Icons.coffee_rounded;
      case 'juice':
      case 'jus':
        return Icons.local_bar_rounded;
      case 'frozen':
      case 'surgelé':
        return Icons.ac_unit_rounded;
      case 'ice cream':
      case 'glace':
        return Icons.icecream_rounded;
      case 'supermarket':
      case 'market':
      case 'grocery':
      case 'épicerie':
        return Icons.shopping_bag_rounded;
      case 'shopping_cart':
      case 'cart':
        return Icons.shopping_cart_rounded;
      case 'home':
      case 'maison':
      case 'household':
        return Icons.home_rounded;
      case 'cleaning':
      case 'nettoyage':
        return Icons.cleaning_services_rounded;
      case 'personal care':
      case 'soins personnels':
        return Icons.spa_rounded;
      case 'electronics':
      case 'électronique':
        return Icons.devices_rounded;
      case 'phones':
      case 'téléphones':
        return Icons.phone_android_rounded;
      case 'clothing':
      case 'vêtements':
      case 'vetements':
        return Icons.checkroom_rounded;
      case 'shoes':
      case 'chaussures':
        return Icons.directions_walk_rounded;
      case 'baby':
      case 'bébé':
      case 'bebe':
        return Icons.child_care_rounded;
      case 'toys':
      case 'jouets':
        return Icons.toys_rounded;
      case 'health':
      case 'santé':
      case 'sante':
        return Icons.medical_services_rounded;
      case 'pharmacy':
      case 'pharmacie':
        return Icons.local_pharmacy_rounded;
      case 'snacks':
      case 'gouter':
        return Icons.fastfood_rounded;
      case 'chocolate':
      case 'chocolat':
        return Icons.cookie_rounded;
      case 'candy':
      case 'bonbons':
        return Icons.cake_rounded;
      case 'sports':
      case 'sport':
        return Icons.sports_soccer_rounded;
      case 'outdoor':
        return Icons.directions_bike_rounded;
      case 'books':
      case 'livres':
        return Icons.menu_book_rounded;
      case 'stationery':
      case 'papeterie':
        return Icons.edit_rounded;
      case 'pets':
      case 'animaux':
        return Icons.pets_rounded;
      case 'automotive':
      case 'automobile':
        return Icons.directions_car_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
