import 'dart:io';

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
  final File? imageFile;

  const ProductAddRequested({required this.product, this.imageFile});

  @override
  List<Object?> get props => [product, imageFile];
}

/// Update produk.
class ProductUpdateRequested extends ProductEvent {
  final ProductEntity product;
  final File? imageFile;
  final String? originalImageUrl;

  const ProductUpdateRequested({
    required this.product,
    this.imageFile,
    this.originalImageUrl,
  });

  @override
  List<Object?> get props => [product, imageFile, originalImageUrl];
}

/// Hapus produk (soft delete).
class ProductDeleteRequested extends ProductEvent {
  final String productId;
  final String? imageUrl;
  const ProductDeleteRequested(this.productId, {this.imageUrl});

  @override
  List<Object?> get props => [productId, imageUrl];
}
