import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product_entity.dart';

/// Model data produk untuk serialisasi dari/ke Firestore.
class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    super.description,
    required super.price,
    super.buyPrice,
    required super.stock,
    super.minStock,
    super.sku,
    super.category,
    super.imageUrl,
    required super.ownerId,
    super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  /// Konversi dari Firestore document snapshot.
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      price: (data['price'] ?? 0).toDouble(),
      buyPrice: (data['buyPrice'] ?? 0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(),
      minStock: (data['minStock'] ?? 0).toInt(),
      sku: data['sku'],
      category: data['category'],
      imageUrl: data['imageUrl'],
      ownerId: data['ownerId'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'buyPrice': buyPrice,
      'stock': stock,
      'minStock': minStock,
      'sku': sku,
      'category': category,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Data lengkap untuk produk baru (termasuk createdAt).
  Map<String, dynamic> toFirestoreNew() {
    return {
      ...toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Konversi dari ProductEntity.
  factory ProductModel.fromEntity(ProductEntity entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      price: entity.price,
      buyPrice: entity.buyPrice,
      stock: entity.stock,
      minStock: entity.minStock,
      sku: entity.sku,
      category: entity.category,
      imageUrl: entity.imageUrl,
      ownerId: entity.ownerId,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Konversi ke ProductEntity.
  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      name: name,
      description: description,
      price: price,
      buyPrice: buyPrice,
      stock: stock,
      minStock: minStock,
      sku: sku,
      category: category,
      imageUrl: imageUrl,
      ownerId: ownerId,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
