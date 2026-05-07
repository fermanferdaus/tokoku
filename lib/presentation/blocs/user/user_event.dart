import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/user_entity.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class UserFetchRequested extends UserEvent {}

class UserAddRequested extends UserEvent {
  final String name;
  final String email;
  final String password;

  const UserAddRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class UserUpdateRequested extends UserEvent {
  final UserEntity user;
  final String? password;
  final Uint8List? imageBytes;
  final String? imageName;
  final String? originalImageUrl;

  const UserUpdateRequested(
    this.user, {
    this.password,
    this.imageBytes,
    this.imageName,
    this.originalImageUrl,
  });

  @override
  List<Object?> get props => [user, password, imageBytes, imageName, originalImageUrl];
}

class UserDeleteRequested extends UserEvent {
  final String uid;

  const UserDeleteRequested(this.uid);

  @override
  List<Object?> get props => [uid];
}
