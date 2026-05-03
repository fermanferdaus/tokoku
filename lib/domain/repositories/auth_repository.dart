import 'dart:io';

import '../entities/user_entity.dart';

/// Kontrak repository untuk operasi autentikasi.
abstract class AuthRepository {
  /// Stream status autentikasi user saat ini.
  Stream<UserEntity> get authStateChanges;

  /// User yang sedang login saat ini.
  UserEntity get currentUser;

  /// Login menggunakan Email & Password.
  Future<UserEntity> signInWithEmail(String email, String password);

  /// Register menggunakan Email & Password.
  Future<UserEntity> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String role = 'kasir',
  });

  /// Logout dari aplikasi.
  Future<void> signOut();

  /// Ambil semua user (Admin Only).
  Future<List<UserEntity>> getUsers();

  /// Hapus user berdasarkan UID.
  Future<void> deleteUser(String uid);

  /// Update data user.
  Future<void> updateUser(UserEntity user, {String? password});

  /// Upload foto profil user dan kembalikan URL-nya.
  Future<String> uploadUserAvatar(File imageFile);
}
