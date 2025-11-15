import 'package:flutter/material.dart';
import '../models/product_models.dart';
import '../theme/app_theme.dart';

class AdminProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleAvailability;

  const AdminProductCard({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
    this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.backgroundColor,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: AppTheme.textLight,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: AppTheme.textLight,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Product Name and Status
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.isAvailable
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.isAvailable ? 'Available' : 'Unavailable',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: product.isAvailable
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Price and Rating
          Row(
            children: [
              Text(
                AppTheme.formatCurrency(product.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber[600]),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleAvailability,
                  icon: Icon(
                    product.isAvailable
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 16,
                  ),
                  label: Text(product.isAvailable ? 'Hide' : 'Show'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Category Icon and Name
          GestureDetector(
            onTap: onTap,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getColorFromHex(category.color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getIconFromName(category.iconName),
                    color: _getColorFromHex(category.color),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  category.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              ),
            ],
          ),
        ],
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

class SubCategoryCard extends StatelessWidget {
  final SubCategory subCategory;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SubCategoryCard({
    super.key,
    required this.subCategory,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.category,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subCategory.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subCategory.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subCategory.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${subCategory.productIds.length} products',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
