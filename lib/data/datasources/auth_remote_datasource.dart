import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Datasource untuk operasi autentikasi menggunakan Firebase Auth + Google Sign-In.
class AuthRemoteDatasource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  AuthRemoteDatasource({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
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

  /// Login dengan Google OAuth.
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Login dibatalkan oleh pengguna', code: 'cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw const AuthException('Gagal mendapatkan data user dari Firebase');
      }

      final userModel = UserModel.fromFirebaseUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL,
      );

      await _saveUserToFirestore(userModel, userCredential.additionalUserInfo?.isNewUser ?? false);

      _logger.i('User berhasil login: ${userModel.email}');
      return userModel;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth Error', error: e);
      throw AuthException('Gagal login: ${e.message}', code: e.code);
    } catch (e, stackTrace) {
      _logger.e('Unexpected Auth Error', error: e, stackTrace: stackTrace);
      throw const AuthException('Terjadi kesalahan saat login');
    }
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
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthException('Gagal membuat akun');
      }

      // Update display name di Firebase Auth
      await firebaseUser.updateDisplayName(name);

      final userModel = UserModel.fromFirebaseUser(
        uid: firebaseUser.uid,
        email: email,
        displayName: name,
      );

      // Simpan ke Firestore
      await _saveUserToFirestore(userModel, true);

      return userModel;
    } on FirebaseAuthException catch (e) {
      String message = 'Gagal mendaftar';
      if (e.code == 'email-already-in-use') message = 'Email sudah digunakan';
      if (e.code == 'weak-password') message = 'Password terlalu lemah';
      throw AuthException(message, code: e.code);
    } catch (e) {
      throw const AuthException('Terjadi kesalahan saat pendaftaran');
    }
  }

  /// Logout dari Firebase dan Google Sign-In.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      _logger.i('User berhasil logout');
    } catch (e, stackTrace) {
      _logger.e('Logout Error', error: e, stackTrace: stackTrace);
      throw const AuthException('Gagal logout');
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
