import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('fr')];

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'appTitle': 'Livriyes',
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
      'authShimmerGreeting': 'Welcome to Livriyes',
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
      // Profile Tab
      'profileEditInfo': 'Edit my info',
      'profileEditInfoSubtitle': 'Name, phone, email',
      'profileChangePassword': 'Change my password',
      'profileChangePasswordSubtitle': 'Secure your account',
      'profileMyAddresses': 'My addresses',
      'profileMyAddressesSubtitle': 'Manage your delivery locations',
      'profileMyFavorites': 'My favorites',
      'profileMyFavoritesSubtitle': 'Find your favorites',
      'profileSupportContact': 'Support and contact',
      'profileCallButton': 'Call',
      'profileWebsiteButton': 'Website',
      'profileEmailButton': 'Email',
      'profileWhatsAppButton': 'WhatsApp',
      'profileUpdateInfoTitle': 'Update my information',
      'profileUpdateInfoSubtitle':
          'Update your contact details so we can always reach you.',
      'profileFullNameLabel': 'Full name',
      'profilePhoneNumberLabel': 'Phone number',
      'profileEmailLabel': 'Email address',
      'profileFillAllFields': 'Please fill in all information.',
      'profileValidEmail': 'Please enter a valid email.',
      'profileSaveButton': 'Save',
      'profileUpdatedSuccess': 'Profile updated successfully',
      'profileChangePasswordTitle': 'Change my password',
      'profileChangePasswordDesc':
          'To secure your account, use a unique and confidential password.',
      'profileCurrentPassword': 'Current password',
      'profileNewPassword': 'New password',
      'profileConfirmNewPassword': 'Confirm new password',
      'profileFillAllPasswordFields': 'Please fill in all fields.',
      'profilePasswordMinLength': 'New password must be at least 6 characters.',
      'profilePasswordsDoNotMatch': 'Passwords do not match.',
      'profilePasswordUpdatedSuccess': 'Password updated successfully',
      'profileCustomizeAvatar': 'Customize your avatar',
      'profileUploadPhotoDesc':
          'Upload a photo from your gallery or capture a new selfie instantly.',
      'profileGalleryButton': 'Gallery',
      'profileCameraButton': 'Camera',
      'profilePhotoUpdateError': 'Unable to update photo: {error}',
      'profilePhotoUpdatedSuccess': 'Profile photo updated successfully!',
      'profileCannotOpenPhone': 'Unable to open phone app.',
      'profileCannotOpenEmail': 'Unable to open email app.',
      'profileCannotOpenWhatsApp': 'Unable to open WhatsApp.',
      'profileCannotOpenWebsite': 'Unable to open website.',
      // Address Management
      'addressManagementTitle': 'My Addresses',
      'addressNoAddresses': 'No addresses yet',
      'addressAddFirst': 'Add your first delivery address',
      'addressAddNew': 'Add new address',
      'addressDefault': 'Default',
      'addressSetAsDefault': 'Set as default',
      'addressEdit': 'Edit',
      'addressDelete': 'Delete',
      'addressDeleteConfirmTitle': 'Delete address',
      'addressDeleteConfirmMessage':
          'Are you sure you want to delete this address?',
      'addressDeletedSuccess': 'Address deleted successfully',
      'addressSetDefaultSuccess': 'Default address updated',
      // Address Picker
      'addressPickerAddTitle': 'Add Address',
      'addressPickerEditTitle': 'Edit Address',
      'addressPickerManualMode': 'Manual',
      'addressPickerAutoMode': 'Auto',
      'addressPickerSelectOnMap': 'Select your location on the map',
      'addressPickerDragMarker': 'Drag the marker to adjust your location',
      'addressPickerMyLocation': 'My location',
      'addressPickerSaveAddress': 'Save address',
      'addressPickerSaveDialogTitle': 'Save address',
      'addressPickerEditDialogTitle': 'Edit address',
      'addressPickerAddressNameLabel': 'Address name',
      'addressPickerAddressNameHint': 'E.g.: Home, Office, Delivery...',
      'addressPickerSetAsDefault': 'Set as default address',
      'addressPickerEnterName': 'Please enter a name for the address',
      'addressPickerSavedSuccess': 'Address "{label}" saved successfully',
      'addressPickerSaveError': 'Error saving: {error}',
      'addressPickerSelectPosition': 'Please select a position on the map',
      'addressPickerLocationError': 'Location error: {error}',
      'addressPickerLocationServicesDisabled':
          'Location services are disabled.',
      'addressPickerLocationPermissionDenied':
          'Location permissions are denied',
      'addressPickerLocationPermissionDeniedForever':
          'Location permissions are permanently denied.',
      'addressPickerDetectingAddress': 'Detecting address...',
      'addressPickerAddresses': 'Addresses',
    },
    'fr': {
      'appTitle': 'Livriyes',
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
          'Changez la langue de l\'application instantanément',
      'authLanguageEnglish': 'Anglais',
      'authLanguageFrench': 'Français',
      'authShimmerGreeting': 'Bienvenue chez Livriyes',
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
      // Profile Tab
      'profileEditInfo': 'Modifier mes infos',
      'profileEditInfoSubtitle': 'Nom, téléphone, email',
      'profileChangePassword': 'Changer mon mot de passe',
      'profileChangePasswordSubtitle': 'Sécurisez votre compte',
      'profileMyAddresses': 'Mes adresses',
      'profileMyAddressesSubtitle': 'Gérez vos lieux de livraison',
      'profileMyFavorites': 'Mes favoris',
      'profileMyFavoritesSubtitle': 'Retrouvez vos coups de cœur',
      'profileSupportContact': 'Support et contact',
      'profileCallButton': 'Appeler',
      'profileWebsiteButton': 'Site Web',
      'profileEmailButton': 'Email',
      'profileWhatsAppButton': 'WhatsApp',
      'profileUpdateInfoTitle': 'Mettre à jour mes informations',
      'profileUpdateInfoSubtitle':
          'Actualisez vos coordonnées afin que nous puissions toujours vous contacter.',
      'profileFullNameLabel': 'Nom complet',
      'profilePhoneNumberLabel': 'Numéro de téléphone',
      'profileEmailLabel': 'Adresse email',
      'profileFillAllFields': 'Veuillez remplir toutes les informations.',
      'profileValidEmail': 'Veuillez saisir un email valide.',
      'profileSaveButton': 'Enregistrer',
      'profileUpdatedSuccess': 'Profil mis à jour avec succès',
      'profileChangePasswordTitle': 'Modifier mon mot de passe',
      'profileChangePasswordDesc':
          'Pour sécuriser votre compte, utilisez un mot de passe unique et confidentiel.',
      'profileCurrentPassword': 'Mot de passe actuel',
      'profileNewPassword': 'Nouveau mot de passe',
      'profileConfirmNewPassword': 'Confirmer le nouveau mot de passe',
      'profileFillAllPasswordFields': 'Veuillez remplir tous les champs.',
      'profilePasswordMinLength':
          'Le nouveau mot de passe doit contenir au moins 6 caractères.',
      'profilePasswordsDoNotMatch': 'Les mots de passe ne correspondent pas.',
      'profilePasswordUpdatedSuccess': 'Mot de passe mis à jour avec succès',
      'profileCustomizeAvatar': 'Personnalisez votre avatar',
      'profileUploadPhotoDesc':
          'Téléversez une photo depuis votre galerie ou capturez un nouveau selfie instantanément.',
      'profileGalleryButton': 'Galerie',
      'profileCameraButton': 'Caméra',
      'profilePhotoUpdateError':
          'Impossible de mettre à jour la photo: {error}',
      'profilePhotoUpdatedSuccess': 'Photo de profil mise à jour avec succès !',
      'profileCannotOpenPhone': 'Impossible d`ouvrir l\'application téléphone.',
      'profileCannotOpenEmail': 'Impossible d\'ouvrir l\'application mail.',
      'profileCannotOpenWhatsApp': 'Impossible d\'ouvrir WhatsApp.',
      'profileCannotOpenWebsite': 'Impossible d\'ouvrir le site web.',
      // Address Management
      'addressManagementTitle': 'Mes Adresses',
      'addressNoAddresses': 'Aucune adresse pour le moment',
      'addressAddFirst': 'Ajoutez votre première adresse de livraison',
      'addressAddNew': 'Ajouter une nouvelle adresse',
      'addressDefault': 'Par défaut',
      'addressSetAsDefault': 'Définir par défaut',
      'addressEdit': 'Modifier',
      'addressDelete': 'Supprimer',
      'addressDeleteConfirmTitle': 'Supprimer l\'adresse',
      'addressDeleteConfirmMessage':
          'Êtes-vous sûr de vouloir supprimer cette adresse ?',
      'addressDeletedSuccess': 'Adresse supprimée avec succès',
      'addressSetDefaultSuccess': 'Adresse par défaut mise à jour',
      // Address Picker
      'addressPickerAddTitle': 'Ajouter une adresse',
      'addressPickerEditTitle': 'Modifier l\'adresse',
      'addressPickerManualMode': 'Manuel',
      'addressPickerAutoMode': 'Auto',
      'addressPickerSelectOnMap': 'Sélectionnez votre position sur la carte',
      'addressPickerDragMarker':
          'Faites glisser le marqueur pour ajuster votre position',
      'addressPickerMyLocation': 'Ma position',
      'addressPickerSaveAddress': 'Enregistrer l\'adresse',
      'addressPickerSaveDialogTitle': 'Enregistrer l\'adresse',
      'addressPickerEditDialogTitle': 'Modifier l\'adresse',
      'addressPickerAddressNameLabel': 'Nom de l\'adresse',
      'addressPickerAddressNameHint': 'Ex: Maison, Bureau, Livraison...',
      'addressPickerSetAsDefault': 'Définir comme adresse par défaut',
      'addressPickerEnterName': 'Veuillez entrer un nom pour l\'adresse',
      'addressPickerSavedSuccess': 'Adresse "{label}" enregistrée avec succès',
      'addressPickerSaveError': 'Erreur lors de l\'enregistrement: {error}',
      'addressPickerSelectPosition':
          'Veuillez sélectionner une position sur la carte',
      'addressPickerLocationError': 'Erreur localisation: {error}',
      'addressPickerLocationServicesDisabled':
          'Les services de localisation sont désactivés.',
      'addressPickerLocationPermissionDenied':
          'Les permissions de localisation sont refusées',
      'addressPickerLocationPermissionDeniedForever':
          'Les permissions de localisation sont définitivement refusées.',
      'addressPickerDetectingAddress': 'Détection de l\'adresse...',
      'addressPickerAddresses': 'Adresses',
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

  // Profile Tab getters
  String get profileEditInfo => _text('profileEditInfo');
  String get profileEditInfoSubtitle => _text('profileEditInfoSubtitle');
  String get profileChangePassword => _text('profileChangePassword');
  String get profileChangePasswordSubtitle =>
      _text('profileChangePasswordSubtitle');
  String get profileMyAddresses => _text('profileMyAddresses');
  String get profileMyAddressesSubtitle => _text('profileMyAddressesSubtitle');
  String get profileMyFavorites => _text('profileMyFavorites');
  String get profileMyFavoritesSubtitle => _text('profileMyFavoritesSubtitle');
  String get profileSupportContact => _text('profileSupportContact');
  String get profileCallButton => _text('profileCallButton');
  String get profileWebsiteButton => _text('profileWebsiteButton');
  String get profileEmailButton => _text('profileEmailButton');
  String get profileWhatsAppButton => _text('profileWhatsAppButton');
  String get profileUpdateInfoTitle => _text('profileUpdateInfoTitle');
  String get profileUpdateInfoSubtitle => _text('profileUpdateInfoSubtitle');
  String get profileFullNameLabel => _text('profileFullNameLabel');
  String get profilePhoneNumberLabel => _text('profilePhoneNumberLabel');
  String get profileEmailLabel => _text('profileEmailLabel');
  String get profileFillAllFields => _text('profileFillAllFields');
  String get profileValidEmail => _text('profileValidEmail');
  String get profileSaveButton => _text('profileSaveButton');
  String get profileUpdatedSuccess => _text('profileUpdatedSuccess');
  String get profileChangePasswordTitle => _text('profileChangePasswordTitle');
  String get profileChangePasswordDesc => _text('profileChangePasswordDesc');
  String get profileCurrentPassword => _text('profileCurrentPassword');
  String get profileNewPassword => _text('profileNewPassword');
  String get profileConfirmNewPassword => _text('profileConfirmNewPassword');
  String get profileFillAllPasswordFields =>
      _text('profileFillAllPasswordFields');
  String get profilePasswordMinLength => _text('profilePasswordMinLength');
  String get profilePasswordsDoNotMatch => _text('profilePasswordsDoNotMatch');
  String get profilePasswordUpdatedSuccess =>
      _text('profilePasswordUpdatedSuccess');
  String get profileCustomizeAvatar => _text('profileCustomizeAvatar');
  String get profileUploadPhotoDesc => _text('profileUploadPhotoDesc');
  String get profileGalleryButton => _text('profileGalleryButton');
  String get profileCameraButton => _text('profileCameraButton');
  String profilePhotoUpdateErrorMessage(String error) =>
      _text('profilePhotoUpdateError').replaceAll('{error}', error);
  String get profilePhotoUpdatedSuccess => _text('profilePhotoUpdatedSuccess');
  String get profileCannotOpenPhone => _text('profileCannotOpenPhone');
  String get profileCannotOpenEmail => _text('profileCannotOpenEmail');
  String get profileCannotOpenWhatsApp => _text('profileCannotOpenWhatsApp');
  String get profileCannotOpenWebsite => _text('profileCannotOpenWebsite');

  // Address Management getters
  String get addressManagementTitle => _text('addressManagementTitle');
  String get addressNoAddresses => _text('addressNoAddresses');
  String get addressAddFirst => _text('addressAddFirst');
  String get addressAddNew => _text('addressAddNew');
  String get addressDefault => _text('addressDefault');
  String get addressSetAsDefault => _text('addressSetAsDefault');
  String get addressEdit => _text('addressEdit');
  String get addressDelete => _text('addressDelete');
  String get addressDeleteConfirmTitle => _text('addressDeleteConfirmTitle');
  String get addressDeleteConfirmMessage =>
      _text('addressDeleteConfirmMessage');
  String get addressDeletedSuccess => _text('addressDeletedSuccess');
  String get addressSetDefaultSuccess => _text('addressSetDefaultSuccess');

  // Address Picker getters
  String get addressPickerAddTitle => _text('addressPickerAddTitle');
  String get addressPickerEditTitle => _text('addressPickerEditTitle');
  String get addressPickerManualMode => _text('addressPickerManualMode');
  String get addressPickerAutoMode => _text('addressPickerAutoMode');
  String get addressPickerSelectOnMap => _text('addressPickerSelectOnMap');
  String get addressPickerDragMarker => _text('addressPickerDragMarker');
  String get addressPickerMyLocation => _text('addressPickerMyLocation');
  String get addressPickerSaveAddress => _text('addressPickerSaveAddress');
  String get addressPickerSaveDialogTitle =>
      _text('addressPickerSaveDialogTitle');
  String get addressPickerEditDialogTitle =>
      _text('addressPickerEditDialogTitle');
  String get addressPickerAddressNameLabel =>
      _text('addressPickerAddressNameLabel');
  String get addressPickerAddressNameHint =>
      _text('addressPickerAddressNameHint');
  String get addressPickerSetAsDefault => _text('addressPickerSetAsDefault');
  String get addressPickerEnterName => _text('addressPickerEnterName');
  String addressPickerSavedSuccessMessage(String label) =>
      _text('addressPickerSavedSuccess').replaceAll('{label}', label);
  String addressPickerSaveErrorMessage(String error) =>
      _text('addressPickerSaveError').replaceAll('{error}', error);
  String get addressPickerSelectPosition =>
      _text('addressPickerSelectPosition');
  String addressPickerLocationErrorMessage(String error) =>
      _text('addressPickerLocationError').replaceAll('{error}', error);
  String get addressPickerLocationServicesDisabled =>
      _text('addressPickerLocationServicesDisabled');
  String get addressPickerLocationPermissionDenied =>
      _text('addressPickerLocationPermissionDenied');
  String get addressPickerLocationPermissionDeniedForever =>
      _text('addressPickerLocationPermissionDeniedForever');
  String get addressPickerDetectingAddress =>
      _text('addressPickerDetectingAddress');
  String get addressPickerAddresses => _text('addressPickerAddresses');

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
