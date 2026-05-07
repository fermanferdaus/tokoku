import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import 'app.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/firebase/firebase_config.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale data untuk formatting tanggal
  await initializeDateFormatting('id_ID', null);

  // Lock orientasi ke portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final logger = Logger(printer: PrettyPrinter(methodCount: 0));

  try {
    // Inisialisasi Firebase
    await FirebaseConfig.initialize();

    // Inisialisasi Dependency Injection
    await initDependencies();

    logger.i('Aplikasi Tokoku siap dijalankan');
  } catch (e, stackTrace) {
    logger.f('Gagal menginisialisasi aplikasi', error: e, stackTrace: stackTrace);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Gagal memuat aplikasi.\n$e',
                textAlign: TextAlign.center),
          ),
        ),
      ),
    );
    return;
  }

  runApp(const App());
}
