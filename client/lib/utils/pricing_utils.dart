class PricingUtils {
  // Calculate the actual price for a specific unit based on the base price
  // Base prices are stored as per standard unit (kg, litre, or unit)
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

  // Format price display for UI
  static String formatPriceWithUnit(
    double price,
    String unit, {
    String currency = '€',
  }) {
    final formattedPrice = price.toStringAsFixed(2).replaceAll('.', ',');
    return '$formattedPrice $currency / $unit';
  }

  // Get display name for unit
  static String getUnitDisplayName(String unit) {
    switch (unit.toLowerCase()) {
      case '100g':
        return '100g';
      case '250g':
        return '250g';
      case '500g':
        return '500g';
      case '1kg':
      case 'kg':
        return '1kg';
      case 'unité':
      case 'unit':
      case 'pièce':
      case 'piece':
        return 'unité';
      case 'litre':
      case 'l':
        return '1L';
      default:
        return unit;
    }
  }

  // Calculate price for quantity with specific unit
  static double calculateTotalPrice(
    double basePrice,
    String unit,
    double quantity,
  ) {
    final unitPrice = calculatePriceForUnit(basePrice, unit);
    return unitPrice * quantity;
  }

  // Get increment step for quantity based on unit
  static double getQuantityStep(String unit) {
    final lowerUnit = unit.toLowerCase();
    if (lowerUnit.contains('kg')) return 1.0; // 1kg steps for kg units
    if (lowerUnit == '100g') return 1.0; // 1 x 100g steps
    if (lowerUnit == '250g') return 1.0; // 1 x 250g steps
    if (lowerUnit == '500g') return 1.0; // 1 x 500g steps
    if (lowerUnit.contains('g'))
      return 1.0; // Default 1g steps for other gram units
    if (lowerUnit.contains('l')) return 0.1; // 0.1L steps
    return 1.0; // 1 unit steps for pieces
  }

  // Format quantity display
  static String formatQuantity(double quantity, String unit) {
    final lowerUnit = unit.toLowerCase();

    if (lowerUnit.contains('kg')) {
      if (quantity >= 1) {
        return '${quantity.toStringAsFixed(1).replaceAll('.', ',')} kg';
      } else {
        return '${(quantity * 1000).toInt()}g';
      }
    } else if (lowerUnit == '100g' ||
        lowerUnit == '250g' ||
        lowerUnit == '500g') {
      // For specific gram units, show as multiples of that unit
      if (quantity % 1 == 0) {
        return '${quantity.toInt()}';
      } else {
        return quantity.toStringAsFixed(1).replaceAll('.', ',');
      }
    } else if (lowerUnit.contains('g')) {
      // For other gram units
      return '${quantity.toInt()}g';
    } else if (lowerUnit.contains('l')) {
      return '${quantity.toStringAsFixed(1).replaceAll('.', ',')}L';
    } else {
      // For pieces
      if (quantity % 1 == 0) {
        return quantity.toInt().toString();
      } else {
        return quantity.toStringAsFixed(1).replaceAll('.', ',');
      }
    }
  }
}
