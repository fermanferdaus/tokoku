import 'package:equatable/equatable.dart';

/// Base class untuk semua failure dalam aplikasi.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Failure yang terjadi pada proses autentikasi.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Failure yang terjadi saat komunikasi dengan server/Firebase.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Failure yang terjadi pada operasi penyimpanan lokal.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure yang tidak terduga.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Terjadi kesalahan yang tidak terduga.']);
}
