import 'package:equatable/equatable.dart';

/// Events untuk AuthBloc.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Mulai mendengarkan perubahan status autentikasi.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User menekan tombol "Sign in with Google".
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// User menekan tombol login email.
class AuthEmailSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthEmailSignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// User menekan tombol register email.
class AuthEmailSignUpRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const AuthEmailSignUpRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

/// User menekan tombol logout.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
