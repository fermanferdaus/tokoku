import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';

/// Model data user untuk serialisasi dari/ke Firestore.
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    super.photoUrl,
    super.createdAt,
    super.lastLoginAt,
  });

  /// Konversi dari Firestore document snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Konversi dari Firebase Auth User dan Google Sign-In data.
  factory UserModel.fromFirebaseUser({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
  }

  /// Data lengkap untuk user baru (termasuk createdAt).
  Map<String, dynamic> toFirestoreNewUser() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
  }

  /// Konversi ke UserEntity.
  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }
}
