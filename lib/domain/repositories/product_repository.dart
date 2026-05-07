import 'dart:typed_data';

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
  Future<String> uploadProductImage(Uint8List imageBytes, String fileName);

  /// Hapus gambar produk dari storage.
  Future<void> deleteProductImage(String imageUrl);

  /// Memproses transaksi: potong stok dan simpan data order.
  Future<void> createTransaction({
    required String invoiceNo,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double total,
    required double cash,
    required double change,
    required String paymentMethod,
  });

  /// Mengambil statistik dashboard.
  Future<Map<String, dynamic>> getDashboardStats();

  /// Mengambil riwayat transaksi dengan filter tanggal.
  Future<List<Map<String, dynamic>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Mengambil data laporan lengkap (statistik + tren + produk terlaris).
  Future<Map<String, dynamic>> getReportData({
    required String ownerId,
    DateTime? startDate,
    DateTime? endDate,
  });
}
