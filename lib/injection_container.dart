import 'package:get_it/get_it.dart';

import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/category_remote_datasource.dart';
import 'data/datasources/product_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/product_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/product_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/product/product_bloc.dart';
import 'presentation/blocs/cart/cart_bloc.dart';

/// Service Locator — registrasi semua dependency menggunakan GetIt.
final sl = GetIt.instance;

/// Inisialisasi semua dependency. Dipanggil sekali di `main.dart`.
Future<void> initDependencies() async {
  // ─── Datasources ───
  sl.registerLazySingleton<AuthRemoteDatasource>(() => AuthRemoteDatasource());
  sl.registerLazySingleton<ProductRemoteDatasource>(() => ProductRemoteDatasource());
  sl.registerLazySingleton<CategoryRemoteDatasource>(() => CategoryRemoteDatasource());

  // ─── Repositories ───
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDatasource: sl<AuthRemoteDatasource>()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDatasource: sl<ProductRemoteDatasource>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(
      remoteDatasource: sl<CategoryRemoteDatasource>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  // ─── BLoCs ───
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<ProductBloc>(
    () => ProductBloc(productRepository: sl<ProductRepository>()),
  );
  sl.registerFactory<CartBloc>(
    () => CartBloc(productRepository: sl<ProductRepository>()),
  );
}
