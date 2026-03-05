class PricingUtils {
  // Calculate the actual price for a specific unit based on the base price
  // Base prices are stored as per standard unit (kg, litre, or unit)
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

  // Format price display for UI
  static String formatPriceWithUnit(
    double price,
    String unit, {
    String currency = '€',
  }) {
    String formattedPrice;
    if (price.abs() > 0 && price.abs() < 0.01) {
      // For very small numbers, show up to 6 decimal places, stripping trailing zeros
      formattedPrice = price
          .toStringAsFixed(6)
          .replaceAll(RegExp(r'0*$'), '')
          .replaceAll(RegExp(r'\.$'), '')
          .replaceAll('.', ',');
    } else {
      // Standard formatting for normal prices
      formattedPrice = price.toStringAsFixed(2).replaceAll('.', ',');
    }
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
    double quantity, [
    String priceUnit = '1kg',
  ]) {
    final unitPrice = calculatePriceForUnit(basePrice, unit, priceUnit);
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
        return '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2).replaceAll(RegExp(r'0$'), '').replaceAll(RegExp(r'\.$'), '').replaceAll('.', ',')} kg';
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
        return quantity
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'0$'), '')
            .replaceAll(RegExp(r'\.$'), '')
            .replaceAll('.', ',');
      }
    } else if (lowerUnit.contains('g')) {
      // For other gram units
      return '${quantity.toInt()}g';
    } else if (lowerUnit.contains('l')) {
      return '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2).replaceAll(RegExp(r'0$'), '').replaceAll(RegExp(r'\.$'), '').replaceAll('.', ',')}L';
    } else {
      // For pieces
      if (quantity % 1 == 0) {
        return quantity.toInt().toString();
      } else {
        return quantity
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'0$'), '')
            .replaceAll(RegExp(r'\.$'), '')
            .replaceAll('.', ',');
      }
    }
  }

  // Format total weight/volume for display
  static String formatTotalWeight(double quantity, String unit) {
    final lowerUnit = unit.toLowerCase();

    String formatDecimal(double value) {
      String s = value.toStringAsFixed(2);
      if (s.contains('.')) {
        s = s.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      return s.replaceAll('.', ',');
    }

    if (lowerUnit.contains('kg')) {
      if (quantity >= 1) {
        return '${formatDecimal(quantity)} kg';
      } else {
        return '${(quantity * 1000).toInt()}g';
      }
    } else if (lowerUnit.contains('g')) {
      final gramMatch = RegExp(r'(\d+)').firstMatch(lowerUnit);
      if (gramMatch != null) {
        final gramsPerUnit = double.parse(gramMatch.group(1)!);
        final totalGrams = (quantity * gramsPerUnit);
        if (totalGrams >= 1000) {
          return '${formatDecimal(totalGrams / 1000)} kg';
        } else {
          return '${totalGrams.toInt()}g';
        }
      }
      return '${quantity.toInt()} $unit';
    } else if (lowerUnit.contains('l')) {
      return '${formatDecimal(quantity)}L';
    } else {
      return quantity % 1 == 0
          ? '${quantity.toInt()} $unit'
          : '${formatDecimal(quantity)} $unit';
    }
  }
}
