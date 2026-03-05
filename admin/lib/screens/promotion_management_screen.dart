import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
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
          priceUnit: result['priceUnit'],
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
          priceUnit: result['priceUnit'],
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(width: 16),
            const Text('Supprimer'),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment supprimer cette promotion ? Cette action est irréversible.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestion des Promotions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: _addPromotion,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Nouvelle Promotion'),
              ),
            ),
        ],
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton.extended(
              onPressed: _addPromotion,
              label: const Text('Promotion'),
              icon: const Icon(Icons.add),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des promotions...'),
                ],
              ),
            )
          : _promotions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_offer_outlined,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Aucune promotion active',
                    style: AppTheme.theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre première offre exceptionnelle maintenant.',
                    textAlign: TextAlign.center,
                    style: AppTheme.theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _addPromotion,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une promotion'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: GridView.builder(
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 1,
                  childAspectRatio: isDesktop ? 0.85 : 1.5,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: _promotions.length,
                itemBuilder: (context, index) {
                  final promotion = _promotions[index];
                  return _buildPromotionCard(promotion, isDesktop);
                },
              ),
            ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion, bool isDesktop) {
    final name = promotion['name'] ?? 'Sans nom';
    final price = (promotion['price'] as num?)?.toDouble() ?? 0.0;
    final originalPrice = (promotion['originalPrice'] as num?)?.toDouble();
    final discountPercentage = (promotion['discountPercentage'] as num?)
        ?.toDouble();
    final imageUrl = promotion['imageUrl'] ?? '';
    final availableUnits = List<String>.from(promotion['availableUnits'] ?? []);

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: isDesktop ? 5 : 4,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadii.lg),
                    ),
                    color: AppColors.surfaceMuted,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadii.lg),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                  ),
                ),
              ),
              // Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${AppTheme.formatCurrency(price)} / ${promotion['priceUnit'] ?? '1kg'}',
                          style: AppTheme.theme.textTheme.headlineSmall
                              ?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (originalPrice != null && originalPrice > price) ...[
                          const SizedBox(width: 8),
                          Text(
                            AppTheme.formatCurrency(originalPrice),
                            style: AppTheme.theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (availableUnits.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availableUnits
                            .take(isDesktop ? 3 : 4)
                            .map((unit) => _buildUnitTag(unit))
                            .toList(),
                      ),
                  ],
                ),
              ),
              // Actions Section
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editPromotion(promotion),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Modifier'),
                    ),
                    TextButton.icon(
                      onPressed: () => _removePromotion(promotion['id']),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppTheme.errorColor,
                      ),
                      label: const Text(
                        'Supprimer',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Discount Badge
          if (discountPercentage != null && discountPercentage > 0)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  boxShadow: AppShadows.subtle,
                ),
                child: Text(
                  '-${discountPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnitTag(String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Text(
        unit,
        style: AppTheme.theme.textTheme.labelSmall?.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
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
  String _selectedPriceUnit = '1kg';

  final List<String> _predefinedPriceUnits = [
    '100g',
    '250g',
    '500g',
    '1kg',
    'unité',
    'litre',
  ];

  final List<String> _predefinedUnits = [
    '100g',
    '250g',
    '500g',
    '1kg',
    'unité',
    'litre',
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Nouvelle Promotion',
                      style: AppTheme.theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Nom du produit'),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Pommes de terre, etc.',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Prix Promotionnel'),
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    hintText: '0.00',
                                    prefixIcon: Icon(Icons.euro),
                                  ),
                                  validator: (value) {
                                    final val = double.tryParse(value ?? '');
                                    if (val == null || val <= 0)
                                      return 'Prix invalide';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Ancien Prix'),
                                TextFormField(
                                  controller: _originalPriceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    hintText: 'Optionnel',
                                    prefixIcon: Icon(Icons.history_rounded),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return null;
                                    final val = double.tryParse(value);
                                    if (val == null || val <= 0)
                                      return 'Prix invalide';
                                    final promo = double.tryParse(
                                      _priceController.text,
                                    );
                                    if (promo != null && val <= promo)
                                      return 'Doit être > promo';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildFieldLabel('Image URL'),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.image_search_rounded),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Lien requis' : null,
                      ),
                      const SizedBox(height: 24),
                      _buildFieldLabel('Unité du prix affiché'),
                      Wrap(
                        spacing: 8,
                        children: _predefinedPriceUnits.map((unit) {
                          final isSelected = _selectedPriceUnit == unit;
                          return ChoiceChip(
                            label: Text(unit),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedPriceUnit = unit);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      _buildFieldLabel('Unités disponibles'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _predefinedUnits
                            .map((u) => _buildSelectableUnit(u))
                            .toList(),
                      ),
                      if (_selectedUnits.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Sélectionnez au moins une unité',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Enregistrer la promotion'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: AppTheme.theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSelectableUnit(String unit) {
    final isSelected = _selectedUnits.contains(unit);
    return FilterChip(
      label: Text(unit),
      selected: isSelected,
      onSelected: (_) => _toggleUnit(unit),
      selectedColor: AppColors.primarySoft,
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : AppColors.border,
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedUnits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez choisir une unité')),
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
        'priceUnit': _selectedPriceUnit,
      });
    }
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
  late String _selectedPriceUnit;

  final List<String> _predefinedPriceUnits = [
    '100g',
    '250g',
    '500g',
    '1kg',
    'unité',
    'litre',
  ];

  final List<String> _predefinedUnits = [
    '100g',
    '250g',
    '500g',
    '1kg',
    'unité',
    'litre',
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
      text: originalPriceValue != null ? originalPriceValue.toString() : '',
    );
    _selectedPriceUnit = widget.promotion['priceUnit'] ?? '1kg';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const Icon(
                      Icons.edit_calendar_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Modifier Promotion',
                      style: AppTheme.theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Nom du produit'),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Pommes de terre, etc.',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Prix Promotionnel'),
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    hintText: '0.00',
                                    prefixIcon: Icon(Icons.euro),
                                  ),
                                  validator: (value) {
                                    final val = double.tryParse(value ?? '');
                                    if (val == null || val <= 0)
                                      return 'Prix invalide';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Ancien Prix'),
                                TextFormField(
                                  controller: _originalPriceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    hintText: 'Optionnel',
                                    prefixIcon: Icon(Icons.history_rounded),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return null;
                                    final val = double.tryParse(value);
                                    if (val == null || val <= 0)
                                      return 'Prix invalide';
                                    final promo = double.tryParse(
                                      _priceController.text,
                                    );
                                    if (promo != null && val <= promo)
                                      return 'Doit être > promo';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildFieldLabel('Image URL'),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: const InputDecoration(
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.image_search_rounded),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Lien requis' : null,
                      ),
                      const SizedBox(height: 24),
                      _buildFieldLabel('Unité du prix affiché'),
                      Wrap(
                        spacing: 8,
                        children: _predefinedPriceUnits.map((unit) {
                          final isSelected = _selectedPriceUnit == unit;
                          return ChoiceChip(
                            label: Text(unit),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedPriceUnit = unit);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      _buildFieldLabel('Unités disponibles'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _predefinedUnits
                            .map((u) => _buildSelectableUnit(u))
                            .toList(),
                      ),
                      if (_selectedUnits.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Sélectionnez au moins une unité',
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Mettre à jour la promotion'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: AppTheme.theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSelectableUnit(String unit) {
    final isSelected = _selectedUnits.contains(unit);
    return FilterChip(
      label: Text(unit),
      selected: isSelected,
      onSelected: (_) => _toggleUnit(unit),
      selectedColor: AppColors.primarySoft,
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : AppColors.border,
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedUnits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez choisir une unité')),
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
        'priceUnit': _selectedPriceUnit,
      });
    }
  }
}
