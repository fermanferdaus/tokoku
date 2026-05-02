import 'package:equatable/equatable.dart';

/// Representasi data user dalam domain layer.
class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = 'kasir',
    this.photoUrl,
    this.createdAt,
    this.lastLoginAt,
  });

  /// Empty user untuk representasi state belum login.
  static const empty =
      UserEntity(uid: '', email: '', displayName: '', role: '');

  bool get isEmpty => this == empty;
  bool get isNotEmpty => !isEmpty;

  @override
  List<Object?> get props =>
      [uid, email, displayName, role, photoUrl, createdAt, lastLoginAt];
}
