class ContactSupportConfig {
  ContactSupportConfig._();

  static String supportEmail = 'chafaaamine9@gmail.com';

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
