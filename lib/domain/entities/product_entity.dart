import 'package:equatable/equatable.dart';

/// Representasi data produk dalam domain layer.
class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double buyPrice;
  final int stock;
  final int minStock;
  final String? sku;
  final String? category;
  final String? imageUrl;
  final String ownerId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.buyPrice = 0,
    required this.stock,
    this.minStock = 0,
    this.sku,
    this.category,
    this.imageUrl,
    required this.ownerId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id, name, description, price, buyPrice, stock, minStock,
        sku, category, imageUrl, ownerId, isActive,
        createdAt, updatedAt,
      ];
}
