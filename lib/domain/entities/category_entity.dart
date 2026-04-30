import 'package:equatable/equatable.dart';

/// Representasi data kategori produk.
class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final DateTime? createdAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, ownerId, createdAt];
}
