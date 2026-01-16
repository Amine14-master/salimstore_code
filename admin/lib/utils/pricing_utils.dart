class PricingUtils {
  // Base unit prices are always per standard unit:
  // - kg products: price per 1kg
  // - litre products: price per 1 litre
  // - unit products: price per 1 unit

  static double calculatePriceForUnit(double basePrice, String unit) {
    switch (unit.toLowerCase()) {
      case '100g':
        return basePrice * 0.1; // 100g = 0.1kg
      case '250g':
        return basePrice * 0.25; // 250g = 0.25kg
      case '500g':
        return basePrice * 0.5; // 500g = 0.5kg
      case '1kg':
      case 'kg':
        return basePrice; // 1kg = base price
      case 'unité':
      case 'unit':
      case 'pièce':
      case 'piece':
        return basePrice; // 1 unit = base price
      case 'litre':
      case 'l':
        return basePrice; // 1 litre = base price
      default:
        // For any other unit, assume it's the base unit
        return basePrice;
    }
  }

  static String getBaseUnitForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('fruit') ||
        name.contains('légume') ||
        name.contains('viande')) {
      return 'kg'; // Sold by weight, base price per kg
    } else if (name.contains('boisson') || name.contains('liquide')) {
      return 'litre'; // Sold by volume, base price per litre
    } else {
      return 'unité'; // Sold by piece, base price per unit
    }
  }

  static List<String> getAvailableUnitsForCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('fruit') ||
        name.contains('légume') ||
        name.contains('viande')) {
      return ['100g', '250g', '500g', '1kg'];
    } else if (name.contains('boisson') || name.contains('liquide')) {
      return ['litre'];
    } else {
      return ['unité'];
    }
  }

  static String formatPriceDisplay(double price, String unit) {
    return '${price.toString().replaceAll('.', ',')} € / $unit';
  }

  static String getPricingHint(String categoryName) {
    final baseUnit = getBaseUnitForCategory(categoryName);
    switch (baseUnit) {
      case 'kg':
        return 'Prix par kilogramme. Ex: 100€ = 100€/kg (donc 10€ pour 100g)';
      case 'litre':
        return 'Prix par litre. Ex: 5€ = 5€/L';
      case 'unité':
        return 'Prix par unité. Ex: 10€ = 10€ par pièce';
      default:
        return 'Prix par unité de base';
    }
  }
}
