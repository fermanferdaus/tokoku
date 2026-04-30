import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC untuk mengelola state autentikasi aplikasi.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  StreamSubscription<UserEntity>? _authSubscription;
  bool _isRegistering = false;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthEmailSignInRequested>(_onEmailSignInRequested);
    on<AuthEmailSignUpRequested>(_onEmailSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<_AuthUserChanged>(_onUserChanged);
  }

  /// Listen ke Firebase auth state changes.
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    await _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges.listen(
      (user) {
        // Abaikan perubahan jika sedang dalam proses pendaftaran manual
        if (_isRegistering) return;

        if (user.isNotEmpty) {
          add(const _AuthUserChanged(isAuthenticated: true));
        } else {
          add(const _AuthUserChanged(isAuthenticated: false));
        }
      },
      onError: (error) {
        _logger.e('Auth stream error', error: error);
      },
    );

    // Check current user state secara langsung
    final currentUser = _authRepository.currentUser;
    if (currentUser.isNotEmpty) {
      emit(AuthAuthenticated(currentUser));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Proses Google Sign-In.
  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      emit(AuthAuthenticated(user));
      _logger.i('Login berhasil: ${user.displayName}');
    } on AuthFailure catch (e) {
      _logger.w('Login gagal: ${e.message}');
      // Jika user cancel, kembali ke unauthenticated tanpa error
      if (e.message.contains('dibatalkan')) {
        emit(const AuthUnauthenticated());
      } else {
        emit(AuthError(e.message));
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      _logger.e('Unexpected login error', error: e);
      emit(const AuthError('Terjadi kesalahan saat login'));
      emit(const AuthUnauthenticated());
    }
  }

  /// Proses Email Sign-In.
  Future<void> _onEmailSignInRequested(
    AuthEmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.signInWithEmail(event.email, event.password);
      emit(AuthAuthenticated(user));
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
      emit(const AuthUnauthenticated());
    }
  }

  /// Proses Email Sign-Up.
  Future<void> _onEmailSignUpRequested(
    AuthEmailSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    _isRegistering = true; // Set flag pendaftaran
    try {
      await _authRepository.signUpWithEmail(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      
      // Paksa sign out agar tidak langsung masuk dashboard
      await _authRepository.signOut();
      
      _isRegistering = false;
      emit(const AuthRegistrationSuccess());
      emit(const AuthUnauthenticated());
    } on AuthFailure catch (e) {
      _isRegistering = false;
      emit(AuthError(e.message));
      emit(const AuthUnauthenticated());
    }
  }

  /// Handler perubahan user dari stream.
  void _onUserChanged(
    _AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.isAuthenticated) {
      final user = _authRepository.currentUser;
      if (user.isNotEmpty) {
        emit(AuthAuthenticated(user));
      }
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Proses Sign Out.
  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.signOut();
      emit(const AuthUnauthenticated());
      _logger.i('Logout berhasil');
    } on AuthFailure catch (e) {
      _logger.e('Logout gagal: ${e.message}');
      emit(AuthError(e.message));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

/// Event internal untuk perubahan user dari stream.
class _AuthUserChanged extends AuthEvent {
  final bool isAuthenticated;

  const _AuthUserChanged({required this.isAuthenticated});

  @override
  List<Object?> get props => [isAuthenticated];
}
