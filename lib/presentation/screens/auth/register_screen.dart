import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/loading_overlay.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthEmailSignUpRequested(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 64),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Berhasil!', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AppButton(
              text: 'Masuk Sekarang',
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                context.go('/login'); // Ke halaman login
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is AuthRegistrationSuccess) {
          _showSuccessDialog(context, state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return LoadingOverlay(
            isLoading: isLoading,
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AppLogo(size: 72, iconSize: 40, borderRadius: 18)),
                        const SizedBox(height: 24),
                        Text(
                          'Buat Akun Baru',
                          style: AppTextStyles.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Silakan lengkapi data di bawah ini',
                          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Full Name
                        Text('Nama Lengkap', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Masukkan nama lengkap',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (v) => Validators.validateRequired(v, 'Nama Lengkap'),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        Text('Email', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'contoh@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        Text('Password', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        Text('Konfirmasi Password', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                            ),
                          ),
                          validator: (v) => Validators.validateConfirmPassword(v, _passwordController.text),
                        ),
                        const SizedBox(height: 32),

                        AppButton(
                          text: 'Daftar Sekarang',
                          onPressed: isLoading ? null : _onRegister,
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Text(
                                'Masuk di sini',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
