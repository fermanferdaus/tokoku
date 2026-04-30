/// Base class untuk semua custom exceptions.
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException($code): $message';
}

/// Exception saat proses autentikasi gagal.
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Exception saat komunikasi dengan Firebase gagal.
class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

/// Exception saat operasi penyimpanan lokal gagal.
class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}
