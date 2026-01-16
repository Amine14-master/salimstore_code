class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = 'dggvbx3c1';
  static const String apiKey = '866161696649349';
  static const String apiSecret = '1MoqBLp8mIyrD6mMW9cBf1XjMlk';

  /// Unsigned upload preset configured in Cloudinary dashboard.
  static const String uploadPreset = 'images';

  /// Folder under the root where profile avatars will be stored.
  static const String profileFolder = 'salimstore/profile_avatars';

  static String get cloudinaryUrl =>
      'cloudinary://$apiKey:$apiSecret@$cloudName';
}
