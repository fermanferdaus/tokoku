import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tokoku/presentation/screens/product/product_list_screen.dart';
import 'package:tokoku/presentation/screens/transaction/transaction_screen.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../home/user_management_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;
        final isAdmin = user?.role == 'admin';

        return Scaffold(
          backgroundColor: AppColors.background,
          extendBody: true,
          appBar: _buildAppBar(user, isAdmin),
          body: _buildBody(user, isAdmin),
          bottomNavigationBar: _buildBottomNav(isAdmin),
        );
      },
    );
  }

  Widget _buildBody(dynamic user, bool isAdmin) {
    if (isAdmin) {
      switch (_currentIndex) {
        case 0:
          return _DashboardBody(
            user: user,
            isAdmin: true,
            onTabChange: (index) => setState(() => _currentIndex = index),
          );
        case 1:
          return const ProductListScreen();
        case 2:
          return const UserManagementScreen();
        case 3:
          return _PlaceholderBody(title: 'Laporan');
        case 4:
          return _PlaceholderBody(title: 'Pengaturan');
        default:
          return const SizedBox.shrink();
      }
    } else {
      // Cashier
      switch (_currentIndex) {
        case 0:
          return _DashboardBody(
            user: user,
            isAdmin: false,
            onTabChange: (index) => setState(() => _currentIndex = index),
          );
        case 1:
          return const ProductListScreen();
        case 2:
          return const TransactionScreen();
        case 3:
          return _PlaceholderBody(title: 'Profil');
        default:
          return const SizedBox.shrink();
      }
    }
  }

  PreferredSizeWidget _buildAppBar(dynamic user, bool isAdmin) {
    String title = '';
    if (isAdmin) {
      title = [
        'Dashboard',
        'Produk',
        'Kelola User',
        'Laporan',
        'Pengaturan',
      ][_currentIndex];
    } else {
      title = ['Dashboard', 'Produk', 'Transaksi', 'Profil'][_currentIndex];
    }

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        title,
        style: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () => _showProfileMenu(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: user?.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        user!.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              user.displayName?.isNotEmpty == true
                                  ? user.displayName![0].toUpperCase()
                                  : 'U',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        user?.displayName?.isNotEmpty == true
                            ? user!.displayName[0].toUpperCase()
                            : 'U',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(bool isAdmin) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: isAdmin
                ? [
                    _buildNavItem(0, Icons.home_rounded, 'Beranda'),
                    _buildNavItem(1, Icons.inventory_2_outlined, 'Produk'),
                    _buildCenterNavItem(2, Icons.people_alt_outlined),
                    _buildNavItem(3, Icons.bar_chart_rounded, 'Laporan'),
                    _buildNavItem(4, Icons.settings_outlined, 'Setting'),
                  ]
                : [
                    _buildNavItem(0, Icons.home_rounded, 'Beranda'),
                    _buildNavItem(1, Icons.inventory_2_outlined, 'Produk'),
                    _buildCenterNavItem(2, Icons.receipt_long_outlined),
                    _buildNavItem(3, Icons.person_outline_rounded, 'Profil'),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(int index, IconData icon) {
    // ignore: unused_local_variable
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Transform.translate(
        offset: const Offset(0, -20), // Pop out upwards
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.background,
              width: 6,
            ), // Creates a "cutout" effect against the background
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 28, // Slightly larger icon
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.textTertiary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final authState = context.read<AuthBloc>().state;
        final user = authState is AuthAuthenticated ? authState.user : null;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? Text(
                          user?.displayName.isNotEmpty == true
                              ? user!.displayName[0].toUpperCase()
                              : 'U',
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(user?.displayName ?? '', style: AppTextStyles.titleLarge),
                Text(
                  user?.email ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<AuthBloc>().add(
                        const AuthSignOutRequested(),
                      );
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
                    label: Text(
                      'Keluar',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widget body dashboard yang terpisah agar rapi
class _DashboardBody extends StatelessWidget {
  final dynamic user;
  final bool isAdmin;
  final Function(int) onTabChange;

  const _DashboardBody({
    this.user,
    required this.isAdmin,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 180),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          _buildGreeting(),
          const SizedBox(height: 16),

          if (isAdmin) ...[
            // Alert stok menipis (Admin Only)
            _buildStockAlert(),
            const SizedBox(height: 20),

            // Pendapatan hari ini (Admin Only)
            _buildRevenueCard(),
            const SizedBox(height: 16),

            // Stats Row (Admin Only)
            _buildStatsRow(),
            const SizedBox(height: 24),

            // Tren Penjualan (Admin Only)
            _buildSalesTrend(),
            const SizedBox(height: 20),
          ] else ...[
            // Cashier Greeting / Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Siap melayani pelanggan?',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pastikan stok produk dicek secara berkala untuk kelancaran transaksi.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Aksi Cepat
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final firstName = user?.displayName?.split(' ').first ?? 'User';
    final roleName = isAdmin ? 'Administrator' : 'Kasir';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Halo, $firstName',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isAdmin
                    ? AppColors.primaryContainer
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                roleName,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isAdmin ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isAdmin ? 'Ringkasan toko hari ini' : 'Selamat bekerja!',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStockAlert() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stok Menipis',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
                Text(
                  '5 produk membutuhkan restock segera.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 30),
            ),
            child: Text(
              'Cek',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pendapatan Hari Ini',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Rp 4.250.000',
            style: AppTextStyles.priceDisplay.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 4),
              Text(
                '+12.5% dibanding kemarin',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Transaksi',
            '84',
            Icons.receipt_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Produk',
            '1,240',
            Icons.inventory_2_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              Icon(icon, size: 18, color: AppColors.textTertiary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aksi Cepat', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 14),
        Row(
          children: isAdmin
              ? [
                  _buildActionButton(
                    'Kelola\nProduk',
                    Icons.inventory_2_outlined,
                    AppColors.textSecondary,
                    index: 1,
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    'Kelola\nUser',
                    Icons.people_alt_outlined,
                    AppColors.primary,
                    index: 2,
                    isPrimary: true,
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    'Laporan',
                    Icons.bar_chart_rounded,
                    AppColors.textSecondary,
                    index: 3,
                  ),
                ]
              : [
                  _buildActionButton(
                    'Mulai\nTransaksi',
                    Icons.receipt_long_outlined,
                    AppColors.primary,
                    index: 2,
                    isPrimary: true,
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    'Lihat\nProduk',
                    Icons.inventory_2_outlined,
                    AppColors.textSecondary,
                    index: 1,
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    'Lihat\nProfil',
                    Icons.person_outline_rounded,
                    AppColors.textSecondary,
                    index: 3,
                  ),
                ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color, {
    required int index,
    bool isPrimary = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChange(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: isPrimary ? null : Border.all(color: AppColors.border),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 26, color: isPrimary ? Colors.white : color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isPrimary ? Colors.white : color,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesTrend() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tren Penjualan (7 Hari)', style: AppTextStyles.titleMedium),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(60, 30),
                ),
                child: Text(
                  'Lihat Detail',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBarChart(),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final data = [
      _ChartData('Sen', 0.4),
      _ChartData('Sel', 0.35),
      _ChartData('Rab', 0.5),
      _ChartData('Kam', 0.55),
      _ChartData('Jum', 0.65),
      _ChartData('Sab', 0.8),
      _ChartData('Ming', 1.0),
    ];

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: item.value,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  const _ChartData(this.label, this.value);
}

class _PlaceholderBody extends StatelessWidget {
  final String title;
  const _PlaceholderBody({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            size: 72,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Halaman $title',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Halaman ini sedang dalam tahap pengembangan.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
