import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tokoku/domain/entities/user_entity.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final AuthRepository _authRepository;

  UserBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(UserInitial()) {
    on<UserFetchRequested>(_onFetchRequested);
    on<UserAddRequested>(_onAddRequested);
    on<UserUpdateRequested>(_onUpdateRequested);
    on<UserDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onFetchRequested(
    UserFetchRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final users = await _authRepository.getUsers();
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onAddRequested(
    UserAddRequested event,
    Emitter<UserState> emit,
  ) async {
    final currentState = state;
    List<UserEntity> currentUsers = [];
    if (currentState is UserLoaded) {
      currentUsers = currentState.users;
    }

    emit(UserLoading());
    try {
      // Pre-validation: Cek apakah email sudah ada
      final allUsers = await _authRepository.getUsers();
      final isEmailUsed = allUsers.any((u) => u.email.toLowerCase() == event.email.toLowerCase());
      
      if (isEmailUsed) {
        emit(const UserError('Email sudah digunakan oleh akun lain.'));
        if (currentUsers.isNotEmpty) emit(UserLoaded(currentUsers));
        return;
      }

      await _authRepository.signUpWithEmail(
        name: event.name,
        email: event.email,
        password: event.password,
        role: 'kasir', // Default role untuk pendaftaran dari panel admin
      );
      
      // Ambil data terbaru segera
      final updatedUsers = await _authRepository.getUsers();
      emit(UserLoaded(updatedUsers));
      // Kita tidak lagi emit UserOperationSuccess di sini agar state terakhir tetap UserLoaded
      // Notifikasi sukses bisa dilakukan via listener di UI yang mengecek perubahan data
    } catch (e) {
      emit(UserError(e.toString()));
      final latestUsers = await _authRepository.getUsers();
      emit(UserLoaded(latestUsers));
    }
  }

  Future<void> _onUpdateRequested(
    UserUpdateRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      // Pre-validation: Cek duplikasi email jika email diubah
      final allUsers = await _authRepository.getUsers();
      final isEmailUsed = allUsers.any((u) => 
        u.email.toLowerCase() == event.user.email.toLowerCase() && 
        u.uid != event.user.uid
      );

      if (isEmailUsed) {
        emit(const UserError('Email sudah digunakan oleh akun lain.'));
        final latestUsers = await _authRepository.getUsers();
        emit(UserLoaded(latestUsers));
        return;
      }

      String? photoUrl = event.user.photoUrl;
      
      // Jika ada file gambar baru
      if (event.imageBytes != null) {
        photoUrl = await _authRepository.uploadUserAvatar(
          event.imageBytes!,
          event.imageName ?? 'avatar.jpg',
        );
      }

      final updatedUser = UserEntity(
        uid: event.user.uid,
        email: event.user.email,
        displayName: event.user.displayName,
        role: event.user.role,
        photoUrl: photoUrl,
        createdAt: event.user.createdAt,
        lastLoginAt: event.user.lastLoginAt,
      );

      await _authRepository.updateUser(updatedUser, password: event.password);
      
      // Ambil data terbaru segera
      final updatedUsers = await _authRepository.getUsers();
      emit(UserLoaded(updatedUsers));
    } catch (e) {
      emit(UserError(e.toString()));
      final latestUsers = await _authRepository.getUsers();
      emit(UserLoaded(latestUsers));
    }
  }

  Future<void> _onDeleteRequested(
    UserDeleteRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      await _authRepository.deleteUser(event.uid);
      
      // Ambil data terbaru segera
      final updatedUsers = await _authRepository.getUsers();
      emit(UserLoaded(updatedUsers));
    } catch (e) {
      emit(UserError(e.toString()));
      final latestUsers = await _authRepository.getUsers();
      emit(UserLoaded(latestUsers));
    }
  }
}
