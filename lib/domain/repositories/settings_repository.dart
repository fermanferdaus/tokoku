/// Kontrak repository untuk manajemen pengaturan aplikasi.
abstract class SettingsRepository {
  /// Mengambil kode akses admin dari database.
  Future<String> getAdminAccessCode();

  /// Memperbarui kode akses admin di database.
  Future<void> updateAdminAccessCode(String newCode);
}
