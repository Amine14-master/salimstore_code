import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/realtime_database_service.dart';

class PromotionManagementScreen extends StatefulWidget {
  const PromotionManagementScreen({super.key});

  @override
  State<PromotionManagementScreen> createState() =>
      _PromotionManagementScreenState();
}

class _PromotionManagementScreenState extends State<PromotionManagementScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _promotions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final promotions = await RealtimeDatabaseService.getPromotions();

      print('Loaded ${promotions.length} promotions');

      setState(() {
        _promotions = promotions;
        _loading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _addPromotion() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddPromotionDialog(),
    );

    if (result != null) {
      try {
        await RealtimeDatabaseService.addPromotion(
          name: result['name'],
          price: result['price'],
          originalPrice: result['originalPrice'],
          imageUrl: result['imageUrl'],
          availableUnits: result['availableUnits'],
        );
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promotion ajoutée avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _editPromotion(Map<String, dynamic> promotion) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditPromotionDialog(promotion: promotion),
    );

    if (result != null) {
      try {
        await RealtimeDatabaseService.updatePromotion(
          promotionId: promotion['id'],
          name: result['name'],
          price: result['price'],
          originalPrice: result['originalPrice'],
          imageUrl: result['imageUrl'],
          availableUnits: result['availableUnits'],
        );
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promotion mise à jour avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _removePromotion(String promotionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la promotion'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette promotion?',
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
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await RealtimeDatabaseService.removePromotion(promotionId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promotion supprimée'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;
    final padding = isDesktop
        ? const EdgeInsets.symmetric(horizontal: 40, vertical: 30)
        : const EdgeInsets.all(18);

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: padding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gestion des Promotions',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 32 : 24,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, size: isDesktop ? 32 : 24),
                    onPressed: _addPromotion,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            // Promotions List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _promotions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 64,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune promotion active',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _addPromotion,
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter une promotion'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: padding,
                        itemCount: _promotions.length,
                        itemBuilder: (context, index) {
                          final promotion = _promotions[index];
                          final name = promotion['name'] ?? 'Sans nom';
                          double price = 0.0;
                          if (promotion['price'] != null) {
                            if (promotion['price'] is double) {
                              price = promotion['price'] as double;
                            } else if (promotion['price'] is num) {
                              price = (promotion['price'] as num).toDouble();
                            }
                          }
                          double? originalPrice;
                          if (promotion['originalPrice'] != null) {
                            if (promotion['originalPrice'] is double) {
                              originalPrice =
                                  promotion['originalPrice'] as double;
                            } else if (promotion['originalPrice'] is num) {
                              originalPrice =
                                  (promotion['originalPrice'] as num)
                                      .toDouble();
                            }
                          }
                          double? discountPercentage;
                          if (promotion['discountPercentage'] != null) {
                            if (promotion['discountPercentage'] is double) {
                              discountPercentage =
                                  promotion['discountPercentage'] as double;
                            } else if (promotion['discountPercentage'] is num) {
                              discountPercentage =
                                  (promotion['discountPercentage'] as num)
                                      .toDouble();
                            }
                          }
                          final imageUrl = promotion['imageUrl'] ?? '';
                          final availableUnits = List<String>.from(
                            promotion['availableUnits'] ?? [],
                          );

                          return Container(
                            margin: EdgeInsets.only(
                              bottom: isDesktop ? 16 : 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                isDesktop ? 20 : 16,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  blurRadius: isDesktop ? 15 : 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(
                                isDesktop ? 20 : 12,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 60,
                                          height: 60,
                                          color: AppTheme.accentColor
                                              .withOpacity(0.1),
                                          child: const Icon(
                                            Icons.image,
                                            size: 30,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: AppTheme.accentColor.withOpacity(
                                          0.1,
                                        ),
                                        child: const Icon(
                                          Icons.image,
                                          size: 30,
                                        ),
                                      ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (originalPrice != null &&
                                          originalPrice > price) ...[
                                        Text(
                                          '${originalPrice.toStringAsFixed(2)} EUR',
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 14,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${price.toStringAsFixed(2)} EUR',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (discountPercentage != null &&
                                                discountPercentage > 0) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.successColor,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '-${discountPercentage.toStringAsFixed(0)}%',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (availableUnits.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      children: availableUnits
                                          .take(3)
                                          .map(
                                            (unit) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                unit,
                                                style: TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editPromotion(promotion),
                                    color: AppTheme.primaryColor,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _removePromotion(promotion['id']),
                                    color: AppTheme.errorColor,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPromotionDialog extends StatefulWidget {
  const _AddPromotionDialog();

  @override
  State<_AddPromotionDialog> createState() => _AddPromotionDialogState();
}

class _AddPromotionDialogState extends State<_AddPromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  List<String> _selectedUnits = [];

  final List<String> _predefinedUnits = [
    'piece',
    'kg',
    'g',
    'L',
    'ml',
    'litre',
    'can',
    'box',
    'pack',
    'bottle',
    'bag',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ajouter une promotion',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Product Name
                Text(
                  'Nom du produit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Entrez le nom du produit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Original Price
                Text(
                  'Ancien prix (EUR)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _originalPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: '€ ',
                    helperText:
                        'Laissez vide si cette promotion n\'a pas d\'ancien prix',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }
                    final parsedValue = double.tryParse(value);
                    if (parsedValue == null || parsedValue <= 0) {
                      return 'Ancien prix invalide';
                    }
                    final priceValue =
                        double.tryParse(_priceController.text) ?? 0;
                    if (parsedValue <= priceValue) {
                      return 'L\'ancien prix doit être supérieur au prix promotionnel';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Price
                Text(
                  'Prix (EUR)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: '€ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le prix est requis';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Prix invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Image URL
                Text(
                  'URL de l\'image',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    hintText: 'https://example.com/image.jpg',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'L\'URL de l\'image est requise';
                    }
                    final uri = Uri.tryParse(value);
                    if (uri == null || !uri.hasScheme) {
                      return 'URL invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Available Units
                Text(
                  'Types d\'achat disponibles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
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
                if (_selectedUnits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Sélectionnez au moins un type d\'achat',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_selectedUnits.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Veuillez sélectionner au moins un type d\'achat',
                              ),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, {
                          'name': _nameController.text.trim(),
                          'price': double.parse(_priceController.text),
                          'originalPrice': _originalPriceController.text.isEmpty
                              ? null
                              : double.parse(_originalPriceController.text),
                          'imageUrl': _imageUrlController.text.trim(),
                          'availableUnits': _selectedUnits,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ajouter la promotion',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditPromotionDialog extends StatefulWidget {
  final Map<String, dynamic> promotion;

  const _EditPromotionDialog({required this.promotion});

  @override
  State<_EditPromotionDialog> createState() => _EditPromotionDialogState();
}

class _EditPromotionDialogState extends State<_EditPromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _imageUrlController;
  late List<String> _selectedUnits;

  final List<String> _predefinedUnits = [
    'piece',
    'kg',
    'g',
    'L',
    'ml',
    'litre',
    'can',
    'box',
    'pack',
    'bottle',
    'bag',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.promotion['name'] ?? '',
    );
    double priceValue = 0.0;
    if (widget.promotion['price'] != null) {
      if (widget.promotion['price'] is double) {
        priceValue = widget.promotion['price'] as double;
      } else if (widget.promotion['price'] is num) {
        priceValue = (widget.promotion['price'] as num).toDouble();
      }
    }
    _priceController = TextEditingController(text: priceValue.toString());
    _imageUrlController = TextEditingController(
      text: widget.promotion['imageUrl'] ?? '',
    );
    _selectedUnits = List<String>.from(
      widget.promotion['availableUnits'] ?? [],
    );
    double? originalPriceValue;
    if (widget.promotion['originalPrice'] != null) {
      if (widget.promotion['originalPrice'] is double) {
        originalPriceValue = widget.promotion['originalPrice'] as double;
      } else if (widget.promotion['originalPrice'] is num) {
        originalPriceValue = (widget.promotion['originalPrice'] as num)
            .toDouble();
      }
    }
    _originalPriceController = TextEditingController(
      text: originalPriceValue != null
          ? originalPriceValue.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Modifier la promotion',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Product Name
                Text(
                  'Nom du produit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Entrez le nom du produit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Price
                Text(
                  'Prix (EUR)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: '€ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le prix est requis';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Prix invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Image URL
                Text(
                  'URL de l\'image',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    hintText: 'https://example.com/image.jpg',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'L\'URL de l\'image est requise';
                    }
                    final uri = Uri.tryParse(value);
                    if (uri == null || !uri.hasScheme) {
                      return 'URL invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Available Units
                Text(
                  'Types d\'achat disponibles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
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
                if (_selectedUnits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Sélectionnez au moins un type d\'achat',
                      style: TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_selectedUnits.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Veuillez sélectionner au moins un type d\'achat',
                              ),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, {
                          'name': _nameController.text.trim(),
                          'price': double.parse(_priceController.text),
                          'imageUrl': _imageUrlController.text.trim(),
                          'availableUnits': _selectedUnits,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Mettre à jour',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
