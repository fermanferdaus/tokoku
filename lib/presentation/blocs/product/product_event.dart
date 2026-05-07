import 'dart:typed_data';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/product_entity.dart';

/// Events untuk ProductBloc.
abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

/// Muat semua produk.
class ProductLoadRequested extends ProductEvent {
  const ProductLoadRequested();
}

/// Cari produk berdasarkan query.
class ProductSearchRequested extends ProductEvent {
  final String query;
  const ProductSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

/// Tambah produk baru.
class ProductAddRequested extends ProductEvent {
  final ProductEntity product;
  final Uint8List? imageBytes;
  final String? imageName;

  const ProductAddRequested({required this.product, this.imageBytes, this.imageName});

  @override
  List<Object?> get props => [product, imageBytes, imageName];
}

/// Update produk.
class ProductUpdateRequested extends ProductEvent {
  final ProductEntity product;
  final Uint8List? imageBytes;
  final String? imageName;
  final String? originalImageUrl;

  const ProductUpdateRequested({
    required this.product,
    this.imageBytes,
    this.imageName,
    this.originalImageUrl,
  });

  @override
  List<Object?> get props => [product, imageBytes, imageName, originalImageUrl];
}

/// Hapus produk (soft delete).
class ProductDeleteRequested extends ProductEvent {
  final String productId;
  final String? imageUrl;
  const ProductDeleteRequested(this.productId, {this.imageUrl});

  @override
  List<Object?> get props => [productId, imageUrl];
}
