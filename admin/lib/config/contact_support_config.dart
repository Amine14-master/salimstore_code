class ContactSupportConfig {
  ContactSupportConfig._();

  static String supportEmail = 'chafaaamine9@gmail.com';

  static Uri get supportEmailUri => Uri(scheme: 'mailto', path: supportEmail);
}
