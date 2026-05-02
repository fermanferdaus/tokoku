import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDatasource _remoteDatasource;

  SettingsRepositoryImpl({required SettingsRemoteDatasource remoteDatasource})
      : _remoteDatasource = remoteDatasource;

  @override
  Future<String> getAdminAccessCode() {
    return _remoteDatasource.getAdminAccessCode();
  }

  @override
  Future<void> updateAdminAccessCode(String newCode) {
    return _remoteDatasource.updateAdminAccessCode(newCode);
  }
}
