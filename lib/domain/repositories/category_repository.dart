import '../entities/category_entity.dart';

/// Kontrak repository untuk operasi kategori produk.
abstract class CategoryRepository {
  /// Ambil semua kategori milik user yang sedang login.
  Future<List<CategoryEntity>> getCategories();

  /// Tambah kategori baru dan kembalikan entity-nya.
  Future<CategoryEntity> addCategory(String name);

  /// Hapus kategori.
  Future<void> deleteCategory(String id);

  /// Update kategori.
  Future<void> updateCategory(CategoryEntity category);
}
