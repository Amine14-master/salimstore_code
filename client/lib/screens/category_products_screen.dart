import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/realtime_database_service.dart';
import '../models/product_models.dart';
import 'product_detail_screen.dart';
import '../widgets/add_to_cart_dialog.dart';
import '../utils/formatting.dart';

class CategoryProductsScreen extends StatefulWidget {
  final Category category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  bool _loading = true;
  List<Product> _products = [];
  StreamSubscription<List<Product>>? _productsSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListener() {
    setState(() => _loading = true);
    _productsSubscription =
        RealtimeDatabaseService.productsByCategoryStream(
          widget.category.id,
        ).listen(
          (products) {
            if (mounted) {
              // Sort by latest first
              products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              setState(() {
                _products = products;
                _loading = false;
              });
            }
          },
          onError: (error) {
            print('Error listening to products: $error');
            if (mounted) {
              setState(() => _loading = false);
            }
          },
        );
  }

  Future<void> _loadProducts() async {
    // Keep for refresh indicator compatibility
    setState(() => _loading = true);
    try {
      final categoryProducts =
          await RealtimeDatabaseService.getProductsByCategory(
            widget.category.id,
          );

      categoryProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _products = categoryProducts;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading products: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(widget.category.color);

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
                    colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
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
              // Products Grid
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun produit disponible',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                              child:
                                  Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.08),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                      18,
                                                    ),
                                                    topRight: Radius.circular(
                                                      18,
                                                    ),
                                                  ),
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    height: 120,
                                                    width: double.infinity,
                                                    color: AppTheme.accentColor
                                                        .withOpacity(0.1),
                                                    child:
                                                        product
                                                            .imageUrl
                                                            .isNotEmpty
                                                        ? Image.network(
                                                            product.imageUrl,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  _,
                                                                  __,
                                                                  ___,
                                                                ) => const Center(
                                                                  child: Icon(
                                                                    Icons.image,
                                                                    size: 40,
                                                                  ),
                                                                ),
                                                          )
                                                        : const Center(
                                                            child: Icon(
                                                              Icons.image,
                                                              size: 40,
                                                            ),
                                                          ),
                                                  ),
                                                  if (!product.isAvailable)
                                                    Container(
                                                      height: 120,
                                                      color: Colors.black54,
                                                      child: const Center(
                                                        child: Text(
                                                          'Indisponible',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    product.description,
                                                    style: TextStyle(
                                                      color: AppTheme
                                                          .textSecondary,
                                                      fontSize: 11,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        FormattingUtils.formatPriceWithLocale(
                                                          product.price,
                                                          Localizations.localeOf(
                                                            context,
                                                          ),
                                                        ),
                                                        style: TextStyle(
                                                          color: AppTheme
                                                              .successColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.star,
                                                            color: Colors
                                                                .amber
                                                                .shade400,
                                                            size: 14,
                                                          ),
                                                          const SizedBox(
                                                            width: 2,
                                                          ),
                                                          Text(
                                                            product.rating
                                                                .toStringAsFixed(
                                                                  1,
                                                                ),
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: () async {
                                                        final result =
                                                            await showDialog(
                                                              context: context,
                                                              builder: (context) =>
                                                                  AddToCartDialog(
                                                                    product:
                                                                        product,
                                                                  ),
                                                            );
                                                        if (result != null &&
                                                            mounted) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                '${result['quantity']}x ${product.name} ajouté${result['quantity'] > 1 ? 's' : ''} au panier',
                                                              ),
                                                              backgroundColor:
                                                                  AppTheme
                                                                      .successColor,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        'Ajouter',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .animate()
                                      .fade(
                                        duration: 300.ms,
                                        delay: (index * 80).ms,
                                      )
                                      .scale(
                                        begin: const Offset(0.9, 0.9),
                                        end: const Offset(1, 1),
                                      ),
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
