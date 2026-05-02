import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tokoku/core/utils/validators.dart';
import 'package:tokoku/presentation/blocs/user/user_bloc.dart';
import 'package:tokoku/presentation/blocs/user/user_event.dart';
import 'package:tokoku/presentation/blocs/user/user_state.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/user_entity.dart';
import '../../widgets/common/app_button.dart';

class UserFormScreen extends StatefulWidget {
  final UserEntity? user;

  const UserFormScreen({super.key, this.user});

  bool get isEditing => user != null;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.displayName);
    _emailController = TextEditingController(text: widget.user?.email);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (widget.isEditing) {
        final updatedUser = UserEntity(
          uid: widget.user!.uid,
          email: _emailController.text.trim(),
          displayName: _nameController.text.trim(),
          role: widget.user!.role,
          photoUrl: widget.user!.photoUrl,
          createdAt: widget.user!.createdAt,
          lastLoginAt: widget.user!.lastLoginAt,
        );
        
        final newPassword = _passwordController.text.isNotEmpty 
            ? _passwordController.text 
            : null;
            
        context.read<UserBloc>().add(UserUpdateRequested(
          updatedUser, 
          password: newPassword,
        ));
      } else {
        context.read<UserBloc>().add(UserAddRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UserLoaded) {
          // Hanya pop jika sebelumnya kita sedang loading (artinya baru saja submit)
          // Ini mencegah pop saat pertama kali buka halaman jika state sudah Loaded
          if (ModalRoute.of(context)?.isCurrent ?? false) {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(widget.isEditing 
                  ? 'Data kasir berhasil diperbarui' 
                  : 'Akun kasir berhasil didaftarkan'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop();
          }
        } else if (state is UserError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          final isLoading = state is UserLoading;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                widget.isEditing ? 'Edit Kasir' : 'Daftarkan Kasir',
                style: AppTextStyles.titleLarge,
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionCard(
                      title: 'Data Akun',
                      children: [
                        _buildLabel('Nama Lengkap *'),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Masukkan nama lengkap',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                          ),
                          validator: (v) => Validators.validateRequired(v, 'Nama Lengkap'),
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Email *'),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'email@contoh.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 20),
                          ),
                          validator: Validators.validateEmail,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: widget.isEditing ? 'Ubah Password' : 'Keamanan',
                      children: [
                        if (widget.isEditing)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Kosongkan jika tidak ingin mengubah password.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                            ),
                          ),
                        _buildLabel(widget.isEditing ? 'Password Baru' : 'Password *'),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (v) {
                            if (widget.isEditing && (v == null || v.isEmpty)) {
                              return null; // Boleh kosong saat edit
                            }
                            return Validators.validatePassword(v);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Konfirmasi Password'),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                            ),
                          ),
                          validator: (v) {
                            if (widget.isEditing && _passwordController.text.isEmpty) {
                              return null;
                            }
                            return Validators.validateConfirmPassword(v, _passwordController.text);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      text: widget.isEditing ? 'Simpan Perubahan' : 'Daftarkan Kasir',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _onSubmit,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.labelLarge),
    );
  }
}
