import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import '../../firebase_options.dart';

/// Wrapper untuk inisialisasi dan konfigurasi Firebase.
class FirebaseConfig {
  FirebaseConfig._();

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  /// Inisialisasi Firebase. Dipanggil sekali di `main.dart`.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _logger.i('Firebase berhasil diinisialisasi');
    } catch (e, stackTrace) {
      _logger.e('Gagal menginisialisasi Firebase', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
