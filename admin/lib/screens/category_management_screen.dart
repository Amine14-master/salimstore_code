import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../services/realtime_database_service.dart';
import '../models/product_models.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_search_bar.dart';
import '../firebase_options.dart';

IconData iconForNameGlobal(String name) {
  switch (name.toLowerCase()) {
    // Fruits & Vegetables
    case 'fruits':
    case 'fruit':
      return Icons.apple_rounded;
    case 'vegetables':
    case 'vegetable':
    case 'légumes':
    case 'legumes':
      return Icons.eco_rounded;
    case 'carrot':
    case 'carottes':
      return Icons.agriculture_rounded;

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

class _CategoryListIconPreview extends StatelessWidget {
  final String? iconUrl;
  final IconData fallbackIcon;
  final Color accentColor;

  const _CategoryListIconPreview({
    required this.iconUrl,
    required this.fallbackIcon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final url = iconUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Shimmer.fromColors(
            baseColor: accentColor.withOpacity(0.2),
            highlightColor: Colors.white,
            child: Container(color: Colors.white),
          );
        },
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: accentColor),
    );
  }
}

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  bool _loading = true;
  List<Category> _categories = [];
  Map<String, List<SubCategory>> _subByCategory = {};
  String _search = '';
  bool _gridView = true;

  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _subCategoriesSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
    _load();
  }

  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    _subCategoriesSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    // Get database instance using same method as RealtimeDatabaseService
    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
    );

    // Listen to categories changes
    final categoriesRef = database.ref('categories');
    _categoriesSubscription = categoriesRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(
          event.snapshot.value as Map,
        );
        final categories = <Category>[];

        for (final entry in data.entries) {
          if (entry.value == null) continue;
          try {
            final categoryData = entry.value as Map<dynamic, dynamic>;
            if (categoryData['name'] == null ||
                categoryData['name'].toString().isEmpty) {
              continue;
            }
            categories.add(
              Category.fromJson({
                'id': entry.key.toString(),
                'name': categoryData['name']?.toString() ?? '',
                'description': categoryData['description']?.toString() ?? '',
                'iconName': categoryData['iconName']?.toString() ?? 'category',
                'color': categoryData['color']?.toString() ?? '#6366F1',
                'iconUrl': categoryData['iconUrl']?.toString(),
                'subCategoryIds': categoryData['subCategoryIds'] ?? [],
                'createdAt':
                    categoryData['createdAt'] ??
                    DateTime.now().millisecondsSinceEpoch,
              }),
            );
          } catch (e) {
            print('Error parsing category: $e');
          }
        }
        categories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (mounted) {
          setState(() {
            _categories = categories;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _categories = [];
          });
        }
      }
    });

    // Listen to subcategories changes
    final subCategoriesRef = database.ref('subCategories');
    _subCategoriesSubscription = subCategoriesRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(
          event.snapshot.value as Map,
        );
        final Map<String, List<SubCategory>> result = {};

        for (final entry in data.entries) {
          if (entry.value == null) continue;
          try {
            final subcategoryData = entry.value as Map<dynamic, dynamic>;
            final categoryId = subcategoryData['categoryId']?.toString();

            if (categoryId != null) {
              result.putIfAbsent(categoryId, () => []);
              result[categoryId]!.add(
                SubCategory.fromJson({
                  'id': entry.key.toString(),
                  ...Map<String, dynamic>.from(subcategoryData),
                }),
              );
            }
          } catch (e) {
            print('Error parsing subcategory: $e');
          }
        }

        if (mounted) {
          setState(() {
            _subByCategory = result;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _subByCategory = {};
          });
        }
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Force refresh by clearing cache first
      //await RealtimeDatabaseService.forceRefreshCategories();
      final categories = await RealtimeDatabaseService.getCategories();
      final subs = await RealtimeDatabaseService.getAllSubCategories();
      print('Loaded ${categories.length} categories');
      setState(() {
        _categories = categories;
        _subByCategory = subs;
        _loading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _addOrEditCategory({Category? category}) async {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    final iconUrlCtrl = TextEditingController(text: category?.iconUrl ?? '');
    // Selection state lives outside the modal to be available after it closes
    final predefinedIcons = <Map<String, dynamic>>[
      {'key': 'fruits', 'icon': Icons.apple_rounded, 'label': 'Fruits'},
      {'key': 'vegetables', 'icon': Icons.eco_rounded, 'label': 'Légumes'},
      {'key': 'meat', 'icon': Icons.set_meal_rounded, 'label': 'Viandes'},
      {
        'key': 'seafood',
        'icon': Icons.water_drop_rounded,
        'label': 'Fruits de Mer',
      },
      {
        'key': 'bakery',
        'icon': Icons.bakery_dining_rounded,
        'label': 'Boulangerie',
      },
      {'key': 'dairy', 'icon': Icons.local_dining_rounded, 'label': 'Laiterie'},
      {'key': 'drinks', 'icon': Icons.local_drink_rounded, 'label': 'Boissons'},
      {'key': 'coffee', 'icon': Icons.coffee_rounded, 'label': 'Café'},
      {'key': 'frozen', 'icon': Icons.ac_unit_rounded, 'label': 'Surgelé'},
      {
        'key': 'supermarket',
        'icon': Icons.shopping_bag_rounded,
        'label': 'Market',
      },
      {'key': 'home', 'icon': Icons.home_rounded, 'label': 'Maison'},
      {
        'key': 'cleaning',
        'icon': Icons.cleaning_services_rounded,
        'label': 'Nettoyage',
      },
      {
        'key': 'personal care',
        'icon': Icons.spa_rounded,
        'label': 'Soins Personnels',
      },
      {
        'key': 'electronics',
        'icon': Icons.devices_rounded,
        'label': 'Électronique',
      },
      {
        'key': 'clothing',
        'icon': Icons.checkroom_rounded,
        'label': 'Vêtements',
      },
      {'key': 'baby', 'icon': Icons.child_care_rounded, 'label': 'Bébé'},
      {
        'key': 'health',
        'icon': Icons.medical_services_rounded,
        'label': 'Santé',
      },
      {'key': 'snacks', 'icon': Icons.fastfood_rounded, 'label': 'Snacks'},
      {'key': 'pets', 'icon': Icons.pets_rounded, 'label': 'Animaux'},
    ];
    final palette = <String>[
      '#6366F1', // Indigo
      '#4ECDC4', // Teal
      '#FF6B6B', // Red/Coral
      '#F59E0B', // Amber
      '#10B981', // Emerald
      '#3B82F6', // Blue
      '#A855F7', // Purple
      '#EF4444', // Red
      '#0EA5E9', // Sky
      '#84CC16', // Lime
      '#EC4899', // Pink
      '#F97316', // Orange
      '#06B6D4', // Cyan
      '#8B5CF6', // Violet
      '#14B8A6', // Teal
      '#F43F5E', // Rose
    ];
    String selectedIcon = category?.iconName ?? 'fruits';
    String selectedColor = category?.color ?? '#6366F1';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.category_rounded,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category == null
                                ? 'Nouvelle Catégorie'
                                : 'Modifier la Catégorie',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: 'Nom de la Catégorie',
                      controller: nameCtrl,
                      icon: Icons.label_rounded,
                      hintText: 'Entrez un nom personnalisé',
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'Description',
                      controller: descCtrl,
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Icône prédéfinie',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: predefinedIcons.map((m) {
                        final isSelected = selectedIcon == m['key'];
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedIcon = m['key'] as String;
                              // Don't auto-update name, let user keep their custom name
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey[300]!,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  m['icon'] as IconData,
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  m['label'] as String,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'Icône personnalisée (URL)',
                      controller: iconUrlCtrl,
                      icon: Icons.link_rounded,
                      hintText: 'https://.../icone.png',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Couleur',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: palette.map((hex) {
                        final isSelected =
                            selectedColor.toUpperCase() == hex.toUpperCase();
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedColor = hex;
                            });
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _parseColor(hex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.white,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
                          category == null ? 'Ajouter' : 'Enregistrer',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        final categoryName = nameCtrl.text.trim();

        if (categoryName.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Veuillez entrer un nom pour la catégorie'),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        if (category == null) {
          // Add new category
          final categoryId =
              await RealtimeDatabaseService.addCategoryWithCustomId(
                name: categoryName,
                description: descCtrl.text.trim(),
                iconName: selectedIcon,
                color: selectedColor,
                iconUrl: iconUrlCtrl.text.trim().isEmpty
                    ? null
                    : iconUrlCtrl.text.trim(),
              );

          if (categoryId == null) {
            throw Exception('Failed to create category');
          }

          print('Category created successfully with ID: $categoryId');

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Catégorie "$categoryName" ajoutée avec succès'),
                backgroundColor: AppTheme.successColor,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Update existing category - preserve subcategories
          try {
            await RealtimeDatabaseService.updateCategory(category.id, {
              'name': categoryName,
              'description': descCtrl.text.trim(),
              'iconName': selectedIcon,
              'color': selectedColor,
              if (iconUrlCtrl.text.trim().isNotEmpty)
                'iconUrl': iconUrlCtrl.text.trim(),
              if (iconUrlCtrl.text.trim().isEmpty) 'iconUrl': null,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
              // subCategoryIds will be preserved automatically
            });
          } catch (e) {
            // Re-throw with better message
            throw Exception(e.toString());
          }

          print('Category updated successfully');

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Catégorie "$categoryName" mise à jour avec succès',
                ),
                backgroundColor: AppTheme.successColor,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }

        // Realtime listeners will update automatically, no need to reload
      } on CategoryAlreadyExistsException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('Error saving category: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la Catégorie'),
        content: Text(
          'Supprimer "${category.name}" ? Les sous-catégories liées devront être gérées.',
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
      final ok = await RealtimeDatabaseService.deleteCategoryDeep(category.id);
      if (!ok) return;
      // Realtime listeners will update automatically
    }
  }

  Future<void> _addOrEditSub({
    SubCategory? sub,
    required Category parent,
  }) async {
    final nameCtrl = TextEditingController(text: sub?.name ?? '');
    final descCtrl = TextEditingController(text: sub?.description ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sub == null
                          ? 'Nouvelle Sous-Catégorie'
                          : 'Modifier la Sous-Catégorie',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Nom',
                controller: nameCtrl,
                icon: Icons.badge_rounded,
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Description',
                controller: descCtrl,
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(sub == null ? 'Ajouter' : 'Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      if (nameCtrl.text.trim().isEmpty) return;
      if (sub == null) {
        await RealtimeDatabaseService.addSubCategory(
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim(),
          categoryId: parent.id,
        );
        // Realtime listeners will update automatically
      } else {
        await RealtimeDatabaseService.updateSubCategory(sub.id, {
          'name': nameCtrl.text.trim(),
          'description': descCtrl.text.trim(),
        });
      }
      // Realtime listeners will update automatically
    }
  }

  Future<void> _deleteSub(SubCategory sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer Sous-Catégorie'),
        content: Text(
          'Supprimer "${sub.name}" ? Les produits liés doivent être vérifiés.',
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
      await RealtimeDatabaseService.deleteSubCategory(sub.id);
      // Realtime listeners will update automatically
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;
    final padding = isDesktop
        ? const EdgeInsets.symmetric(horizontal: 40, vertical: 20)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    final filtered = _categories.where((c) {
      if (_search.trim().isEmpty) return true;
      final q = _search.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditCategory(),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catégorie'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Gestion des Catégories',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Rafraîchir',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AdminSearchBar(
                        hintText: 'Rechercher une catégorie...',
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _gridView = !_gridView),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _gridView
                              ? Icons.view_list_rounded
                              : Icons.grid_view_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_loading)
            SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 160,
                    child: Lottie.asset(
                      'lib/assets/animations/category_loader.json',
                      repeat: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Shimmer.fromColors(
                    baseColor: AppTheme.primaryColor.withOpacity(0.2),
                    highlightColor: Colors.white,
                    child: Column(
                      children: List.generate(
                        3,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 32,
                          ),
                          height: 18,
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
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune catégorie',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _search.isEmpty
                                ? 'Commencez par créer votre première catégorie'
                                : 'Aucun résultat pour "$_search"',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _addOrEditCategory(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Ajouter une Catégorie'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
          else if (_gridView)
            SliverPadding(
              padding: padding.copyWith(
                top: padding.top - 4,
                bottom: padding.bottom,
              ),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final cat = filtered[index];
                  return _CategoryCard(
                    category: cat,
                    subCount: (_subByCategory[cat.id] ?? const []).length,
                    onEdit: () => _addOrEditCategory(category: cat),
                    onDelete: () => _deleteCategory(cat),
                    onAddSub: () => _addOrEditSub(parent: cat),
                    subTiles: (_subByCategory[cat.id] ?? const [])
                        .map(
                          (s) => _SubcategoryTile(
                            sub: s,
                            onEdit: () => _addOrEditSub(sub: s, parent: cat),
                            onDelete: () => _deleteSub(s),
                          ),
                        )
                        .toList(),
                  );
                }, childCount: filtered.length),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: isDesktop ? 260 : 200,
                  crossAxisSpacing: isDesktop ? 16 : 12,
                  mainAxisSpacing: isDesktop ? 16 : 12,
                  childAspectRatio: isDesktop ? 0.62 : 0.66,
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final cat = filtered[index];
                final color = _parseColor(cat.color);
                final subs = _subByCategory[cat.id] ?? [];
                return Container(
                  margin: EdgeInsets.fromLTRB(
                    isDesktop ? 40 : 16,
                    12,
                    isDesktop ? 40 : 16,
                    0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.18),
                            color.withOpacity(0.32),
                          ],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: _CategoryListIconPreview(
                          iconUrl: cat.iconUrl,
                          fallbackIcon: iconForNameGlobal(cat.iconName),
                          accentColor: color,
                        ),
                      ),
                    ),
                    title: Text(
                      cat.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(cat.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded),
                          color: AppTheme.primaryColor,
                          onPressed: () => _addOrEditCategory(category: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded),
                          color: AppTheme.errorColor,
                          onPressed: () => _deleteCategory(cat),
                        ),
                      ],
                    ),
                    children: [
                      Row(
                        children: [
                          Text(
                            'Sous-catégories (${subs.length})',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _addOrEditSub(parent: cat),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Ajouter'),
                          ),
                        ],
                      ),
                      if (subs.isEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Aucune sous-catégorie. Ajoutez-en pour organiser vos produits.',
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: subs
                              .map(
                                (s) => _SubcategoryTile(
                                  sub: s,
                                  onEdit: () =>
                                      _addOrEditSub(sub: s, parent: cat),
                                  onDelete: () => _deleteSub(s),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  // Expose a global-style resolver for use in nested classes
  IconData iconForName(String name) {
    return iconForNameGlobal(name);
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final String? hintText;
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final Category category;
  final int subCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSub;
  final List<Widget> subTiles;
  const _CategoryCard({
    required this.category,
    required this.subCount,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSub,
    required this.subTiles,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovering = false;

  Future<void> _showSubcategoriesModal() async {
    final color = _parseColor(widget.category.color);
    final rawIconUrl = widget.category.iconUrl?.trim();
    final String? resolvedIconUrl =
        (rawIconUrl != null && rawIconUrl.isNotEmpty) ? rawIconUrl : null;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.15),
                      child: resolvedIconUrl != null
                          ? ClipOval(
                              child: Image.network(
                                resolvedIconUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => Icon(
                                  iconForNameGlobal(widget.category.iconName),
                                  color: color,
                                ),
                              ),
                            )
                          : Icon(
                              iconForNameGlobal(widget.category.iconName),
                              color: color,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sous-catégories — ${widget.category.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: widget.onAddSub,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.subTiles.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aucune sous-catégorie. Ajoutez-en pour organiser vos produits.',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: SingleChildScrollView(
                      child: Column(children: widget.subTiles),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(widget.category.color);
    final textTheme = Theme.of(context).textTheme;
    final description = widget.category.description.trim();
    final rawIconUrl = widget.category.iconUrl?.trim();
    final String? resolvedIconUrl =
        (rawIconUrl != null && rawIconUrl.isNotEmpty) ? rawIconUrl : null;
    final subLabel = widget.subCount == 1
        ? '1 sous-catégorie'
        : '${widget.subCount} sous-catégories';
    final idLabel = widget.category.id.length > 10
        ? '#${widget.category.id.substring(0, 10)}…'
        : '#${widget.category.id}';

    Widget infoPill(String label, {Color? background, Color? foreground}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
        decoration: BoxDecoration(
          color: background ?? color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: foreground ?? color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    Widget actionButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback onTap,
      Color? background,
      Color? foreground,
    }) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: background ?? color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 18, color: foreground ?? color),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()
          ..translate(0.0, _hovering ? -6.0 : 0.0)
          ..scale(_hovering ? 1.015 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withOpacity(0.08)],
          ),
          border: Border.all(
            color: _hovering
                ? color.withOpacity(0.28)
                : color.withOpacity(0.14),
            width: 1.2,
          ),
          boxShadow: [
            _hovering
                ? BoxShadow(
                    color: color.withOpacity(0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  )
                : BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 148,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildHeroImage(
                      color: color,
                      url: resolvedIconUrl,
                      fallbackIcon: iconForNameGlobal(widget.category.iconName),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.12),
                              Colors.black.withOpacity(0.68),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: infoPill(
                        idLabel,
                        background: Colors.white.withOpacity(0.22),
                        foreground: Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.category.name,
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                              shadows: const [
                                Shadow(color: Colors.black45, blurRadius: 12),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          infoPill(
                            subLabel,
                            background: Colors.white.withOpacity(0.24),
                            foreground: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white.withOpacity(0.94),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (description.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.08)),
                        ),
                        child: Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(
                        children: [
                          actionButton(
                            icon: Icons.edit_rounded,
                            tooltip: 'Modifier',
                            onTap: widget.onEdit,
                          ),
                          const SizedBox(width: 10),
                          actionButton(
                            icon: Icons.delete_rounded,
                            tooltip: 'Supprimer',
                            onTap: widget.onDelete,
                            background: AppTheme.errorColor.withOpacity(0.12),
                            foreground: AppTheme.errorColor,
                          ),
                          const Spacer(),
                          actionButton(
                            icon: Icons.add_circle_rounded,
                            tooltip: 'Ajouter une sous-catégorie',
                            onTap: widget.onAddSub,
                            background: color.withOpacity(0.12),
                            foreground: color,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showSubcategoriesModal,
                          borderRadius: BorderRadius.circular(12),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withOpacity(0.35),
                                  color.withOpacity(0.48),
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.subdirectory_arrow_right_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Voir les sous-catégories (${widget.subCount})',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (_hovering) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.north_east_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
                            ),
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
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  Widget _buildHeroImage({
    required Color color,
    required String? url,
    required IconData fallbackIcon,
  }) {
    final Widget fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.9), color.withOpacity(0.55)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: Colors.white, size: 48),
    );

    if (url == null || url.isEmpty) {
      return fallback;
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Shimmer.fromColors(
          baseColor: color.withOpacity(0.25),
          highlightColor: Colors.white,
          child: fallback,
        );
      },
    );
  }
}

class _SubcategoryTile extends StatelessWidget {
  final SubCategory sub;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _SubcategoryTile({
    required this.sub,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  sub.description,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            color: AppTheme.primaryColor,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            color: AppTheme.errorColor,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
