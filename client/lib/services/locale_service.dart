import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

class LocaleController extends ChangeNotifier {
  LocaleController() : _locale = AppLocalizations.supportedLocales.first;

  static const String _storageKey = 'client_selected_locale';

  Locale _locale;

  Locale get locale => _locale;

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_storageKey);
    if (savedCode == null || savedCode.isEmpty) {
      return;
    }

    final matchedLocale = AppLocalizations.supportedLocales.firstWhere(
      (locale) => locale.languageCode == savedCode,
      orElse: () => _locale,
    );
    if (_locale.languageCode != matchedLocale.languageCode) {
      _locale = matchedLocale;
      notifyListeners();
    }
  }

  Future<void> updateLocale(Locale locale) async {
    final normalizedLocale = AppLocalizations.supportedLocales.firstWhere(
      (supported) => supported.languageCode == locale.languageCode,
      orElse: () => AppLocalizations.supportedLocales.first,
    );

    if (_locale.languageCode == normalizedLocale.languageCode) {
      return;
    }

    _locale = normalizedLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _locale.languageCode);
    notifyListeners();
  }
}

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found in widget tree.');
    final controller = scope?.notifier;
    assert(controller != null, 'LocaleScope provided a null controller.');
    return controller ?? LocaleController();
  }
}

extension LocaleScopeX on BuildContext {
  LocaleController get localeController => LocaleScope.of(this);
}
