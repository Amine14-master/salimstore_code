import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pill_page_header.dart';
import '../../services/realtime_database_service.dart';
import '../../models/product_models.dart';
import '../category_products_screen.dart';
import '../../widgets/category_icon_view.dart';

class CategoriesTab extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const CategoriesTab({super.key, this.onBackToHome});
  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  bool _loading = true;
  List<Category> _categories = [];
  StreamSubscription<List<Category>>? _categoriesSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListener() {
    setState(() => _loading = true);
    _categoriesSubscription = RealtimeDatabaseService.categoriesStream().listen(
      (categories) {
        if (mounted) {
          setState(() {
            _categories = categories;
            _loading = false;
          });
        }
      },
      onError: (error) {
        print('Error listening to categories: $error');
        if (mounted) {
          setState(() => _loading = false);
        }
      },
    );
  }

  Future<void> _fetchCategories() async {
    // Keep for refresh indicator compatibility
    setState(() => _loading = true);
    try {
      final cats = await RealtimeDatabaseService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PillPageHeader(
                title: 'Catégories',
                subtitle: 'Explorez toutes nos sélections',
                onBack: widget.onBackToHome,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: Lottie.asset(
                                'lib/assets/animations/category_loader.json',
                                repeat: true,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Shimmer.fromColors(
                              baseColor: Colors.white.withOpacity(0.4),
                              highlightColor: Colors.white,
                              child: Column(
                                children: List.generate(
                                  3,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 48,
                                      vertical: 6,
                                    ),
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _categories.isEmpty
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
                              'Aucune catégorie trouvée.',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchCategories,
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 18),
                          itemCount: _categories.length,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 150,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1,
                              ),
                          itemBuilder: (context, i) {
                            final c = _categories[i];
                            final color = _parseColor(c.color);
                            final icon = _iconForName(c.iconName);

                            final card = GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CategoryProductsScreen(category: c),
                                  ),
                                );
                              },
                              child: Container(
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
                                          iconUrl: c.iconUrl,
                                          fallbackIcon: icon,
                                          size: 56,
                                          fallbackColor: color,
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
                                        c.name,
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
                              ),
                            );

                            return card
                                .animate()
                                .fade(duration: 260.ms, delay: (i * 50).ms)
                                .scale(
                                  begin: const Offset(0.9, 0.9),
                                  end: const Offset(1, 1),
                                );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  IconData _iconForName(String iconName) {
    switch (iconName.toLowerCase()) {
      // Fruits & Vegetables
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

      // Meat & Seafood
      case 'meat':
      case 'viandes':
      case 'viande':
        return Icons.set_meal_rounded;
      case 'seafood':
      case 'fruits de mer':
      case 'poisson':
        return Icons.water_drop_rounded;

      // Bakery & Dairy
      case 'bakery':
      case 'boulangerie':
      case 'bread':
      case 'pain':
        return Icons.bakery_dining_rounded;
      case 'dairy':
      case 'laiterie':
      case 'lait':
        return Icons.local_dining_rounded;

      // Beverages
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

      // Frozen & Cold
      case 'frozen':
      case 'surgelé':
        return Icons.ac_unit_rounded;
      case 'ice cream':
      case 'glace':
        return Icons.icecream_rounded;

      // Supermarket & General
      case 'supermarket':
      case 'market':
      case 'grocery':
      case 'épicerie':
        return Icons.shopping_bag_rounded;
      case 'shopping_cart':
      case 'cart':
        return Icons.shopping_cart_rounded;

      // Home & Household
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

      // Electronics
      case 'electronics':
      case 'électronique':
        return Icons.devices_rounded;
      case 'phones':
      case 'téléphones':
        return Icons.phone_android_rounded;

      // Clothing
      case 'clothing':
      case 'vêtements':
      case 'vetements':
        return Icons.checkroom_rounded;
      case 'shoes':
      case 'chaussures':
        return Icons.directions_walk_rounded;

      // Baby & Kids
      case 'baby':
      case 'bébé':
      case 'bebe':
        return Icons.child_care_rounded;
      case 'toys':
      case 'jouets':
        return Icons.toys_rounded;

      // Health & Pharmacy
      case 'health':
      case 'santé':
      case 'sante':
        return Icons.medical_services_rounded;
      case 'pharmacy':
      case 'pharmacie':
        return Icons.local_pharmacy_rounded;

      // Snacks & Sweets
      case 'snacks':
      case 'gouter':
        return Icons.fastfood_rounded;
      case 'chocolate':
      case 'chocolat':
        return Icons.cookie_rounded;
      case 'candy':
      case 'bonbons':
        return Icons.cake_rounded;

      // Sports & Outdoor
      case 'sports':
      case 'sport':
        return Icons.sports_soccer_rounded;
      case 'outdoor':
        return Icons.directions_bike_rounded;

      // Books & Stationery
      case 'books':
      case 'livres':
        return Icons.menu_book_rounded;
      case 'stationery':
      case 'papeterie':
        return Icons.edit_rounded;

      // Pet Supplies
      case 'pets':
      case 'animaux':
        return Icons.pets_rounded;

      // Automotive
      case 'automotive':
      case 'automobile':
        return Icons.directions_car_rounded;

      default:
        return Icons.category_rounded;
    }
  }
}
