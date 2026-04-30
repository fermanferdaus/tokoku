/// Konfigurasi konstanta aplikasi Tokoku POS.
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Tokoku';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String transactionsCollection = 'transactions';
  static const String customersCollection = 'customers';

  // Firebase Storage Paths
  static const String productImagesPath = 'products';
  static const String userAvatarsPath = 'avatars';

  // Pagination
  static const int defaultPageSize = 20;

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
}
