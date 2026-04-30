import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/category_model.dart';

/// Datasource untuk operasi CRUD kategori di Firestore.
class CategoryRemoteDatasource {
  final FirebaseFirestore _firestore;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  CategoryRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection(AppConstants.categoriesCollection);

  /// Ambil semua kategori milik user tertentu.
  Future<List<CategoryModel>> getCategories(String ownerId) async {
    try {
      final snapshot = await _categoriesRef
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      _logger.e('Error mengambil kategori', error: e, stackTrace: stackTrace);
      throw const ServerException('Gagal mengambil data kategori');
    }
  }

  /// Tambah kategori baru.
  Future<CategoryModel> addCategory(CategoryModel category) async {
    try {
      final docRef = await _categoriesRef.add(category.toFirestoreNew());
      _logger.i('Kategori berhasil ditambahkan: ${category.name}');
      final doc = await docRef.get();
      return CategoryModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      _logger.e('Error menambah kategori', error: e, stackTrace: stackTrace);
      throw const ServerException('Gagal menambah kategori');
    }
  }

  /// Hapus kategori.
  Future<void> deleteCategory(String id) async {
    try {
      await _categoriesRef.doc(id).delete();
      _logger.i('Kategori berhasil dihapus: $id');
    } catch (e, stackTrace) {
      _logger.e('Error menghapus kategori', error: e, stackTrace: stackTrace);
      throw const ServerException('Gagal menghapus kategori');
    }
  }

  /// Update kategori.
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _categoriesRef.doc(category.id).update(category.toFirestoreUpdate());
      _logger.i('Kategori berhasil diperbarui: ${category.name}');
    } catch (e, stackTrace) {
      _logger.e('Error memperbarui kategori', error: e, stackTrace: stackTrace);
      throw const ServerException('Gagal memperbarui kategori');
    }
  }
}
