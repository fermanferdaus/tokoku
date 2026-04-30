import 'package:equatable/equatable.dart';

import '../../../domain/entities/product_entity.dart';

/// States untuk ProductBloc.
abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

/// State awal.
class ProductInitial extends ProductState {
  const ProductInitial();
}

/// Sedang memuat data produk.
class ProductLoading extends ProductState {
  const ProductLoading();
}

/// Produk berhasil dimuat.
class ProductLoaded extends ProductState {
  final List<ProductEntity> products;

  const ProductLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

/// Operasi CRUD berhasil.
class ProductOperationSuccess extends ProductState {
  final String message;

  const ProductOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Terjadi error.
class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
