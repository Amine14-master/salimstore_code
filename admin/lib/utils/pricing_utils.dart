class PricingUtils {
  // Base unit prices are always per standard unit:
  // - kg products: price per 1kg
  // - litre products: price per 1 litre
  // - unit products: price per 1 unit

  static double calculatePriceForUnit(
    double basePrice,
    String targetUnit, [
    String priceUnit = '1kg',
  ]) {
    // If they are exactly the same, return base price
    if (targetUnit.toLowerCase() == priceUnit.toLowerCase()) return basePrice;

    // Handle units with weight (g, kg)
    double targetWeight = _getWeight(targetUnit);
    double baseWeight = _getWeight(priceUnit);

    // If both have weight, return ratio
    if (targetWeight > 0 && baseWeight > 0) {
      return basePrice * (targetWeight / baseWeight);
    }

    // Default to base price if units are incompatible or have no weight (e.g., 'unité')
    return basePrice;
  }

  static double _getWeight(String unit) {
    unit = unit.toLowerCase();
    if (unit == '100g') return 100.0;
    if (unit == '250g') return 250.0;
    if (unit == '500g') return 500.0;
    if (unit == '1000g' || unit == '1kg' || unit == 'kg') return 1000.0;
    if (unit == 'litre' || unit == 'l') return 1000.0;
    return 0.0; // No measurable weight
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

  static String getPricingHint(String categoryName, [String? unit]) {
    final baseUnit = unit ?? getBaseUnitForCategory(categoryName);
    switch (baseUnit.toLowerCase()) {
      case 'kg':
      case '1kg':
        return 'Prix par kilogramme. Ex: 100€ = 100€/kg (donc 10€ pour 100g)';
      case '500g':
        return 'Prix pour 500 grammes. Ex: 50€ = 50€ pour 500g (donc 100€/kg)';
      case '250g':
        return 'Prix pour 250 grammes. Ex: 25€ = 25€ pour 250g (donc 100€/kg)';
      case '100g':
        return 'Prix pour 100 grammes. Ex: 10€ = 10€ pour 100g (donc 100€/kg)';
      case 'litre':
      case 'l':
        return 'Prix par litre. Ex: 5€ = 5€/L';
      case 'unité':
      case 'unit':
      case 'pièce':
      case 'piece':
        return 'Prix par unité. Ex: 10€ = 10€ par pièce';
      default:
        return 'Prix par $baseUnit';
    }
  }
}
