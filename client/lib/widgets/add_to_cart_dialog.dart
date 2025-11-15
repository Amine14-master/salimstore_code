import 'package:flutter/material.dart';

import '../models/product_models.dart';
import '../theme/app_theme.dart';
import '../services/cart_service.dart';
import '../services/realtime_database_service.dart';
import '../utils/formatting.dart';

class AddToCartDialog extends StatefulWidget {
  final Product product;
  final Map<String, double>?
  promotionDiscounts; // Optional promotion discounts map

  const AddToCartDialog({
    super.key,
    required this.product,
    this.promotionDiscounts,
  });

  @override
  State<AddToCartDialog> createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<AddToCartDialog> {
  double _quantity = 1.0;
  String? _selectedUnit;
  Map<String, double> _promotionDiscounts = {};
  bool _loadingPromotions = true;

  @override
  void initState() {
    super.initState();
    if (widget.product.availableUnits.isNotEmpty) {
      _selectedUnit = widget.product.availableUnits.first;
      _quantity = _getInitialQuantity(_selectedUnit!);
    }
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      if (widget.promotionDiscounts != null) {
        setState(() {
          _promotionDiscounts = widget.promotionDiscounts!;
          _loadingPromotions = false;
        });
        return;
      }

      // Load promotions if not provided
      final promotions = await RealtimeDatabaseService.getPromotions();
      final discountMap = <String, double>{};
      for (var promo in promotions) {
        final productId = promo['productId']?.toString();
        final discount = promo['discountPercentage'];
        if (productId != null && discount != null) {
          discountMap[productId] = discount is double
              ? discount
              : (discount as num).toDouble();
        }
      }
      setState(() {
        _promotionDiscounts = discountMap;
        _loadingPromotions = false;
      });
    } catch (e) {
      print('Error loading promotions: $e');
      setState(() {
        _promotionDiscounts = {};
        _loadingPromotions = false;
      });
    }
  }

  double? _getPromotionalPrice() {
    final discount = _promotionDiscounts[widget.product.id];
    if (discount != null && discount > 0) {
      return widget.product.price * (1 - discount / 100);
    }
    return null;
  }

  double _getCurrentPrice() {
    return _getPromotionalPrice() ?? widget.product.price;
  }

  bool get _isOnPromotion => _promotionDiscounts.containsKey(widget.product.id);

  String _formatPrice(double value) {
    final locale = Localizations.localeOf(context);
    return FormattingUtils.formatPriceWithLocale(value, locale);
  }

  double _getInitialQuantity(String unit) {
    // Return appropriate initial quantity based on unit
    if (unit.toLowerCase().contains('kg')) return 1.0;
    if (unit.toLowerCase().contains('g')) return 500.0;
    if (unit.toLowerCase().contains('l')) return 1.0;
    if (unit.toLowerCase().contains('piece') ||
        unit.toLowerCase().contains('pièce'))
      return 1.0;
    return 1.0;
  }

  double _getIncrementStep(String unit) {
    // Return appropriate increment step based on unit
    if (unit.toLowerCase().contains('kg')) return 0.5; // 0.5kg increments
    if (unit.toLowerCase().contains('g')) return 100.0; // 100g increments
    if (unit.toLowerCase().contains('l')) return 0.5; // 0.5L increments
    if (unit.toLowerCase().contains('piece') ||
        unit.toLowerCase().contains('pièce'))
      return 1.0; // 1 piece increments
    return 1.0;
  }

  String _formatQuantity(double qty, String unit) {
    // Format quantity nicely
    if (unit.toLowerCase().contains('kg')) {
      return qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
    }
    if (unit.toLowerCase().contains('g')) {
      return qty.toInt().toString();
    }
    if (unit.toLowerCase().contains('l')) {
      return qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
    }
    return qty.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.product.name,
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
            const SizedBox(height: 16),
            // Product image
            if (widget.product.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.product.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: AppTheme.accentColor.withOpacity(0.1),
                    child: const Icon(Icons.image, size: 50),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            // Unit Selection
            Text(
              'Unité',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (widget.product.availableUnits.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: widget.product.availableUnits.map((unit) {
                    return DropdownMenuItem(value: unit, child: Text(unit));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedUnit = value;
                        _quantity = _getInitialQuantity(value);
                      });
                    }
                  },
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Aucune unité disponible',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            const SizedBox(height: 20),
            // Quantity Selection
            Text(
              'Quantité',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Decrease button
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed:
                        _selectedUnit != null &&
                            _quantity > _getIncrementStep(_selectedUnit!)
                        ? () {
                            setState(() {
                              _quantity -= _getIncrementStep(_selectedUnit!);
                              if (_quantity <
                                  _getIncrementStep(_selectedUnit!)) {
                                _quantity = _getIncrementStep(_selectedUnit!);
                              }
                            });
                          }
                        : null,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                // Quantity display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _selectedUnit != null
                        ? '${_formatQuantity(_quantity, _selectedUnit!)} ${_selectedUnit}'
                        : _quantity.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Increase button
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _selectedUnit != null
                        ? () {
                            setState(() {
                              _quantity += _getIncrementStep(_selectedUnit!);
                            });
                          }
                        : null,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Price display
            if (!_loadingPromotions)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_isOnPromotion) ...[
                          Text(
                            _formatPrice(widget.product.price * _quantity),
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '-${_promotionDiscounts[widget.product.id]!.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ],
                        Text(
                          _formatPrice(_getCurrentPrice() * _quantity),
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedUnit != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${_formatQuantity(_quantity, _selectedUnit!)} $_selectedUnit',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // Add to cart button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedUnit != null && !_loadingPromotions
                    ? () async {
                        final currentPrice = _getCurrentPrice();
                        final originalPrice = _isOnPromotion
                            ? widget.product.price
                            : null;
                        final discount = _isOnPromotion
                            ? _promotionDiscounts[widget.product.id]
                            : null;

                        // Add to cart service with promotion info
                        await CartService.addToCart(
                          productId: widget.product.id,
                          productName: widget.product.name,
                          productImageUrl: widget.product.imageUrl,
                          unitPrice: currentPrice,
                          quantity: _quantity,
                          unit: _selectedUnit!,
                          originalPrice: originalPrice,
                          discountPercentage: discount,
                        );
                        if (context.mounted) {
                          Navigator.pop(context, {
                            'quantity': _quantity,
                            'unit': _selectedUnit,
                          });
                        }
                      }
                    : null,
                icon: const Icon(Icons.shopping_cart),
                label: const Text(
                  'Ajouter au panier',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
