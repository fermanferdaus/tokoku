import '../entities/user_entity.dart';

/// Kontrak repository untuk operasi autentikasi.
abstract class AuthRepository {
  /// Stream status autentikasi user saat ini.
  Stream<UserEntity> get authStateChanges;

  /// User yang sedang login saat ini.
  UserEntity get currentUser;

  /// Login menggunakan akun Google.
  Future<UserEntity> signInWithGoogle();

  /// Login menggunakan Email & Password.
  Future<UserEntity> signInWithEmail(String email, String password);

  /// Register menggunakan Email & Password.
  Future<UserEntity> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Logout dari aplikasi.
  Future<void> signOut();
}
