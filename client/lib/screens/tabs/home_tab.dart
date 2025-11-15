import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/realtime_database_service.dart';
import '../../services/address_service.dart';
import '../../models/product_models.dart';
import '../product_detail_screen.dart';
import '../addresses_management_screen.dart';
import '../../widgets/add_to_cart_dialog.dart';
import '../../widgets/category_icon_view.dart';
import '../../utils/formatting.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback? onNavigateToCategories;
  final VoidCallback? onNavigateToCart;

  const HomeTab({
    super.key,
    this.onNavigateToCategories,
    this.onNavigateToCart,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _loading = true;
  List<Product> _promotionalProducts = [];
  List<Product> _latestProducts = [];
  List<Category> _categories = [];
  int _currentSliderIndex = 0;
  String _deliveryAddressLabel = 'Adresse';
  String _deliveryAddressFull = 'Alger, Alger Centre';
  StreamSubscription<List<Category>>? _categoriesSubscription;
  List<Map<String, dynamic>> _promotionEntries = [];
  List<Product> _allProducts = [];
  StreamSubscription<List<Map<String, dynamic>>>? _promotionsSubscription;
  StreamSubscription<List<Product>>? _productsSubscription;
  StreamSubscription<Map<String, dynamic>?>? _defaultAddressSubscription;

  @override
  void initState() {
    super.initState();
    _loadAddress();
    _listenToDefaultAddress();
    _initDataStreams();
    _fetchData();
    _listenToCategories();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _promotionsSubscription?.cancel();
    _productsSubscription?.cancel();
    _defaultAddressSubscription?.cancel();
    super.dispose();
  }

  Widget _buildLoadingState() {
    return Stack(
      children: [
        Positioned.fill(
          child: Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_jmBauI.json',
            fit: BoxFit.cover,
            repeat: true,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildShimmerBox(height: 120),
                const SizedBox(height: 16),
                _buildShimmerBox(height: 180, borderRadius: 24),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    6,
                    (_) => _buildShimmerBox(
                      width: (MediaQuery.of(context).size.width - 64) / 3,
                      height: 110,
                      borderRadius: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: 4,
                  itemBuilder: (_, __) => _buildShimmerBox(borderRadius: 24),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerBox({
    double? width,
    double? height,
    double borderRadius = 16,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.5),
      highlightColor: Colors.white.withOpacity(0.9),
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  String _formatEuro(double price) {
    final locale = Localizations.localeOf(context);
    return FormattingUtils.formatPriceWithLocale(price, locale);
  }

  Future<void> _loadAddress() async {
    try {
      final defaultAddress = await AddressService.getDefaultAddress();
      if (defaultAddress != null && mounted) {
        final fullAddress = defaultAddress['fullAddress'] as String?;
        final label = defaultAddress['label'] as String?;
        if (fullAddress != null && fullAddress.isNotEmpty) {
          await _persistAddress(fullAddress, label);
          _applyAddressState(fullAddress, label);
          return;
        }
      }
    } catch (e) {
      print('Error loading default address: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('delivery_address');
    final savedLabel = prefs.getString('delivery_address_label');
    if (savedAddress != null && savedAddress.isNotEmpty && mounted) {
      _applyAddressState(savedAddress, savedLabel);
    }
  }

  Future<void> _openAddressManager() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressesManagementScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadAddress();
    } else {
      // Even without an explicit result, addresses might have changed.
      await _loadAddress();
    }
  }

  void _listenToDefaultAddress() {
    _defaultAddressSubscription?.cancel();
    _defaultAddressSubscription = AddressService.defaultAddressStream().listen((
      address,
    ) async {
      if (!mounted) return;
      if (address == null) {
        await _loadAddress();
        return;
      }

      final fullAddress = address['fullAddress'] as String?;
      final label = address['label'] as String?;
      if (fullAddress != null && fullAddress.isNotEmpty) {
        await _persistAddress(fullAddress, label);
        _applyAddressState(fullAddress, label);
      }
    });
  }

  Future<void> _persistAddress(String full, String? label) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('delivery_address', full);
    await prefs.setString('delivery_address_label', _computeLabel(label, full));
  }

  void _applyAddressState(String full, String? label) {
    final displayLabel = _computeLabel(label, full);
    setState(() {
      _deliveryAddressFull = full;
      _deliveryAddressLabel = displayLabel;
    });
  }

  String _computeLabel(String? label, String? full) {
    if (label != null && label.trim().isNotEmpty) {
      return label.trim();
    }
    if (full != null && full.trim().isNotEmpty) {
      final parts = full.split(',');
      if (parts.isNotEmpty && parts.first.trim().isNotEmpty) {
        return parts.first.trim();
      }
      return full.trim();
    }
    return 'Adresse';
  }

  void _initDataStreams() {
    _promotionsSubscription?.cancel();
    _productsSubscription?.cancel();

    _promotionsSubscription = RealtimeDatabaseService.promotionsStream().listen(
      (promos) {
        _promotionEntries = promos
            .map((promo) => Map<String, dynamic>.from(promo))
            .toList();
        _recalculatePromotions();
      },
      onError: (error) =>
          print('Error streaming promotions: ${error.toString()}'),
    );

    _productsSubscription = RealtimeDatabaseService.productsStream().listen(
      (products) {
        _allProducts = List<Product>.from(products);
        _recalculatePromotions();
      },
      onError: (error) =>
          print('Error streaming products: ${error.toString()}'),
    );
  }

  void _recalculatePromotions() {
    if (!mounted) return;

    final sortedProducts = List<Product>.from(_allProducts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final promoProducts = _buildPromotionalProducts(
      _promotionEntries,
      sortedProducts,
    );

    setState(() {
      _allProducts = sortedProducts;
      _promotionalProducts = promoProducts;
      _latestProducts = sortedProducts.take(8).toList();
      _loading = false;
    });
  }

  Future<void> _fetchData() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final promotions = await RealtimeDatabaseService.getPromotions();
      final allProducts = await RealtimeDatabaseService.getAllProducts();

      if (!mounted) return;

      _promotionEntries = promotions
          .map((promo) => Map<String, dynamic>.from(promo))
          .toList();
      _allProducts = List<Product>.from(allProducts);

      _recalculatePromotions();
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Product> _buildPromotionalProducts(
    List<Map<String, dynamic>> promotions,
    List<Product> allProducts,
  ) {
    if (promotions.isEmpty || allProducts.isEmpty) {
      return promotions
          .map((promo) => _productFromPromotionOnly(promo))
          .whereType<Product>()
          .toList();
    }

    promotions.sort(
      (a, b) => _parsePromoDate(
        b['createdAt'],
      ).compareTo(_parsePromoDate(a['createdAt'])),
    );

    final Map<String, Product> productById = {
      for (final product in allProducts) product.id: product,
    };

    final seen = <String>{};
    final result = <Product>[];

    for (final promo in promotions) {
      final productId = (promo['productId'] ?? '').toString();
      final promoId = (promo['id'] ?? '').toString();
      final identity = productId.isNotEmpty ? productId : 'promo_$promoId';
      if (identity.isEmpty || seen.contains(identity)) continue;

      final baseProduct = productId.isNotEmpty ? productById[productId] : null;
      final double? overridePrice = _parsePromoPrice(promo['price']);
      final double? overrideOriginalPrice = _parsePromoPrice(
        promo['originalPrice'],
      );
      final double? overrideDiscount = _parsePromoPrice(
        promo['discountPercentage'],
      );
      final overrideImage = promo['imageUrl']?.toString();
      final overrideName = promo['name']?.toString();
      final overrideDescription = promo['description']?.toString();
      final availableUnits = _stringListFrom(promo['availableUnits']);
      final createdAt = _parsePromoDate(promo['createdAt']);
      final updatedAt = _parsePromoDate(
        promo['updatedAt'] ?? promo['createdAt'],
      );
      final isActive = promo['isActive'] != false;

      Product? product;

      if (baseProduct != null) {
        final double newPrice = overridePrice ?? baseProduct.price;
        double? originalPrice =
            overrideOriginalPrice ??
            (overridePrice != null && baseProduct.price > newPrice
                ? baseProduct.price
                : baseProduct.originalPrice);
        if (originalPrice != null && originalPrice <= newPrice) {
          originalPrice = null;
        }
        final double? discountPercentage =
            overrideDiscount ?? _computeDiscount(originalPrice, newPrice);

        product = Product(
          id: baseProduct.id,
          name: (overrideName?.isNotEmpty ?? false)
              ? overrideName!
              : baseProduct.name,
          description: (overrideDescription?.isNotEmpty ?? false)
              ? overrideDescription!
              : baseProduct.description,
          price: newPrice,
          imageUrl: (overrideImage != null && overrideImage.isNotEmpty)
              ? overrideImage
              : baseProduct.imageUrl,
          rating: baseProduct.rating,
          reviewCount: baseProduct.reviewCount,
          categoryId: baseProduct.categoryId,
          subCategoryId: baseProduct.subCategoryId,
          availableUnits: availableUnits.isNotEmpty
              ? availableUnits
              : baseProduct.availableUnits,
          isAvailable: isActive && baseProduct.isAvailable,
          createdAt: baseProduct.createdAt,
          updatedAt: updatedAt.isAfter(baseProduct.updatedAt)
              ? updatedAt
              : baseProduct.updatedAt,
          originalPrice: originalPrice,
          discountPercentage: discountPercentage,
        );
      } else {
        product = _productFromPromotionOnly(
          promo,
          identityOverride: identity,
          priceOverride: overridePrice,
          imageOverride: overrideImage,
          nameOverride: overrideName,
          descriptionOverride: overrideDescription,
          availableUnitsOverride: availableUnits,
          createdAtOverride: createdAt,
          updatedAtOverride: updatedAt,
          isActiveOverride: isActive,
        );
      }

      if (product != null) {
        result.add(product);
        seen.add(identity);
      }
    }

    if (result.isEmpty) {
      return promotions
          .map((promo) => _productFromPromotionOnly(promo))
          .whereType<Product>()
          .toList();
    }

    return result;
  }

  double? _parsePromoPrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final sanitized = value.replaceAll(',', '.');
      return double.tryParse(sanitized);
    }
    return null;
  }

  double? _computeDiscount(double? original, double? current) {
    if (original == null || current == null) return null;
    if (original <= 0 || current >= original) return null;
    final discount = ((original - current) / original) * 100;
    if (discount <= 0) return null;
    return discount;
  }

  DateTime _parsePromoDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Product? _productFromPromotionOnly(
    Map<String, dynamic> promo, {
    String? identityOverride,
    double? priceOverride,
    String? imageOverride,
    String? nameOverride,
    String? descriptionOverride,
    List<String>? availableUnitsOverride,
    DateTime? createdAtOverride,
    DateTime? updatedAtOverride,
    bool? isActiveOverride,
  }) {
    final double? price = priceOverride ?? _parsePromoPrice(promo['price']);
    final name = (nameOverride ?? promo['name']?.toString() ?? '').trim();
    final imageUrl = (imageOverride ?? promo['imageUrl']?.toString() ?? '')
        .trim();
    final availableUnits = (availableUnitsOverride?.isNotEmpty ?? false)
        ? availableUnitsOverride!
        : _stringListFrom(promo['availableUnits']);
    final double? originalPriceRaw = _parsePromoPrice(promo['originalPrice']);
    final double? discountRaw = _parsePromoPrice(promo['discountPercentage']);

    double? resolvedOriginalPrice = originalPriceRaw;
    if (resolvedOriginalPrice == null &&
        discountRaw != null &&
        discountRaw > 0 &&
        discountRaw < 100 &&
        price != null &&
        price > 0) {
      resolvedOriginalPrice = price / (1 - discountRaw / 100);
    }
    if (resolvedOriginalPrice != null &&
        price != null &&
        resolvedOriginalPrice <= price) {
      resolvedOriginalPrice = null;
    }

    final double? discountPercentage =
        discountRaw ?? _computeDiscount(resolvedOriginalPrice, price);

    if (price == null && (name.isEmpty || imageUrl.isEmpty)) {
      return null;
    }

    final id =
        identityOverride ??
        (promo['id']?.toString().isNotEmpty == true
            ? promo['id'].toString()
            : 'promo_${DateTime.now().millisecondsSinceEpoch}');

    final safeUnits = availableUnits.isNotEmpty ? availableUnits : ['unité'];
    final createdAt = createdAtOverride ?? _parsePromoDate(promo['createdAt']);
    final updatedAt = updatedAtOverride ?? _parsePromoDate(promo['updatedAt']);
    final isActive = isActiveOverride ?? promo['isActive'] != false;

    return Product(
      id: id,
      name: name.isNotEmpty ? name : 'Promotion spéciale',
      description:
          (descriptionOverride ?? promo['description']?.toString() ?? '')
              .trim(),
      price: price ?? 0,
      imageUrl: imageUrl,
      rating: 0,
      reviewCount: 0,
      categoryId: (promo['categoryId'] ?? 'promotion').toString(),
      subCategoryId: (promo['subCategoryId'] ?? 'promotion').toString(),
      availableUnits: safeUnits,
      isAvailable: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt.isAfter(createdAt) ? updatedAt : createdAt,
      originalPrice: resolvedOriginalPrice,
      discountPercentage: discountPercentage,
    );
  }

  List<String> _stringListFrom(dynamic source) {
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

  void _listenToCategories() {
    _categoriesSubscription?.cancel();
    _categoriesSubscription = RealtimeDatabaseService.categoriesStream().listen(
      (cats) {
        if (!mounted) return;
        setState(() {
          _categories = cats;
        });
      },
      onError: (error) {
        print('Error listening to categories: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayCategories = _categories.take(8).toList();
    final hasMoreCategories = _categories.length > displayCategories.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth - 32; // outer horizontal padding (16 * 2)
    const double cartIconTotalWidth = 56;
    const double addressCartSpacing = 12;
    final double addressCardMaxWidth =
        (contentWidth - addressCartSpacing - cartIconTotalWidth).clamp(
          0.0,
          contentWidth,
        );
    final deliveryLabel = _deliveryAddressLabel.trim();
    final hasDeliveryLabel = deliveryLabel.isNotEmpty;
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: _loading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header: Delivery Address (left) + Cart Icon (right)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Delivery Address
                            Expanded(
                              child: GestureDetector(
                                onTap: _openAddressManager,
                                child: Tooltip(
                                  message: _deliveryAddressFull,
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    constraints: BoxConstraints(
                                      maxWidth: addressCardMaxWidth,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.15),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.location_on,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text.rich(
                                                      TextSpan(
                                                        text:
                                                            'Adresse de livraison',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.white
                                                              .withOpacity(
                                                                0.85,
                                                              ),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        children:
                                                            hasDeliveryLabel
                                                            ? [
                                                                TextSpan(
                                                                  text: '  •  ',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                          0.55,
                                                                        ),
                                                                    fontSize:
                                                                        10,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text:
                                                                      deliveryLabel,
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        12.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                              ]
                                                            : const [],
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.edit,
                                                    size: 14,
                                                    color: Colors.white
                                                        .withOpacity(0.85),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: addressCartSpacing),
                            // Cart Icon
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.12,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.shopping_cart_outlined),
                                color: AppTheme.primaryColor,
                                onPressed: widget.onNavigateToCart,
                              ),
                            ),
                          ],
                        ).animate().fade(duration: 300.ms).slideY(begin: -0.1),
                        const SizedBox(height: 16),

                        // Search Field
                        Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.08,
                                    ),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const TextField(
                                decoration: InputDecoration(
                                  hintText: 'Rechercher des produits...',
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: AppTheme.textSecondary,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fade(duration: 300.ms, delay: 150.ms)
                            .slideY(begin: 0.15),
                        const SizedBox(height: 20),

                        // Image Slider for Promotions
                        if (_promotionalProducts.isNotEmpty) ...[
                          CarouselSlider.builder(
                            itemCount: _promotionalProducts.length,
                            itemBuilder: (context, index, realIndex) {
                              final product = _promotionalProducts[index];
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
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.15),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        product.imageUrl.isNotEmpty
                                            ? Image.network(
                                                product.imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      color: AppTheme
                                                          .accentColor
                                                          .withOpacity(0.1),
                                                      child: const Icon(
                                                        Icons.image,
                                                        size: 50,
                                                      ),
                                                    ),
                                              )
                                            : Container(
                                                color: AppTheme.accentColor
                                                    .withOpacity(0.1),
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 50,
                                                ),
                                              ),
                                        // Gradient overlay
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.6),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Product info overlay
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Builder(
                                                  builder: (context) {
                                                    final bool
                                                    hasOriginalPrice =
                                                        product.originalPrice !=
                                                            null &&
                                                        product.originalPrice! >
                                                            product.price;
                                                    final String
                                                    currentPriceText =
                                                        _formatEuro(
                                                          product.price,
                                                        );
                                                    final String?
                                                    originalPriceText =
                                                        hasOriginalPrice
                                                        ? _formatEuro(
                                                            product
                                                                .originalPrice!,
                                                          )
                                                        : null;
                                                    final double? discount =
                                                        (product.discountPercentage !=
                                                                null &&
                                                            product.discountPercentage! >
                                                                0)
                                                        ? product
                                                              .discountPercentage
                                                        : null;

                                                    return AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 250,
                                                      ),
                                                      curve: Curves.easeInOut,
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          if (originalPriceText !=
                                                              null) ...[
                                                            Text(
                                                              originalPriceText,
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                      0.75,
                                                                    ),
                                                                fontSize: 14,
                                                                decoration:
                                                                    TextDecoration
                                                                        .lineThrough,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                          ],
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      14,
                                                                  vertical: 6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              gradient: AppTheme
                                                                  .primaryGradient,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    999,
                                                                  ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: AppTheme
                                                                      .primaryColor
                                                                      .withOpacity(
                                                                        0.35,
                                                                      ),
                                                                  blurRadius:
                                                                      14,
                                                                  offset:
                                                                      const Offset(
                                                                        0,
                                                                        6,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Text(
                                                              currentPriceText,
                                                              style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                fontSize: 16,
                                                                letterSpacing:
                                                                    0.2,
                                                              ),
                                                            ),
                                                          ),
                                                          if (discount !=
                                                              null) ...[
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical: 4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: AppTheme
                                                                    .successColor
                                                                    .withOpacity(
                                                                      0.9,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: AppTheme
                                                                        .successColor
                                                                        .withOpacity(
                                                                          0.24,
                                                                        ),
                                                                    blurRadius:
                                                                        10,
                                                                    offset:
                                                                        const Offset(
                                                                          0,
                                                                          4,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Text(
                                                                '-${discount.toStringAsFixed(0)}%',
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 12,
                                                                  letterSpacing:
                                                                      0.4,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppTheme.successColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    'PROMOTION',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black54,
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            options: CarouselOptions(
                              height: 210,
                              viewportFraction: 0.78,
                              enlargeCenterPage:
                                  _promotionalProducts.length > 1,
                              enlargeStrategy: CenterPageEnlargeStrategy.height,
                              padEnds: _promotionalProducts.length > 1,
                              enableInfiniteScroll:
                                  _promotionalProducts.length > 1,
                              autoPlay: _promotionalProducts.length > 1,
                              autoPlayInterval: const Duration(seconds: 4),
                              autoPlayAnimationDuration: const Duration(
                                milliseconds: 800,
                              ),
                              autoPlayCurve: Curves.fastOutSlowIn,
                              onPageChanged: (index, reason) {
                                setState(() => _currentSliderIndex = index);
                              },
                            ),
                          ).animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2),
                          const SizedBox(height: 8),
                          // Slider indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _promotionalProducts.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentSliderIndex == index
                                      ? AppTheme.primaryColor
                                      : AppTheme.primaryColor.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Categories Section (3 rows with "Voir tout" button)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Catégories',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                            TextButton.icon(
                              onPressed: widget.onNavigateToCategories,
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('Voir tout'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Display categories in rows of 3
                        if (_categories.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'Aucune catégorie disponible',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: displayCategories.length + 1,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1,
                                ),
                            itemBuilder: (context, index) {
                              final isViewAll =
                                  index == displayCategories.length;
                              if (isViewAll) {
                                return _buildViewAllCategoryCard(
                                  remainingCount:
                                      _categories.length >
                                          displayCategories.length
                                      ? _categories.length -
                                            displayCategories.length
                                      : 0,
                                );
                              }
                              final category = displayCategories[index];
                              return _buildCategoryCard(category, index);
                            },
                          ),
                        const SizedBox(height: 8),

                        // Latest Products Section
                        const SizedBox(height: 24),
                        Text(
                          'Derniers produits ajoutés',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                        const SizedBox(height: 12),

                        if (_latestProducts.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'Aucun produit disponible',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _latestProducts.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.9,
                                ),
                            itemBuilder: (context, index) {
                              final product = _latestProducts[index];
                              return _buildProductCard(product, index);
                            },
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category, int index) {
    final color = _parseColor(category.color);
    return GestureDetector(
      onTap: widget.onNavigateToCategories,
      child:
          Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.28), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      CategoryIconView(
                        iconUrl: category.iconUrl,
                        fallbackIcon: _iconForName(category.iconName),
                        size: 110,
                        fallbackColor: color,
                        borderRadius: 0,
                        showLoader: false,
                        overlayColor: Colors.white.withOpacity(0.05),
                        expandToFill: true,
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.04),
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                letterSpacing: 0.2,
                                shadows: [
                                  Shadow(color: Colors.black45, blurRadius: 12),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Text(
                                  '#${(index + 1).toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fade(duration: 260.ms, delay: (index * 45).ms)
              .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1)),
    );
  }

  Widget _buildViewAllCategoryCard({required int remainingCount}) {
    return GestureDetector(
      onTap: widget.onNavigateToCategories,
      child:
          Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.grid_view_rounded,
                      color: AppTheme.primaryColor,
                      size: 26,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Voir tout',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              .animate()
              .fade(duration: 300.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }

  Widget _buildProductCard(Product product, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child:
          Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          AppTheme.backgroundColor.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.6,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  color: AppTheme.accentColor.withOpacity(0.08),
                                  child: product.imageUrl.isNotEmpty
                                      ? Image.network(
                                          product.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.image,
                                                  size: 32,
                                                ),
                                              ),
                                        )
                                      : const Center(
                                          child: Icon(Icons.image, size: 32),
                                        ),
                                ),
                              ),
                              if (!product.isAvailable)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black54,
                                    child: const Center(
                                      child: Text(
                                        'Indisponible',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatEuro(product.price),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: product.description.isNotEmpty
                                        ? Text(
                                            product.description,
                                            style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 11,
                                              height: 1.25,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Transform.translate(
                                  offset: const Offset(0, -18),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await showDialog(
                                          context: context,
                                          builder: (context) =>
                                              AddToCartDialog(product: product),
                                        );
                                        if (result != null && mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${result['quantity']}x ${product.name} ajouté${result['quantity'] > 1 ? 's' : ''} au panier',
                                              ),
                                              backgroundColor:
                                                  AppTheme.successColor,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.add_shopping_cart_rounded,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Ajouter',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        elevation: 0,
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fade(duration: 300.ms, delay: (index * 80).ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
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
      case 'apple':
        return Icons.apple;
      case 'carrot':
        return Icons.local_dining;
      case 'meat':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      default:
        return Icons.category;
    }
  }
}
