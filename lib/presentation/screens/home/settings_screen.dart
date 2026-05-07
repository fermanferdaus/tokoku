import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tokoku/core/theme/app_colors.dart';
import 'package:tokoku/core/theme/app_text_styles.dart';
import 'package:tokoku/domain/entities/user_entity.dart';
import 'package:tokoku/presentation/blocs/auth/auth_bloc.dart';
import 'package:tokoku/presentation/blocs/auth/auth_event.dart';
import 'package:tokoku/presentation/blocs/auth/auth_state.dart';
import 'package:tokoku/presentation/blocs/user/user_bloc.dart';
import 'package:tokoku/presentation/blocs/user/user_event.dart';
import 'package:tokoku/presentation/blocs/user/user_state.dart';
import 'package:tokoku/presentation/blocs/settings/settings_bloc.dart';
import 'package:tokoku/presentation/widgets/common/app_button.dart';
import 'package:tokoku/presentation/widgets/common/loading_overlay.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _adminTokenController;

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isAdminTokenVisible = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _nameController = TextEditingController(text: user.displayName);
      _emailController = TextEditingController(text: user.email);
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
    }
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _adminTokenController = TextEditingController();
    
    // Load current admin token
    final settingsState = context.read<SettingsBloc>().state;
    if (settingsState is SettingsLoaded) {
      _adminTokenController.text = settingsState.code;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _adminTokenController.dispose();
    super.dispose();
  }

  void _onUpdateProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;
      
      final user = authState.user;
      final updatedUser = UserEntity(
        uid: user.uid,
        email: _emailController.text.trim(),
        displayName: _nameController.text.trim(),
        role: user.role,
        photoUrl: user.photoUrl,
        createdAt: user.createdAt,
        lastLoginAt: user.lastLoginAt,
      );

      final newPassword = _newPasswordController.text.isNotEmpty
          ? _newPasswordController.text
          : null;

      context.read<UserBloc>().add(
            UserUpdateRequested(
              updatedUser,
              password: newPassword,
              imageBytes: _selectedImageBytes,
              imageName: _selectedImageName,
              originalImageUrl: user.photoUrl,
            ),
          );
    }
  }

  void _onUpdateAdminToken() {
    if (_adminTokenController.text.isNotEmpty) {
      context.read<SettingsBloc>().add(
            SettingsUpdateRequested(_adminTokenController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              // Tidak perlu navigasi manual karena GoRouter sudah menghandle via refreshListenable
            }
          },
        ),
        BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserLoaded) {
              final authState = context.read<AuthBloc>().state;
              if (authState is! AuthAuthenticated) return;
              
              final user = authState.user;
              final updatedUser = state.users.firstWhere(
                (u) => u.uid == user.uid,
                orElse: () => user,
              );
              context.read<AuthBloc>().add(AuthUserUpdated(updatedUser));

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil berhasil diperbarui'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              setState(() {
                _selectedImageBytes = null;
                _selectedImageName = null;
              });
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
        ),
        BlocListener<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is SettingsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is SettingsLoaded) {
              _adminTokenController.text = state.code;
            }
          },
        ),
      ],
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, userState) {
          return BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              final authState = context.watch<AuthBloc>().state;
              final isLoading = userState is UserLoading || 
                               settingsState is SettingsLoading || 
                               authState is AuthLoading;
              
              // Ambil user secara aman (hindari crash saat logout/loading)
              UserEntity? user;
              if (authState is AuthAuthenticated) {
                user = authState.user;
              }

              return LoadingOverlay(
                isLoading: isLoading,
                child: user == null 
                  ? const SizedBox.shrink() // Jika user null (sedang logout), tampilkan kosong/loading saja
                  : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildProfileHeader(user),
                        const SizedBox(height: 24),
                        _buildMenuCard(
                          items: [
                            _buildMenuItem(
                              icon: Icons.person_outline_rounded,
                              title: 'Data Akun',
                              onTap: () => _showAccountInfoDialog(user!),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'PENGATURAN',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          items: [
                            _buildMenuItem(
                              icon: Icons.lock_outline_rounded,
                              title: 'Ubah Password',
                              onTap: _showChangePasswordDialog,
                            ),
                            const Divider(height: 1, indent: 60),
                            _buildMenuItem(
                              icon: Icons.vpn_key_outlined,
                              title: 'Kode Akses Admin',
                              onTap: _showAdminTokenDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        AppButton(
                          text: 'Keluar',
                          color: AppColors.error,
                          onPressed: () => context.read<AuthBloc>().add(
                                const AuthSignOutRequested(),
                              ),
                          icon: Icons.logout_rounded,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserEntity user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
                width: 4,
              ),
            ),
            child: ClipOval(
              child: user.photoUrl != null
                  ? Image.network(
                      user.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(user),
                    )
                  : _buildDefaultAvatar(user),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  user.role == 'admin' ? 'Administrator' : 'Kasir',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Akun Aktif',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> items}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountInfoDialog(UserEntity user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Data Akun', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 24),
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              width: 4,
                            ),
                          ),
                          child: ClipOval(
                            child: _selectedImageBytes != null
                                ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                                : user.photoUrl != null
                                    ? Image.network(
                                        user.photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(user),
                                      )
                                    : _buildDefaultAvatar(user),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (pickedFile != null) {
                                final bytes = await pickedFile.readAsBytes();
                                setModalState(() {
                                  _selectedImageBytes = bytes;
                                  _selectedImageName = pickedFile.name;
                                });
                                setState(() {
                                  _selectedImageBytes = bytes;
                                  _selectedImageName = pickedFile.name;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildLabel('Nama Lengkap'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Nama lengkap'),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Email'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'email@contoh.com',
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Simpan Perubahan',
                    onPressed: () {
                      Navigator.pop(context);
                      _onUpdateProfile();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Ubah Password', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 24),
                  _buildLabel('Password Saat Ini'),
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: !_isCurrentPasswordVisible,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isCurrentPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setModalState(
                          () => _isCurrentPasswordVisible = !_isCurrentPasswordVisible,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Password Baru'),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: !_isNewPasswordVisible,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setModalState(
                          () => _isNewPasswordVisible = !_isNewPasswordVisible,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Konfirmasi Password'),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setModalState(
                          () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Update Password',
                    onPressed: () {
                      Navigator.pop(context);
                      _onUpdateProfile();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminTokenDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Kode Akses Admin', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Kode ini digunakan untuk pendaftaran akun admin baru.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel('Kode Akses'),
                  TextFormField(
                    controller: _adminTokenController,
                    obscureText: !_isAdminTokenVisible,
                    decoration: InputDecoration(
                      hintText: 'Contoh: ADMIN123',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isAdminTokenVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setModalState(
                          () => _isAdminTokenVisible = !_isAdminTokenVisible,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Simpan Kode Baru',
                    onPressed: () {
                      Navigator.pop(context);
                      _onUpdateAdminToken();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(UserEntity user) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
          style: AppTextStyles.displaySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
