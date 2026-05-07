import 'package:get_it/get_it.dart';

import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/category_remote_datasource.dart';
import 'data/datasources/product_remote_datasource.dart';
import 'data/datasources/transaction_remote_datasource.dart';
import 'data/datasources/settings_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/product_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/product_repository.dart';
import 'domain/repositories/settings_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/product/product_bloc.dart';
import 'presentation/blocs/cart/cart_bloc.dart';
import 'presentation/blocs/user/user_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/history/history_bloc.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/report/report_bloc.dart';

/// Service Locator — registrasi semua dependency menggunakan GetIt.
final sl = GetIt.instance;

/// Inisialisasi semua dependency. Dipanggil sekali di `main.dart`.
Future<void> initDependencies() async {
  // ─── Datasources ───
  sl.registerLazySingleton<AuthRemoteDatasource>(() => AuthRemoteDatasource());
  sl.registerLazySingleton<ProductRemoteDatasource>(
      () => ProductRemoteDatasource());
  sl.registerLazySingleton<TransactionRemoteDatasource>(
      () => TransactionRemoteDatasource());
  sl.registerLazySingleton<CategoryRemoteDatasource>(
      () => CategoryRemoteDatasource());
  sl.registerLazySingleton<SettingsRemoteDatasource>(
      () => SettingsRemoteDatasource());

  // ─── Repositories ───
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDatasource: sl<AuthRemoteDatasource>()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () =>
        SettingsRepositoryImpl(remoteDatasource: sl<SettingsRemoteDatasource>()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDatasource: sl<ProductRemoteDatasource>(),
      transactionRemoteDatasource: sl<TransactionRemoteDatasource>(),
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
    () => AuthBloc(
      authRepository: sl<AuthRepository>(),
      settingsRepository: sl<SettingsRepository>(),
    ),
  );
  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(productRepository: sl<ProductRepository>()),
  );
  sl.registerFactory<ProductBloc>(
    () => ProductBloc(
      productRepository: sl<ProductRepository>(),
      dashboardBloc: sl<DashboardBloc>(),
    ),
  );
  sl.registerFactory<CartBloc>(
    () => CartBloc(productRepository: sl<ProductRepository>()),
  );
  sl.registerLazySingleton<UserBloc>(
    () => UserBloc(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<HistoryBloc>(
    () => HistoryBloc(productRepository: sl<ProductRepository>()),
  );
  sl.registerFactory<SettingsBloc>(
    () => SettingsBloc(settingsRepository: sl<SettingsRepository>()),
  );
  sl.registerFactory<ReportBloc>(
    () => ReportBloc(
      productRepository: sl<ProductRepository>(),
      authRepository: sl<AuthRepository>(),
    ),
  );
}
