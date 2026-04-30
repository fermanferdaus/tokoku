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
  Future<UserEntity> signInWithGoogle() async {
    try {
      final userModel = await _remoteDatasource.signInWithGoogle();
      return userModel.toEntity();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    try {
      final userModel = await _remoteDatasource.signInWithEmail(email, password);
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
  }) async {
    try {
      final userModel = await _remoteDatasource.signUpWithEmail(
        name: name,
        email: email,
        password: password,
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
}
