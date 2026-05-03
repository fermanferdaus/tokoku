import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/product_model.dart';

/// Datasource untuk operasi CRUD produk di Firestore.
class ProductRemoteDatasource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  ProductRemoteDatasource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection(AppConstants.productsCollection);

  /// Ambil semua produk milik user tertentu.
  Future<List<ProductModel>> getProducts() async {
    try {
      final snapshot = await _productsRef
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      _logger.e('Error mengambil produk', error: e, stackTrace: stackTrace);
      throw const ServerException('Gagal mengambil data produk');
    }
  }

  /// Ambil detail produk berdasarkan ID.
  Future<ProductModel> getProductById(String id) async {
    try {
      final doc = await _productsRef.doc(id).get();
      if (!doc.exists) {
        throw const ServerException('Produk tidak ditemukan');
      }
      return ProductModel.fromFirestore(doc);
    } catch (e) {
      if (e is ServerException) rethrow;
      _logger.e('Error mengambil detail produk', error: e);
      throw const ServerException('Gagal mengambil detail produk');
    }
  }

  /// Tambah produk baru ke Firestore.
  Future<void> addProduct(ProductModel product) async {
    try {
      await _productsRef.add(product.toFirestoreNew());
      _logger.i('Produk berhasil ditambahkan: ${product.name}');
    } catch (e, stackTrace) {
      _logger.e('Error menambah produk', error: e, stackTrace: stackTrace);
      throw const ServerException('Gagal menambah produk');
    }
  }

  /// Update data produk di Firestore.
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _productsRef.doc(product.id).update(product.toFirestore());
      _logger.i('Produk berhasil diupdate: ${product.name}');
    } catch (e, stackTrace) {
      _logger.e('Error mengupdate produk', error: e, stackTrace: stackTrace);
      throw const ServerException('Gagal mengupdate produk');
    }
  }

  /// Memproses transaksi: update stok produk secara massal dan simpan data transaksi.
  Future<void> processTransaction({
    required String ownerId,
    required String invoiceNo,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double total,
    required double cash,
    required double change,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Update stok untuk setiap produk
      for (final item in items) {
        final productId = item['productId'] as String;
        final quantity = item['quantity'] as int;
        
        final docRef = _productsRef.doc(productId);
        batch.update(docRef, {
          'stock': FieldValue.increment(-quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // 2. Simpan data transaksi ke koleksi 'transactions'
      final transactionRef = _firestore.collection(AppConstants.transactionsCollection).doc();
      final cashierName = items.isNotEmpty ? (items.first['userName'] ?? 'Kasir') : 'Kasir';
      
      batch.set(transactionRef, {
        'id': transactionRef.id,
        'ownerId': ownerId,
        'userName': cashierName,
        'invoiceNo': invoiceNo,
        'items': items,
        'subtotal': subtotal,
        'total': total,
        'cash': cash,
        'change': change,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      _logger.i('Transaksi $invoiceNo berhasil diproses');
    } catch (e, stackTrace) {
      _logger.e('Error memproses transaksi', error: e, stackTrace: stackTrace);
      throw const ServerException('Gagal memproses transaksi ke database');
    }
  }

  /// Hard delete produk dari Firestore.
  Future<void> deleteProduct(String id) async {
    try {
      await _productsRef.doc(id).delete();
      _logger.i('Produk berhasil dihapus (hard delete): $id');
    } catch (e, stackTrace) {
      _logger.e('Error menghapus produk', error: e, stackTrace: stackTrace);
      throw const ServerException('Gagal menghapus produk');
    }
  }

  /// Cari produk berdasarkan nama (client-side filtering).
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final snapshot = await _productsRef
          .where('isActive', isEqualTo: true)
          .get();

      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((product) =>
              product.name.toLowerCase().contains(lowerQuery) ||
              (product.sku?.toLowerCase().contains(lowerQuery) ?? false))
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error mencari produk', error: e, stackTrace: stackTrace);
      throw const ServerException('Gagal mencari produk');
    }
  }

  /// Upload gambar produk ke Firebase Storage dan kembalikan URL-nya.
  Future<String> uploadProductImage(File imageFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = _storage.ref().child(AppConstants.productImagesPath).child(userId).child(fileName);

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      _logger.i('Gambar produk berhasil diupload: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      _logger.e('Error mengupload gambar', error: e, stackTrace: stackTrace);
      throw const ServerException('Gagal mengupload gambar produk');
    }
  }

  /// Hapus gambar produk dari Firebase Storage.
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      _logger.i('Gambar produk berhasil dihapus');
    } catch (e) {
      _logger.w('Gagal menghapus gambar produk: $e');
    }
  }

  /// Ambil statistik untuk dashboard admin.
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(const Duration(days: 6));

      // 1. Total Produk
      final productsQuery =
          await _productsRef.get();
      final totalProducts = productsQuery.docs.length;

      // 2. Stok Menipis (Threshold < 5)
      final lowStockProducts = productsQuery.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((p) => p.stock < 5)
          .toList();

      // 3. Transaksi Hari Ini
      final transactionsRef = _firestore.collection(AppConstants.transactionsCollection);
      final todayTransactionsQuery = await transactionsRef
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();

      double todayRevenue = 0;
      for (final doc in todayTransactionsQuery.docs) {
        todayRevenue += (doc.data()['total'] ?? 0).toDouble();
      }

      // 4. Perbandingan Pendapatan (Kemarin vs Hari Ini)
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));
      final yesterdayTransactionsQuery = await transactionsRef
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(yesterdayStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(todayStart))
          .get();

      double yesterdayRevenue = 0;
      for (final doc in yesterdayTransactionsQuery.docs) {
        yesterdayRevenue += (doc.data()['total'] ?? 0).toDouble();
      }

      double revenueChange = 0;
      if (yesterdayRevenue > 0) {
        revenueChange = ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
      } else if (todayRevenue > 0) {
        revenueChange = 100;
      }

      // 5. Total Seluruh Transaksi
      final allTransactionsQuery =
          await transactionsRef.get();
      final totalTransactions = allTransactionsQuery.docs.length;

      // 6. Tren Penjualan 7 Hari Terakhir
      final weekTransactionsQuery = await transactionsRef
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .orderBy('createdAt', descending: false)
          .get();

      final Map<String, double> dailyTrend = {};
      // Inisialisasi 7 hari dengan 0
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final label = _getDayLabel(date.weekday);
        dailyTrend[label] = 0;
      }

      for (final doc in weekTransactionsQuery.docs) {
        final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null) {
          final label = _getDayLabel(createdAt.weekday);
          dailyTrend[label] = (dailyTrend[label] ?? 0) + (doc.data()['total'] ?? 0).toDouble();
        }
      }

      return {
        'totalProducts': totalProducts,
        'lowStockCount': lowStockProducts.length,
        'lowStockProducts': lowStockProducts.map((p) => p.toEntity()).toList(),
        'todayRevenue': todayRevenue,
        'todayTransactions': todayTransactionsQuery.docs.length,
        'revenueChange': revenueChange,
        'totalTransactions': totalTransactions,
        'salesTrend': dailyTrend,
      };
    } catch (e, stackTrace) {
      _logger.e('Error mengambil dashboard stats', error: e, stackTrace: stackTrace);
      throw const ServerException('Gagal mengambil statistik dashboard');
    }
  }

  String _getDayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Sen';
      case DateTime.tuesday: return 'Sel';
      case DateTime.wednesday: return 'Rab';
      case DateTime.thursday: return 'Kam';
      case DateTime.friday: return 'Jum';
      case DateTime.saturday: return 'Sab';
      case DateTime.sunday: return 'Ming';
      default: return '';
    }
  }
}
