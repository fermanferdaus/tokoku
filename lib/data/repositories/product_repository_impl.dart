import 'dart:typed_data';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../models/product_model.dart';

/// Implementasi [ProductRepository] yang menghubungkan datasource ke domain.
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDatasource _remoteDatasource;
  final TransactionRemoteDatasource _transactionRemoteDatasource;
  final AuthRepository _authRepository;

  ProductRepositoryImpl({
    required ProductRemoteDatasource remoteDatasource,
    required TransactionRemoteDatasource transactionRemoteDatasource,
    required AuthRepository authRepository,
  })  : _remoteDatasource = remoteDatasource,
        _transactionRemoteDatasource = transactionRemoteDatasource,
        _authRepository = authRepository;

  String get _currentUserId => _authRepository.currentUser.uid;

  AuthRepository get authRepository => _authRepository;

  @override
  Future<List<ProductEntity>> getProducts() async {
    try {
      final models = await _remoteDatasource.getProducts();
      return models.map((m) => m.toEntity()).toList();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<ProductEntity> getProductById(String id) async {
    try {
      final model = await _remoteDatasource.getProductById(id);
      return model.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<void> addProduct(ProductEntity product) async {
    try {
      final model = ProductModel.fromEntity(product);
      await _remoteDatasource.addProduct(model);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<void> updateProduct(ProductEntity product) async {
    try {
      final model = ProductModel.fromEntity(product);
      await _remoteDatasource.updateProduct(model);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _remoteDatasource.deleteProduct(id);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<List<ProductEntity>> searchProducts(String query) async {
    try {
      final models = await _remoteDatasource.searchProducts(query);
      return models.map((m) => m.toEntity()).toList();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<String> uploadProductImage(Uint8List imageBytes, String fileName) async {
    try {
      return await _remoteDatasource.uploadProductImage(imageBytes, fileName, _currentUserId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      await _remoteDatasource.deleteProductImage(imageUrl);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<void> createTransaction({
    required String invoiceNo,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double total,
    required double cash,
    required double change,
    required String paymentMethod,
  }) async {
    try {
      await _remoteDatasource.processTransaction(
        ownerId: _currentUserId,
        invoiceNo: invoiceNo,
        items: items,
        subtotal: subtotal,
        total: total,
        cash: cash,
        change: change,
        paymentMethod: paymentMethod,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      return await _remoteDatasource.getDashboardStats();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _transactionRemoteDatasource.getTransactions(
        startDate: startDate,
        endDate: endDate,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }

  @override
  Future<Map<String, dynamic>> getReportData({
    required String ownerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _remoteDatasource.getReportData(
        ownerId: ownerId,
        startDate: startDate,
        endDate: endDate,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}
