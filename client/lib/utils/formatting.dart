import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

class FormattingUtils {
  const FormattingUtils._();

  static final Map<String, NumberFormat> _currencyFormatters = {};

  static NumberFormat _currencyFormatter(
    Locale locale, {
    bool highPrecision = false,
  }) {
    final localeTag = locale.languageCode == 'fr' ? 'fr_FR' : 'en_US';
    final key = '$localeTag|€|${highPrecision ? 'high' : 'std'}';
    return _currencyFormatters.putIfAbsent(key, () {
      final formatter = NumberFormat.currency(locale: localeTag, symbol: '€');
      formatter.minimumFractionDigits = 0;
      formatter.maximumFractionDigits = highPrecision ? 6 : 2;
      return formatter;
    });
  }

  static String formatPrice(double price, AppLocalizations l10n) {
    return formatPriceWithLocale(price, l10n.locale);
  }

  static String formatPriceWithLocale(double price, Locale locale) {
    // Use high precision for very small non-zero numbers
    final useHighPrecision = price.abs() > 0 && price.abs() < 0.01;
    final formatted = _currencyFormatter(
      locale,
      highPrecision: useHighPrecision,
    ).format(price);
    return formatted.replaceAll('\u00A0', ' ');
  }

  static String formatPriceWithUnit(
    double price,
    String unit,
    AppLocalizations l10n,
  ) {
    return '${formatPrice(price, l10n)} / $unit';
  }

  static String formatQuantity(double quantity) {
    if (quantity % 1 == 0) {
      return quantity.toInt().toString();
    }
    final formatted = quantity.toString();
    return formatted
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
