/// Hằng số toàn cục cho ứng dụng TopTop
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'TopTop';
  static const String appVersion = '1.0.0';

  // Firebase Realtime Database URL
  static const String rtdbUrl =
      'https://mytiktokclone-f9789-default-rtdb.firebaseio.com/';

  // Cloudinary
  static const String cloudinaryCloudName = 'dbxinpidm';

  // Gemini API Key
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyDEI08P5wxq2AWtIpkeYOy8uAW9eS2KTv0',
  );

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String profilesCollection = 'profiles';
  static const String videosCollection = 'videos';
  static const String commentsCollection = 'comments';
  static const String reportsCollection = 'reports';
  static const String userInterestsCollection = 'user_interests';

  // Realtime Database Paths
  static const String chatPath = 'chats';
  static const String notificationsPath = 'Notifications';
  static const String statusPath = 'status';

  // Notification Action Types
  static const String actionFollow = '0';
  static const String actionComment = '1';
  static const String actionLike = '2';
  static const String actionChat = '3';

  // Limits
  static const int maxAvatarBytes = 3 * 1024 * 1024; // 3MB
  static const int videoFeedLimit = 50;

  // Splash
  static const int splashDurationMs = 2000;
}
