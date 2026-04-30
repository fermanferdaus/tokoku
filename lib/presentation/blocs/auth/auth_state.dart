import 'package:equatable/equatable.dart';

import '../../../domain/entities/user_entity.dart';

/// States untuk AuthBloc.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum pengecekan autentikasi.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Sedang memproses autentikasi.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User berhasil terautentikasi.
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// User belum atau tidak terautentikasi.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User berhasil mendaftarkan akun (tapi belum login).
class AuthRegistrationSuccess extends AuthState {
  final String message;

  const AuthRegistrationSuccess({this.message = 'Pendaftaran berhasil! Silakan login.'});

  @override
  List<Object?> get props => [message];
}

/// Terjadi error saat proses autentikasi.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
