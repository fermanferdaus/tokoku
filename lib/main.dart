import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import 'app.dart';
import 'config/firebase/firebase_config.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  }

  runApp(const App());
}
