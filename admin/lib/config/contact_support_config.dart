class ContactSupportConfig {
  ContactSupportConfig._();

  static String supportEmail = 'masterr9111@gmail.com';
  static String supportPhone = '0553776497';
  static String supportWhatsApp = '0553776497';

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

  static Uri get supportEmailUri => Uri(scheme: 'mailto', path: supportEmail);
}
