import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Datasource untuk operasi autentikasi menggunakan Firebase Auth.
class AuthRemoteDatasource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  AuthRemoteDatasource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream perubahan status autentikasi.
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _getUserFromFirestore(firebaseUser.uid);
    });
  }

  /// User Firebase yang sedang login saat ini.
  UserModel? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    return UserModel.fromFirebaseUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
    );
  }

  /// Login dengan Email & Password.
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException('Gagal mendapatkan data user');
      }

      final userModel = await _getUserFromFirestore(firebaseUser.uid);
      if (userModel == null) {
        throw const AuthException('Data user tidak ditemukan di database');
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan saat login';
      if (e.code == 'user-not-found') message = 'Email tidak terdaftar';
      if (e.code == 'wrong-password') message = 'Password salah';
      throw AuthException(message, code: e.code);
    } catch (e) {
      throw const AuthException('Terjadi kesalahan yang tidak terduga');
    }
  }

  /// Register dengan Email & Password.
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String role = 'kasir',
  }) async {
    // Gunakan Secondary FirebaseApp untuk pendaftaran agar tidak menimpa sesi login saat ini (admin)
    FirebaseApp? secondaryApp;
    try {
      final appName = 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: _firebaseAuth.app.options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException('Gagal membuat akun');
      }

      // Update display name di Firebase Auth (Secondary)
      await firebaseUser.updateDisplayName(name);

      final userModel = UserModel.fromFirebaseUser(
        uid: firebaseUser.uid,
        email: email,
        displayName: name,
        role: role,
      );

      // Simpan ke Firestore (menggunakan default app/firestore)
      await _saveUserToFirestore(userModel, true);

      // Logout secondary auth (tidak perlu dipanggil sebenarnya karena app akan dihapus)
      await secondaryAuth.signOut();

      return userModel;
    } on FirebaseAuthException catch (e) {
      String message = 'Gagal mendaftar';
      if (e.code == 'email-already-in-use') message = 'Email sudah digunakan';
      if (e.code == 'weak-password') message = 'Password terlalu lemah';
      throw AuthException(message, code: e.code);
    } catch (e) {
      _logger.e('Error saat pendaftaran user baru: $e');
      throw const AuthException('Terjadi kesalahan saat pendaftaran');
    } finally {
      // Hapus secondary app dari memory
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  /// Logout dari Firebase.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _logger.i('User berhasil logout');
    } catch (e, stackTrace) {
      _logger.e('Logout Error', error: e, stackTrace: stackTrace);
      throw const AuthException('Gagal logout');
    }
  }

  /// Ambil semua data user dari Firestore.
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      _logger.e('Gagal mengambil semua user: $e');
      throw const AuthException('Gagal mengambil daftar user');
    }
  }

  /// Hapus user dari Firestore.
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).delete();
    } catch (e) {
      _logger.e('Gagal menghapus user: $e');
      throw const AuthException('Gagal menghapus user dari database');
    }
  }

  /// Update data user di Firestore.
  Future<void> updateUser(UserModel user, {String? password}) async {
    try {
      // Update Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update(user.toFirestore());

      // Update Password jika diberikan (Hanya jika user yang sedang login adalah target)
      if (password != null && _firebaseAuth.currentUser?.uid == user.uid) {
        await _firebaseAuth.currentUser?.updatePassword(password);
      }
    } catch (e) {
      _logger.e('Gagal update user: $e');
      throw const AuthException('Gagal memperbarui data user');
    }
  }

  /// Simpan atau update data user di Firestore.
  Future<void> _saveUserToFirestore(UserModel user, bool isNewUser) async {
    final docRef = _firestore.collection(AppConstants.usersCollection).doc(user.uid);

    if (isNewUser) {
      await docRef.set(user.toFirestoreNewUser());
    } else {
      await docRef.update(user.toFirestore());
    }
  }

  /// Ambil data user dari Firestore.
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      _logger.w('Gagal mengambil data user dari Firestore: $e');
      return null;
    }
  }
}
