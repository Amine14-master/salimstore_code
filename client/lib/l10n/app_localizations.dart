import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('fr')];

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'appTitle': 'Salim Store Client',
      'authChipLogin': 'Customer Login',
      'authChipRegister': 'Customer Registration',
      'authNameLabel': 'Full Name',
      'authNameEmpty': 'Please enter your full name',
      'authNameShort': 'Name must be at least 2 characters',
      'authEmailLabel': 'Email',
      'authEmailEmpty': 'Please enter your email',
      'authEmailInvalid': 'Please enter a valid email',
      'authPhoneLabel': 'Phone Number',
      'authPhoneEmpty': 'Please enter your phone number',
      'authPhoneInvalid': 'Please enter a valid phone number',
      'authPasswordLabel': 'Password',
      'authPasswordEmpty': 'Please enter your password',
      'authPasswordShort': 'Password must be at least 6 characters',
      'authConfirmPasswordLabel': 'Confirm Password',
      'authConfirmPasswordEmpty': 'Please confirm your password',
      'authConfirmPasswordMismatch': 'Passwords do not match',
      'authPrimaryButtonSignIn': 'Sign In',
      'authPrimaryButtonSignUp': 'Create Account',
      'authSuccessSignIn': 'Welcome back!',
      'authSuccessSignUp': 'Account created successfully!',
      'authToggleQuestionSignIn': "Don't have an account?",
      'authToggleQuestionSignUp': 'Already have an account?',
      'authToggleActionSignIn': 'Sign Up',
      'authToggleActionSignUp': 'Sign In',
      'authLanguageLabel': 'Language',
      'authLanguageSubtitle': 'Switch app language instantly',
      'authLanguageEnglish': 'English',
      'authLanguageFrench': 'French',
      'authShimmerGreeting': 'Welcome to Salim Store',
      'authLoadingCaption': 'Preparing a delightful experience for you...',
      'authLanguageChanged': 'Language switched to {language}',
      'snackGenericError': 'An unexpected error occurred',
      'navHome': 'Home',
      'navCategories': 'Categories',
      'navCart': 'Cart',
      'navFavorites': 'Favorites',
      'navOrders': 'Orders',
      'navAccount': 'Account',
      'profileMenuAddressesTitle': 'Delivery addresses',
      'profileMenuAddressesEmpty': 'No address yet',
      'profileMenuAddressesCount': '{count} address',
      'profileMenuAddressesCountPlural': '{count} addresses',
      'profileMenuFavoritesTitle': 'Favorites',
      'profileMenuFavoritesEmpty': 'No favorite yet',
      'profileMenuFavoritesCount': '{count} favorite',
      'profileMenuFavoritesCountPlural': '{count} favorites',
      'profileMenuSupportTitle': 'Support & contact',
      'profileMenuSupportSubtitle': 'Reach out to our team',
      'profileMenuTermsTitle': 'Terms of use',
      'profileMenuTermsSubtitle': 'Read the terms',
      'profileMenuRefundTitle': 'Refund policy',
      'profileMenuRefundSubtitle': 'Read the policy',
      'profileLogoutButton': 'Sign out',
      'profileLogoutDialogTitle': 'Sign out',
      'profileLogoutDialogMessage': 'Are you sure you want to sign out?',
      'dialogCancel': 'Cancel',
      'dialogConfirm': 'Confirm',
      'profileLanguageTitle': 'Language preferences',
      'profileLanguageSubtitle': 'Select your preferred language',
      'profileLanguageSheetTitle': 'Choose language',
      'profileLanguageSheetDescription':
          'Pick the language that fits you best. Changes apply immediately.',
      'profileLanguageOptionSystem': 'System default',
      'profileLanguageOptionEnglish': 'English',
      'profileLanguageOptionFrench': 'French',
      'profileLanguageSelectedLabel': 'Selected',
      'profileNameLabel': 'Full name',
      'profilePhoneLabel': 'Phone number',
      'profileEditProfileTitle': 'Edit profile',
      'profileSave': 'Save',
      'profileUploading': 'Uploading...',
    },
    'fr': {
      'appTitle': 'Client Salim Store',
      'authChipLogin': 'Connexion Client',
      'authChipRegister': 'Inscription Client',
      'authNameLabel': 'Nom complet',
      'authNameEmpty': 'Veuillez entrer votre nom complet',
      'authNameShort': 'Le nom doit contenir au moins 2 caractères',
      'authEmailLabel': 'E-mail',
      'authEmailEmpty': 'Veuillez entrer votre e-mail',
      'authEmailInvalid': 'Veuillez entrer un e-mail valide',
      'authPhoneLabel': 'Numéro de téléphone',
      'authPhoneEmpty': 'Veuillez entrer votre numéro de téléphone',
      'authPhoneInvalid': 'Veuillez entrer un numéro valide',
      'authPasswordLabel': 'Mot de passe',
      'authPasswordEmpty': 'Veuillez entrer votre mot de passe',
      'authPasswordShort':
          'Le mot de passe doit contenir au moins 6 caractères',
      'authConfirmPasswordLabel': 'Confirmer le mot de passe',
      'authConfirmPasswordEmpty': 'Veuillez confirmer votre mot de passe',
      'authConfirmPasswordMismatch': 'Les mots de passe ne correspondent pas',
      'authPrimaryButtonSignIn': 'Connexion',
      'authPrimaryButtonSignUp': 'Créer un compte',
      'authSuccessSignIn': 'Bon retour !',
      'authSuccessSignUp': 'Compte créé avec succès !',
      'authToggleQuestionSignIn': "Vous n'avez pas de compte ?",
      'authToggleQuestionSignUp': 'Vous avez déjà un compte ?',
      'authToggleActionSignIn': 'Inscription',
      'authToggleActionSignUp': 'Connexion',
      'authLanguageLabel': 'Langue',
      'authLanguageSubtitle':
          'Changez la langue de l’application instantanément',
      'authLanguageEnglish': 'Anglais',
      'authLanguageFrench': 'Français',
      'authShimmerGreeting': 'Bienvenue chez Salim Store',
      'authLoadingCaption':
          'Nous préparons une expérience agréable pour vous...',
      'authLanguageChanged': 'Langue changée en {language}',
      'snackGenericError': 'Une erreur inattendue est survenue',
      'navHome': 'Accueil',
      'navCategories': 'Catégories',
      'navCart': 'Panier',
      'navFavorites': 'Favoris',
      'navOrders': 'Commandes',
      'navAccount': 'Compte',
      'profileMenuAddressesTitle': 'Mes adresses de livraison',
      'profileMenuAddressesEmpty': 'Aucune adresse',
      'profileMenuAddressesCount': '{count} adresse',
      'profileMenuAddressesCountPlural': '{count} adresses',
      'profileMenuFavoritesTitle': 'Favoris',
      'profileMenuFavoritesEmpty': 'Aucun favori',
      'profileMenuFavoritesCount': '{count} favori',
      'profileMenuFavoritesCountPlural': '{count} favoris',
      'profileMenuSupportTitle': 'Support et contact',
      'profileMenuSupportSubtitle': 'Contactez notre équipe',
      'profileMenuTermsTitle': "Conditions d'utilisation",
      'profileMenuTermsSubtitle': 'Lire les conditions',
      'profileMenuRefundTitle': 'Politique de remboursement',
      'profileMenuRefundSubtitle': 'Lire la politique',
      'profileLogoutButton': 'Déconnexion',
      'profileLogoutDialogTitle': 'Déconnexion',
      'profileLogoutDialogMessage':
          'Êtes-vous sûr de vouloir vous déconnecter ?',
      'dialogCancel': 'Annuler',
      'dialogConfirm': 'Confirmer',
      'profileLanguageTitle': 'Préférences de langue',
      'profileLanguageSubtitle': 'Sélectionnez votre langue préférée',
      'profileLanguageSheetTitle': 'Choisissez la langue',
      'profileLanguageSheetDescription':
          'Choisissez la langue qui vous convient. Le changement est immédiat.',
      'profileLanguageOptionSystem': 'Langue du système',
      'profileLanguageOptionEnglish': 'Anglais',
      'profileLanguageOptionFrench': 'Français',
      'profileLanguageSelectedLabel': 'Sélectionné',
      'profileNameLabel': 'Nom complet',
      'profilePhoneLabel': 'Numéro de téléphone',
      'profileEditProfileTitle': 'Modifier le profil',
      'profileSave': 'Enregistrer',
      'profileUploading': 'Téléversement...',
    },
  };

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String _text(String key) {
    final languageCode = locale.languageCode;
    final values = _localizedValues[languageCode] ?? _localizedValues['en']!;
    return values[key] ?? _localizedValues['en']![key] ?? key;
  }

  String get appTitle => _text('appTitle');
  String get authChipLogin => _text('authChipLogin');
  String get authChipRegister => _text('authChipRegister');
  String get authNameLabel => _text('authNameLabel');
  String get authNameEmpty => _text('authNameEmpty');
  String get authNameShort => _text('authNameShort');
  String get authEmailLabel => _text('authEmailLabel');
  String get authEmailEmpty => _text('authEmailEmpty');
  String get authEmailInvalid => _text('authEmailInvalid');
  String get authPhoneLabel => _text('authPhoneLabel');
  String get authPhoneEmpty => _text('authPhoneEmpty');
  String get authPhoneInvalid => _text('authPhoneInvalid');
  String get authPasswordLabel => _text('authPasswordLabel');
  String get authPasswordEmpty => _text('authPasswordEmpty');
  String get authPasswordShort => _text('authPasswordShort');
  String get authConfirmPasswordLabel => _text('authConfirmPasswordLabel');
  String get authConfirmPasswordEmpty => _text('authConfirmPasswordEmpty');
  String get authConfirmPasswordMismatch =>
      _text('authConfirmPasswordMismatch');
  String get authPrimaryButtonSignIn => _text('authPrimaryButtonSignIn');
  String get authPrimaryButtonSignUp => _text('authPrimaryButtonSignUp');
  String get authSuccessSignIn => _text('authSuccessSignIn');
  String get authSuccessSignUp => _text('authSuccessSignUp');
  String get authToggleQuestionSignIn => _text('authToggleQuestionSignIn');
  String get authToggleQuestionSignUp => _text('authToggleQuestionSignUp');
  String get authToggleActionSignIn => _text('authToggleActionSignIn');
  String get authToggleActionSignUp => _text('authToggleActionSignUp');
  String get authLanguageLabel => _text('authLanguageLabel');
  String get authLanguageSubtitle => _text('authLanguageSubtitle');
  String get authLanguageEnglish => _text('authLanguageEnglish');
  String get authLanguageFrench => _text('authLanguageFrench');
  String get authShimmerGreeting => _text('authShimmerGreeting');
  String get authLoadingCaption => _text('authLoadingCaption');
  String authLanguageChangedMessage(String languageName) =>
      _text('authLanguageChanged').replaceAll('{language}', languageName);
  String get snackGenericError => _text('snackGenericError');
  String get navHome => _text('navHome');
  String get navCategories => _text('navCategories');
  String get navCart => _text('navCart');
  String get navFavorites => _text('navFavorites');
  String get navOrders => _text('navOrders');
  String get navAccount => _text('navAccount');
  String get profileMenuAddressesTitle => _text('profileMenuAddressesTitle');
  String get profileMenuAddressesEmpty => _text('profileMenuAddressesEmpty');
  String get profileMenuFavoritesTitle => _text('profileMenuFavoritesTitle');
  String get profileMenuFavoritesEmpty => _text('profileMenuFavoritesEmpty');
  String get profileMenuSupportTitle => _text('profileMenuSupportTitle');
  String get profileMenuSupportSubtitle => _text('profileMenuSupportSubtitle');
  String get profileMenuTermsTitle => _text('profileMenuTermsTitle');
  String get profileMenuTermsSubtitle => _text('profileMenuTermsSubtitle');
  String get profileMenuRefundTitle => _text('profileMenuRefundTitle');
  String get profileMenuRefundSubtitle => _text('profileMenuRefundSubtitle');
  String get profileLogoutButton => _text('profileLogoutButton');
  String get profileLogoutDialogTitle => _text('profileLogoutDialogTitle');
  String get profileLogoutDialogMessage => _text('profileLogoutDialogMessage');
  String get dialogCancel => _text('dialogCancel');
  String get dialogConfirm => _text('dialogConfirm');
  String get profileLanguageTitle => _text('profileLanguageTitle');
  String get profileLanguageSubtitle => _text('profileLanguageSubtitle');
  String get profileLanguageSheetTitle => _text('profileLanguageSheetTitle');
  String get profileLanguageSheetDescription =>
      _text('profileLanguageSheetDescription');
  String get profileLanguageOptionSystem =>
      _text('profileLanguageOptionSystem');
  String get profileLanguageOptionEnglish =>
      _text('profileLanguageOptionEnglish');
  String get profileLanguageOptionFrench =>
      _text('profileLanguageOptionFrench');
  String get profileLanguageSelectedLabel =>
      _text('profileLanguageSelectedLabel');
  String get profileNameLabel => _text('profileNameLabel');
  String get profilePhoneLabel => _text('profilePhoneLabel');
  String get profileEditProfileTitle => _text('profileEditProfileTitle');
  String get profileSave => _text('profileSave');
  String get profileUploading => _text('profileUploading');

  String addressCountLabel(int count) {
    if (count == 0) return profileMenuAddressesEmpty;
    if (count == 1) {
      return _text('profileMenuAddressesCount').replaceAll('{count}', '1');
    }
    return _text(
      'profileMenuAddressesCountPlural',
    ).replaceAll('{count}', '$count');
  }

  String favoritesCountLabel(int count) {
    if (count == 0) return profileMenuFavoritesEmpty;
    if (count == 1) {
      return _text('profileMenuFavoritesCount').replaceAll('{count}', '1');
    }
    return _text(
      'profileMenuFavoritesCountPlural',
    ).replaceAll('{count}', '$count');
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
