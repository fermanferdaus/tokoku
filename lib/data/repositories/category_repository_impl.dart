import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';
import '../models/category_model.dart';

/// Implementasi [CategoryRepository].
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDatasource _remoteDatasource;
  final AuthRepository _authRepository;

  CategoryRepositoryImpl({
    required CategoryRemoteDatasource remoteDatasource,
    required AuthRepository authRepository,
  })  : _remoteDatasource = remoteDatasource,
        _authRepository = authRepository;

  String get _currentUserId => _authRepository.currentUser.uid;

  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
      final models = await _remoteDatasource.getCategories(_currentUserId);
      return models.cast<CategoryEntity>();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<CategoryEntity> addCategory(String name) async {
    try {
      final model = CategoryModel(
        id: '',
        name: name,
        ownerId: _currentUserId,
      );
      final result = await _remoteDatasource.addCategory(model);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _remoteDatasource.deleteCategory(id);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    try {
      final model = CategoryModel(
        id: category.id,
        name: category.name,
        ownerId: _currentUserId,
      );
      await _remoteDatasource.updateCategory(model);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}
