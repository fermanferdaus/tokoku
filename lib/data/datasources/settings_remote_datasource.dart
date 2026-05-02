import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

class SettingsRemoteDatasource {
  final FirebaseFirestore _firestore;

  SettingsRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Mengambil kode akses admin. Jika belum ada, buat dengan default.
  Future<String> getAdminAccessCode() async {
    try {
      final doc = await _firestore
          .collection(AppConstants.settingsCollection)
          .doc(AppConstants.adminAccessCodeDoc)
          .get();

      if (!doc.exists) {
        // Inisialisasi jika belum ada
        const defaultCode = 'ADMIN123';
        await _firestore
            .collection(AppConstants.settingsCollection)
            .doc(AppConstants.adminAccessCodeDoc)
            .set({'code': defaultCode});
        return defaultCode;
      }

      return doc.data()?['code'] ?? 'ADMIN123';
    } catch (e) {
      throw const AuthException('Gagal mengambil kode akses admin');
    }
  }

  /// Memperbarui kode akses admin.
  Future<void> updateAdminAccessCode(String newCode) async {
    try {
      await _firestore
          .collection(AppConstants.settingsCollection)
          .doc(AppConstants.adminAccessCodeDoc)
          .set({'code': newCode});
    } catch (e) {
      throw const AuthException('Gagal memperbarui kode akses admin');
    }
  }
}
