import 'dart:io';
import 'package:tokoku/data/models/user_model.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementasi [AuthRepository] yang menghubungkan datasource ke domain.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;

  AuthRepositoryImpl({required AuthRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Stream<UserEntity> get authStateChanges {
    return _remoteDatasource.authStateChanges.map(
      (userModel) => userModel?.toEntity() ?? UserEntity.empty,
    );
  }

  @override
  UserEntity get currentUser {
    return _remoteDatasource.currentUser?.toEntity() ?? UserEntity.empty;
  }

  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    try {
      final userModel =
          await _remoteDatasource.signInWithEmail(email, password);
      return userModel.toEntity();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<UserEntity> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String role = 'kasir',
  }) async {
    try {
      final userModel = await _remoteDatasource.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      return userModel.toEntity();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDatasource.signOut();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<List<UserEntity>> getUsers() async {
    try {
      final userModels = await _remoteDatasource.getAllUsers();
      return userModels.map((m) => m.toEntity()).toList();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      await _remoteDatasource.deleteUser(uid);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<void> updateUser(UserEntity user, {String? password}) async {
    try {
      await _remoteDatasource.updateUser(
        UserModel(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          role: user.role,
          photoUrl: user.photoUrl,
          createdAt: user.createdAt,
          lastLoginAt: user.lastLoginAt,
        ),
        password: password,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<String> uploadUserAvatar(File imageFile) async {
    try {
      return await _remoteDatasource.uploadUserAvatar(imageFile);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }
}
