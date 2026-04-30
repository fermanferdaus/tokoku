import 'dart:io';

import '../entities/product_entity.dart';

/// Kontrak repository untuk operasi CRUD produk.
abstract class ProductRepository {
  /// Ambil semua produk milik user yang sedang login.
  Future<List<ProductEntity>> getProducts();

  /// Ambil detail produk berdasarkan ID.
  Future<ProductEntity> getProductById(String id);

  /// Tambah produk baru.
  Future<void> addProduct(ProductEntity product);

  /// Update data produk.
  Future<void> updateProduct(ProductEntity product);

  /// Hapus produk berdasarkan ID.
  Future<void> deleteProduct(String id);

  /// Cari produk berdasarkan nama atau SKU.
  Future<List<ProductEntity>> searchProducts(String query);

  /// Upload gambar produk dan kembalikan URL-nya.
  Future<String> uploadProductImage(File imageFile);

  /// Hapus gambar produk dari storage.
  Future<void> deleteProductImage(String imageUrl);
}
