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
  Future<List<ProductModel>> getProducts(String ownerId) async {
    try {
      final snapshot = await _productsRef
          .where('ownerId', isEqualTo: ownerId)
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
      batch.set(transactionRef, {
        'id': transactionRef.id,
        'ownerId': ownerId,
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
  Future<List<ProductModel>> searchProducts(String query, String ownerId) async {
    try {
      final snapshot = await _productsRef
          .where('ownerId', isEqualTo: ownerId)
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
  Future<String> uploadProductImage(File imageFile, String ownerId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = _storage.ref().child(AppConstants.productImagesPath).child(ownerId).child(fileName);

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
}
