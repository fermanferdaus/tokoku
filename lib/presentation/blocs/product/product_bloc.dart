import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/repositories/product_repository.dart';
import 'product_event.dart';
import 'product_state.dart';

/// BLoC untuk mengelola state produk.
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _productRepository;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  ProductBloc({required ProductRepository productRepository})
    : _productRepository = productRepository,
      super(const ProductInitial()) {
    on<ProductLoadRequested>(_onLoadRequested);
    on<ProductSearchRequested>(_onSearchRequested);
    on<ProductAddRequested>(_onAddRequested);
    on<ProductUpdateRequested>(_onUpdateRequested);
    on<ProductDeleteRequested>(_onDeleteRequested);
  }

  /// Muat semua produk.
  Future<void> _onLoadRequested(
    ProductLoadRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      final products = await _productRepository.getProducts();
      emit(ProductLoaded(products));
    } on ServerFailure catch (e) {
      _logger.e('Error loading products', error: e.message);
      emit(ProductError(e.message));
    }
  }

  /// Cari produk.
  Future<void> _onSearchRequested(
    ProductSearchRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      if (event.query.isEmpty) {
        final products = await _productRepository.getProducts();
        emit(ProductLoaded(products));
      } else {
        final products = await _productRepository.searchProducts(event.query);
        emit(ProductLoaded(products));
      }
    } on ServerFailure catch (e) {
      emit(ProductError(e.message));
    }
  }

  /// Tambah produk.
  Future<void> _onAddRequested(
    ProductAddRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      String? imageUrl;
      if (event.imageFile != null) {
        imageUrl = await _productRepository.uploadProductImage(
          event.imageFile!,
        );
      }

      final product = ProductEntity(
        id: event.product.id,
        name: event.product.name,
        description: event.product.description,
        price: event.product.price,
        buyPrice: event.product.buyPrice,
        stock: event.product.stock,
        minStock: event.product.minStock,
        sku: event.product.sku,
        category: event.product.category,
        imageUrl: imageUrl ?? event.product.imageUrl,
        ownerId: event.product.ownerId,
        isActive: event.product.isActive,
      );

      await _productRepository.addProduct(product);
      emit(const ProductOperationSuccess('Produk berhasil ditambahkan'));

      // Reload products
      final products = await _productRepository.getProducts();
      emit(ProductLoaded(products));
    } on ServerFailure catch (e) {
      _logger.e('Error adding product', error: e.message);
      emit(ProductError(e.message));
    }
  }

  /// Update produk.
  Future<void> _onUpdateRequested(
    ProductUpdateRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      String? imageUrl = event.product.imageUrl;

      // Jika ada file gambar baru
      if (event.imageFile != null) {
        // Hapus gambar lama dari Storage jika ada
        if (event.originalImageUrl != null &&
            event.originalImageUrl!.isNotEmpty) {
          await _productRepository.deleteProductImage(event.originalImageUrl!);
        }
        imageUrl = await _productRepository.uploadProductImage(
          event.imageFile!,
        );
      }
      // Jika tidak ada file baru, tapi gambar dihapus (imageUrl di product adalah null)
      else if (event.product.imageUrl == null ||
          event.product.imageUrl!.isEmpty) {
        if (event.originalImageUrl != null &&
            event.originalImageUrl!.isNotEmpty) {
          await _productRepository.deleteProductImage(event.originalImageUrl!);
        }
        imageUrl = null;
      }

      final product = ProductEntity(
        id: event.product.id,
        name: event.product.name,
        description: event.product.description,
        price: event.product.price,
        buyPrice: event.product.buyPrice,
        stock: event.product.stock,
        minStock: event.product.minStock,
        sku: event.product.sku,
        category: event.product.category,
        imageUrl: imageUrl,
        ownerId: event.product.ownerId,
        isActive: event.product.isActive,
      );

      await _productRepository.updateProduct(product);
      emit(const ProductOperationSuccess('Produk berhasil diperbarui'));

      final products = await _productRepository.getProducts();
      emit(ProductLoaded(products));
    } on ServerFailure catch (e) {
      _logger.e('Error updating product', error: e.message);
      emit(ProductError(e.message));
    }
  }

  /// Hapus produk.
  Future<void> _onDeleteRequested(
    ProductDeleteRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(const ProductLoading());
    try {
      // Hapus gambar dari Storage jika ada
      if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
        await _productRepository.deleteProductImage(event.imageUrl!);
      }

      await _productRepository.deleteProduct(event.productId);
      emit(const ProductOperationSuccess('Produk berhasil dihapus'));

      final products = await _productRepository.getProducts();
      emit(ProductLoaded(products));
    } on ServerFailure catch (e) {
      _logger.e('Error deleting product', error: e.message);
      emit(ProductError(e.message));
    }
  }
}
