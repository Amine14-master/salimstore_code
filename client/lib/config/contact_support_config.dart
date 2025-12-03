class ContactSupportConfig {
  ContactSupportConfig._();

  static String supportEmail = 'support@livriyes.app';
  static String supportPhone = '+213778029965';
  static String supportWhatsApp = '+213778029965';

  static Uri buildSupportEmailUri({String? body}) {
    return Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'Assistance SalimStore',
        if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
      },
    );
  }
}
