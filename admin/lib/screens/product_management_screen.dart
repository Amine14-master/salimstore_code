import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../models/product_models.dart';
import 'category_management_screen.dart';
import '../services/realtime_database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_search_bar.dart';
// Removed categories management screen

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen>
    with TickerProviderStateMixin {
  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];
  List<Product> _products = [];
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final categories = await RealtimeDatabaseService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
      _animationController.forward();
      // Load all products initially for better visibility
      await _loadAllProducts();
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSubCategories(Category category) async {
    try {
      final subCategories = await RealtimeDatabaseService.getSubCategories(
        category.id,
      );
      if (!mounted) return;
      setState(() {
        _selectedCategory = category;
        _subCategories = subCategories;
        _selectedSubCategory = null;
        _products = [];
      });
    } catch (e) {
      print('Error loading subcategories: $e');
    }
  }

  Future<void> _loadProducts(SubCategory subCategory) async {
    try {
      setState(() => _isLoading = true);
      final products = await RealtimeDatabaseService.getProducts(
        subCategory.id,
      );
      if (!mounted) return;
      setState(() {
        _selectedSubCategory = subCategory;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllProducts() async {
    try {
      setState(() => _isLoading = true);
      final products = await RealtimeDatabaseService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _selectedCategory = null;
        _selectedSubCategory = null;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading all products: $e');
    }
  }

  List<Product> get _filteredProducts {
    var filtered = _products.where((product) {
      return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();

    // Sort products
    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'rating':
          comparison = a.rating.compareTo(b.rating);
          break;
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Future<void> _addProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(
          initialCategory: _selectedCategory,
          initialSubCategory: _selectedSubCategory,
        ),
      ),
    );
    if (result == true) {
      if (_selectedSubCategory != null) {
        _loadProducts(_selectedSubCategory!);
      } else {
        _loadAllProducts();
      }
    }
  }

  Future<void> _editProduct(Product product) async {
    // Find category and subcategory for this product
    final category = _categories.firstWhere(
      (cat) => cat.id == product.categoryId,
      orElse: () => _categories.first,
    );

    final subCategory = _subCategories.firstWhere(
      (sub) => sub.id == product.subCategoryId,
      orElse: () => SubCategory(
        id: product.subCategoryId,
        name: 'Unknown',
        description: '',
        categoryId: product.categoryId,
        productIds: [],
        createdAt: DateTime.now(),
      ),
    );

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(
          initialCategory: category,
          initialSubCategory: subCategory,
          product: product,
        ),
      ),
    );
    if (result == true) {
      if (_selectedSubCategory != null) {
        _loadProducts(_selectedSubCategory!);
      } else {
        _loadAllProducts();
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            const SizedBox(width: 12),
            const Text('Supprimer le Produit'),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${product.name}"?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await RealtimeDatabaseService.deleteProduct(product.id);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} supprimé avec succès'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          if (_selectedSubCategory != null) {
            _loadProducts(_selectedSubCategory!);
          } else {
            _loadAllProducts();
          }
        } else {
          throw Exception('Échec de la suppression');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: isDesktop ? 112 : 96,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Gestion des Produits',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: isDesktop ? 22 : 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                ),
                child: const SizedBox.shrink(),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _addProduct,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                tooltip: 'Ajouter un Produit',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort_rounded, color: Colors.white),
                onSelected: (value) {
                  setState(() {
                    _sortBy = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'name',
                    child: Text('Trier par Nom'),
                  ),
                  const PopupMenuItem(
                    value: 'price',
                    child: Text('Trier par Prix'),
                  ),
                  const PopupMenuItem(
                    value: 'rating',
                    child: Text('Trier par Note'),
                  ),
                  const PopupMenuItem(
                    value: 'createdAt',
                    child: Text('Trier par Date'),
                  ),
                ],
              ),
            ],
          ),

          // Compact hierarchy selectors + search
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 28 : 14,
                6,
                isDesktop ? 28 : 14,
                6,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Category dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Category?>(
                              isExpanded: true,
                              value: _selectedCategory,
                              hint: const Text('Catégorie'),
                              items: [
                                const DropdownMenuItem<Category?>(
                                  value: null,
                                  child: Text('Tous les Produits'),
                                ),
                                ..._categories
                                    .map(
                                      (c) => DropdownMenuItem<Category?>(
                                        value: c,
                                        child: Text(
                                          c.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ],
                              onChanged: (c) async {
                                if (c == null) {
                                  await _loadAllProducts();
                                  return;
                                }
                                await _loadSubCategories(c);
                                final products =
                                    await RealtimeDatabaseService.getProductsByCategory(
                                      c.id,
                                    );
                                if (!mounted) return;
                                setState(() {
                                  _products = products;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Subcategory dropdown
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<SubCategory>(
                              isExpanded: true,
                              value: _selectedSubCategory,
                              hint: const Text('Sous-catégorie'),
                              items: _subCategories
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(
                                        s.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (s) async {
                                if (s == null) return;
                                await _loadProducts(s);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AdminSearchBar(
                    hintText: 'Rechercher des produits...',
                    onChanged: (value) => setState(() => _searchQuery = value),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                ],
              ),
            ),
          ),

          // Breadcrumb Navigation
          if (_selectedCategory != null || _selectedSubCategory != null)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = null;
                          _selectedSubCategory = null;
                          _subCategories = [];
                          _products = [];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tous les Produits',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (_selectedCategory != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSubCategory = null;
                            _products = [];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _selectedCategory!.name,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (_selectedSubCategory != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _selectedSubCategory!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Chargement des données...',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _selectedCategory == null
                ? _buildAllProductsView()
                : _selectedSubCategory == null
                ? _buildSubCategoriesView()
                : _buildProductsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoriesView() {
    return SliverFillRemaining(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedCategory != null
                        ? 'Sous-catégories de ${_selectedCategory!.name}'
                        : 'Sous-catégories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _subCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucune sous-catégorie',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isDesktop = screenWidth >= 600;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 4 : 2,
                          crossAxisSpacing: isDesktop ? 24 : 20,
                          mainAxisSpacing: isDesktop ? 24 : 20,
                          childAspectRatio: isDesktop ? 1.0 : 1.1,
                        ),
                        itemCount: _subCategories.length,
                        itemBuilder: (context, index) {
                          final sub = _subCategories[index];
                          return GestureDetector(
                            onTap: () => _loadProducts(sub),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.category_rounded,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    sub.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    sub.description,
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllProductsView() {
    return SliverFillRemaining(
      child: Column(
        children: [
          // No quick-action header here to maximize space for the grid

          // Products Grid
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Aucun produit disponible'
                                : 'Aucun produit trouvé',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Commencez par ajouter votre premier produit'
                                : 'Essayez avec d\'autres mots-clés',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: _addProduct,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Ajouter le Premier Produit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isDesktop = screenWidth >= 600;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isDesktop ? 280 : 200,
                          crossAxisSpacing: isDesktop ? 20 : 10,
                          mainAxisSpacing: isDesktop ? 20 : 10,
                          childAspectRatio: isDesktop ? 0.75 : 0.72,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildProductCard(product),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsView() {
    return SliverFillRemaining(
      child: Column(
        children: [
          // Breadcrumb and Add
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedCategory!.name} → ${_selectedSubCategory!.name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Produit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      'Aucun produit dans cette sous-catégorie',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isDesktop = screenWidth >= 600;
                      return GridView.builder(
                        padding: EdgeInsets.all(isDesktop ? 12 : 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 4 : 2,
                          crossAxisSpacing: isDesktop ? 16 : 12,
                          mainAxisSpacing: isDesktop ? 16 : 12,
                          childAspectRatio: isDesktop ? 0.72 : 0.68,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildProductCard(product),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: Colors.grey[200],
              ),
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              size: 40,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_rounded,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppTheme.formatCurrency(product.price),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: product.isAvailable
                              ? AppTheme.successColor.withOpacity(0.1)
                              : AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.isAvailable ? 'Disponible' : 'Indisponible',
                          style: TextStyle(
                            fontSize: 9,
                            color: product.isAvailable
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _editProduct(product),
                            icon: Icon(
                              Icons.edit_rounded,
                              color: AppTheme.primaryColor,
                            ),
                            iconSize: 16,
                          ),
                          IconButton(
                            onPressed: () => _deleteProduct(product),
                            icon: Icon(
                              Icons.delete_rounded,
                              color: AppTheme.errorColor,
                            ),
                            iconSize: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(onTap: () => _editProduct(product), child: card);
  }
}

class AddEditProductScreen extends StatefulWidget {
  final Category? initialCategory;
  final SubCategory? initialSubCategory;
  final Product? product;

  const AddEditProductScreen({
    super.key,
    this.initialCategory,
    this.initialSubCategory,
    this.product,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  XFile? _pickedImage;
  List<String> _selectedUnits = [];
  bool _isLoading = false;
  List<Category> _allCategories = [];
  Map<String, List<SubCategory>> _subCategoriesByCategory = {};
  bool _isCategoryLoading = true;
  bool _categoryLoadFailed = false;
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;

  final List<String> _predefinedUnits = [
    'kg',
    'g',
    'L',
    'ml',
    'piece',
    'pack',
    'box',
    'bottle',
    'can',
    'bag',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toStringAsFixed(2);
      _imageUrlController.text = widget.product!.imageUrl;
      _selectedUnits = List.from(widget.product!.availableUnits);
    } else if (widget.initialCategory != null) {
      // Set default units based on provided category
      _selectedUnits = _getDefaultUnits(widget.initialCategory!.name);
    } else {
      _selectedUnits = _getDefaultUnits(null);
    }
    _selectedCategory = widget.initialCategory;
    _selectedSubCategory = widget.initialSubCategory;
    _loadCategoryHierarchy();
  }

  List<String> _getDefaultUnits(String? categoryName) {
    final name = categoryName?.toLowerCase();
    switch (name) {
      case 'fruits':
      case 'légumes':
        return ['kg', 'g', 'piece'];
      case 'viandes':
        return ['kg', 'g'];
      case 'supermarket':
        return ['piece', 'pack', 'box', 'bottle', 'can', 'bag'];
      default:
        return ['piece', 'kg', 'g'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryHierarchy() async {
    setState(() {
      _isCategoryLoading = true;
      _categoryLoadFailed = false;
    });

    try {
      final categories = await RealtimeDatabaseService.getCategories();
      final subMap = await RealtimeDatabaseService.getAllSubCategories();

      if (!mounted) return;

      Category? resolvedCategory;
      final desiredCategoryId =
          widget.product?.categoryId ?? widget.initialCategory?.id;
      for (final cat in categories) {
        if (cat.id == desiredCategoryId) {
          resolvedCategory = cat;
          break;
        }
      }
      resolvedCategory ??= categories.isNotEmpty ? categories.first : null;

      SubCategory? resolvedSubCategory;
      final subs = resolvedCategory != null
          ? subMap[resolvedCategory.id] ?? const []
          : const <SubCategory>[];
      final desiredSubId =
          widget.product?.subCategoryId ?? widget.initialSubCategory?.id;
      for (final sub in subs) {
        if (sub.id == desiredSubId) {
          resolvedSubCategory = sub;
          break;
        }
      }
      resolvedSubCategory ??= subs.isNotEmpty ? subs.first : null;

      setState(() {
        _allCategories = categories;
        _subCategoriesByCategory = subMap;
        _selectedCategory = resolvedCategory;
        _selectedSubCategory = resolvedSubCategory;
        if (widget.product == null && resolvedCategory != null) {
          _selectedUnits = _getDefaultUnits(resolvedCategory.name);
        }
        _isCategoryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoryLoadFailed = true;
        _isCategoryLoading = false;
      });
    }
  }

  void _onCategorySelected(Category category) {
    if (_selectedCategory?.id == category.id) return;
    final subs = _subCategoriesByCategory[category.id] ?? const [];
    setState(() {
      _selectedCategory = category;
      _selectedSubCategory = subs.isNotEmpty ? subs.first : null;
      if (widget.product == null && _selectedCategory != null) {
        _selectedUnits = _getDefaultUnits(_selectedCategory!.name);
      }
    });
  }

  void _onSubCategorySelected(SubCategory subCategory) {
    if (_selectedSubCategory?.id == subCategory.id) return;
    setState(() {
      _selectedSubCategory = subCategory;
    });
  }

  List<SubCategory> get _currentSubCategories {
    final categoryId = _selectedCategory?.id;
    if (categoryId == null) return const [];
    return _subCategoriesByCategory[categoryId] ?? const [];
  }

  void _showSnack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (_selectedCategory == null) {
      _showSnack('Veuillez sélectionner une catégorie');
      return;
    }
    if (_selectedSubCategory == null) {
      _showSnack('Veuillez sélectionner une sous-catégorie');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnits.isEmpty) {
      _showSnack('Veuillez sélectionner au moins une unité');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final price = _parsePriceInput(_priceController.text);
      if (price == null || price <= 0) {
        throw Exception('Veuillez saisir un prix valide');
      }

      // Upload picked image if any
      String imageUrl = _imageUrlController.text.trim();
      if (_pickedImage != null) {
        final storage = FirebaseStorage.instance;
        final fileName =
            'products/${_selectedSubCategory!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = storage.ref(fileName);
        final bytes = await _pickedImage!.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        imageUrl = await ref.getDownloadURL();
      }

      if (widget.product != null) {
        // Update product
        final oldCategoryId = widget.product!.categoryId;
        final oldSubCategoryId = widget.product!.subCategoryId;
        final success =
            await RealtimeDatabaseService.updateProduct(widget.product!.id, {
              'name': _nameController.text.trim(),
              'description': _descriptionController.text.trim(),
              'price': price,
              'imageUrl': imageUrl,
              'availableUnits': _selectedUnits,
              'categoryId': _selectedCategory!.id,
              'subCategoryId': _selectedSubCategory!.id,
            });

        if (success) {
          final categoryChanged = oldCategoryId != _selectedCategory!.id;
          final subCategoryChanged =
              oldSubCategoryId != _selectedSubCategory!.id;
          if (categoryChanged || subCategoryChanged) {
            await RealtimeDatabaseService.moveProductToSubCategory(
              productId: widget.product!.id,
              newSubCategoryId: _selectedSubCategory!.id,
              oldSubCategoryId: oldSubCategoryId,
            );
          }
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showSnack(
            'Produit mis à jour avec succès',
            color: AppTheme.successColor,
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Échec de la mise à jour');
        }
      } else {
        // Add new product
        final productId = await RealtimeDatabaseService.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          imageUrl: imageUrl,
          categoryId: _selectedCategory!.id,
          subCategoryId: _selectedSubCategory!.id,
          availableUnits: _selectedUnits,
        );

        if (productId != null) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showSnack(
            'Produit ajouté avec succès',
            color: AppTheme.successColor,
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Échec de l\'ajout');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showSnack('Erreur: $e');
    }
  }

  void _toggleUnit(String unit) {
    setState(() {
      if (_selectedUnits.contains(unit)) {
        _selectedUnits.remove(unit);
      } else {
        _selectedUnits.add(unit);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.product != null ? 'Modifier le Produit' : 'Ajouter un Produit',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProduct,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Sauvegarder',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHierarchyCard(context),
              const SizedBox(height: 20),

              // Form Card
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du Produit',
                        prefixIcon: const Icon(Icons.inventory_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir le nom du produit';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: const Icon(Icons.description_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir une description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Price
                    TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Prix (€)',
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir le prix';
                        }
                        final price = _parsePriceInput(value);
                        if (price == null || price <= 0) {
                          return 'Veuillez saisir un prix valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Image picker + optional URL
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlController,
                            decoration: InputDecoration(
                              labelText: 'URL de l\'Image (optionnel)',
                              prefixIcon: const Icon(Icons.link_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((_pickedImage == null) &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Choisissez une image ou entrez une URL';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (picked != null) {
                              setState(() {
                                _pickedImage = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.photo_library_rounded),
                          label: Text(
                            _pickedImage == null ? 'Choisir' : 'Choisie',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Available Units
                    Text(
                      'Unités Disponibles',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _predefinedUnits.map((unit) {
                        final isSelected = _selectedUnits.contains(unit);
                        return GestureDetector(
                          onTap: () => _toggleUnit(unit),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textLight,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              unit,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),

                    // Preview
                    Text(
                      'Aperçu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image Preview
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: _pickedImage != null
                                ? FutureBuilder<Uint8List>(
                                    future: _pickedImage!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    },
                                  )
                                : (_imageUrlController.text.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            _imageUrlController.text,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Center(
                                                    child: Icon(
                                                      Icons
                                                          .image_not_supported_rounded,
                                                      size: 40,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.image_rounded,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        )),
                          ),
                          const SizedBox(height: 12),

                          // Product Name
                          Text(
                            _nameController.text.isEmpty
                                ? 'Nom du Produit'
                                : _nameController.text,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Price
                          Text(
                            () {
                              final parsed = _parsePriceInput(
                                _priceController.text,
                              );
                              return parsed == null
                                  ? AppTheme.formatCurrency(0)
                                  : AppTheme.formatCurrency(parsed);
                            }(),
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Available Units
                          if (_selectedUnits.isNotEmpty) ...[
                            Text(
                              'Disponible en: ${_selectedUnits.join(', ')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHierarchyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organisation du produit',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choisissez la catégorie et la sous-catégorie à laquelle ce produit appartient.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          _buildCategorySection(context),
          const SizedBox(height: 28),
          _buildSubCategorySection(context),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    if (_isCategoryLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Catégorie'),
          const SizedBox(height: 16),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) => _buildShimmerChip(width: 140),
            ),
          ),
        ],
      );
    }

    if (_categoryLoadFailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSectionHeader('Catégorie'),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Lottie.asset(
                  'lib/assets/animations/category_loader.json',
                  height: 120,
                  repeat: true,
                ),
                const SizedBox(height: 12),
                Text(
                  'Impossible de charger les catégories',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifiez votre connexion et réessayez.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadCategoryHierarchy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_allCategories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSectionHeader('Catégorie'),
          const SizedBox(height: 20),
          Lottie.asset(
            'lib/assets/animations/category_loader.json',
            height: 140,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune catégorie trouvée',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez une catégorie avant d’ajouter un produit.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CategoryManagementScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              elevation: 0,
              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Gérer les catégories'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Catégorie'),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _allCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final category = _allCategories[index];
              return _buildCategoryChip(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubCategorySection(BuildContext context) {
    final subs = _currentSubCategories;
    if (_isCategoryLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Sous-catégorie'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(
              4,
              (index) => _buildShimmerChip(width: 120),
            ),
          ),
        ],
      );
    }

    if (_selectedCategory == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Sous-catégorie'),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez une catégorie pour voir ses sous-catégories.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      );
    }

    if (subs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSectionHeader('Sous-catégorie'),
          const SizedBox(height: 16),
          Lottie.asset(
            'lib/assets/animations/category_loader.json',
            height: 120,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune sous-catégorie disponible',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez-en une depuis la gestion des catégories pour continuer.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CategoryManagementScreen(),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Créer une sous-catégorie'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Sous-catégorie'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: subs.map(_buildSubCategoryChip).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(Category category) {
    final isSelected = _selectedCategory?.id == category.id;
    final color = _getColorFromHex(category.color);
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, AppTheme.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.textLight,
            width: 1.4,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 14),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconFromName(category.iconName),
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryChip(SubCategory subCategory) {
    final isSelected = _selectedSubCategory?.id == subCategory.id;
    final baseColor = _getColorFromHex(_selectedCategory?.color ?? '#6366F1');
    return GestureDetector(
      onTap: () => _onSubCategorySelected(subCategory),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? baseColor.withOpacity(0.18) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? baseColor : AppTheme.textLight,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(isSelected ? 0.25 : 0.08),
              blurRadius: isSelected ? 18 : 12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_rounded,
              color: isSelected ? baseColor : AppTheme.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              subCategory.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? baseColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildShimmerChip({double width = 160}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  double? _parsePriceInput(String raw) {
    final sanitized = raw.trim().replaceAll(',', '.');
    return double.tryParse(sanitized);
  }

  IconData _getIconFromName(String iconName) {
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
