import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tokoku/core/utils/formatters.dart';
import 'package:tokoku/presentation/blocs/product/product_bloc.dart';
import 'package:tokoku/presentation/screens/product/product_list_screen.dart';
import 'package:tokoku/presentation/screens/transaction/transaction_screen.dart';
import 'package:tokoku/presentation/screens/transaction/history_screen.dart';
import 'package:tokoku/presentation/screens/home/profile_screen.dart';
import 'package:tokoku/presentation/widgets/common/app_button.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_state.dart';
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

    // Trigger initial fetch global data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardBloc>().add(DashboardFetchRequested());
      context.read<ProductBloc>().add(const ProductLoadRequested());
    });
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
          return const HistoryScreen();
        case 4:
          return const ProfileScreen();
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
      title = [
        'Dashboard',
        'Produk',
        'Transaksi',
        'Riwayat',
        'Profil',
      ][_currentIndex];
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
                    _buildNavItem(3, Icons.history_rounded, 'Riwayat'),
                    _buildNavItem(4, Icons.person_outline_rounded, 'Profil'),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final authState = context.read<AuthBloc>().state;
        final user = authState is AuthAuthenticated ? authState.user : null;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 32),
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
                    child: user?.photoUrl != null
                        ? Image.network(
                            user!.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(user),
                          )
                        : _buildDefaultAvatar(user),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? '',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      AppButton(
                        text: 'Lihat Profil',
                        icon: Icons.person_outline_rounded,
                        onPressed: () {
                          Navigator.pop(context);
                          setState(
                            () => _currentIndex = 4,
                          ); // Index Profil untuk Kasir
                        },
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        text: 'Keluar Akun',
                        icon: Icons.logout_rounded,
                        color: AppColors.error,
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<AuthBloc>().add(
                            const AuthSignOutRequested(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar(dynamic user) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          user?.displayName?.isNotEmpty == true
              ? user.displayName[0].toUpperCase()
              : 'U',
          style: AppTextStyles.displaySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
    return RefreshIndicator(
      onRefresh: () async {
        context.read<DashboardBloc>().add(DashboardFetchRequested());
      },
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final stats = state is DashboardLoaded ? state.stats : null;
          final isLoading = state is DashboardLoading;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                _buildGreeting(),
                const SizedBox(height: 16),

                if (isAdmin) ...[
                  // Alert stok menipis (Admin Only)
                  _buildStockAlert(stats?['lowStockCount'] ?? 0),
                  const SizedBox(height: 20),

                  // Pendapatan hari ini (Admin Only)
                  _buildRevenueCard(
                    stats?['todayRevenue'] ?? 0,
                    stats?['revenueChange'] ?? 0,
                    isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Stats Row (Admin Only)
                  _buildStatsRow(
                    stats?['totalTransactions'] ?? 0,
                    stats?['totalProducts'] ?? 0,
                    isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Tren Penjualan (Admin Only)
                  _buildSalesTrend(
                    stats?['salesTrend'] as Map<String, double>?,
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // Alert stok menipis (Tampilkan juga untuk Kasir agar mereka tahu)
                  _buildStockAlert(stats?['lowStockCount'] ?? 0),
                  if (stats?['lowStockCount'] != null &&
                      stats?['lowStockCount'] > 0)
                    const SizedBox(height: 20),

                  // Cashier Greeting / Summary
                  Container(
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
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Siap Melayani?',
                                    style: AppTextStyles.titleLarge,
                                  ),
                                  Text(
                                    'Semoga harimu produktif!',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        _buildCashierStatsRow(
                          stats?['todayTransactions'] ??
                              0, // Perlu dipastikan di datasource
                          stats?['totalProducts'] ?? 0,
                          isLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Produk Terbaru (Kasir Only)
                  _buildLatestProducts(context),
                  const SizedBox(height: 24),
                ],

                // Aksi Cepat
                _buildQuickActions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLatestProducts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Produk Terbaru', style: AppTextStyles.headlineSmall),
            TextButton(
              onPressed: () => onTabChange(2), // Ke halaman produk
              child: Text(
                'Lihat Semua',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProductLoaded) {
              final latestProducts = state.products.toList();
              // Urutkan berdasarkan yang terbaru (asumsi id atau created at, tapi di entity tidak ada created at,
              // kita ambil 5 terakhir dari list default)
              final displayProducts = latestProducts.reversed.take(5).toList();

              if (displayProducts.isEmpty) {
                return Center(
                  child: Text(
                    'Belum ada produk',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayProducts.length,
                  itemBuilder: (context, index) {
                    final product = displayProducts[index];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              color: AppColors.surfaceVariant,
                              child: product.imageUrl?.isNotEmpty == true
                                  ? Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, e, s) =>
                                          const Icon(Icons.broken_image),
                                    )
                                  : const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 32,
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.currency(product.price),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: const Color(0xFFFF7A00),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
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

  Widget _buildStockAlert(int count) {
    if (count == 0) return const SizedBox.shrink();
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
                  '$count produk membutuhkan restock segera.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => onTabChange(1), // Go to products
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

  Widget _buildRevenueCard(double amount, double change, bool isLoading) {
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
          if (isLoading)
            const SizedBox(
              height: 40,
              width: 150,
              child: LinearProgressIndicator(minHeight: 2),
            )
          else
            Text(
              Formatters.currency(amount),
              style: AppTextStyles.priceDisplay.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                change >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 16,
                color: change >= 0 ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% dibanding kemarin',
                style: AppTextStyles.bodySmall.copyWith(
                  color: change >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int transactions, int products, bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Transaksi',
            isLoading ? '...' : Formatters.number(transactions),
            Icons.receipt_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Produk',
            isLoading ? '...' : Formatters.number(products),
            Icons.inventory_2_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildCashierStatsRow(
    int todayTransactions,
    int totalProducts,
    bool isLoading,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaksi Hari Ini',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isLoading ? '...' : todayTransactions.toString(),
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
        ),
        Container(width: 1, height: 30, color: AppColors.border),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Produk',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isLoading ? '...' : totalProducts.toString(),
                style: AppTextStyles.titleMedium,
              ),
            ],
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
                    AppColors.textSecondary,
                    index: 2,
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
                    index: 4,
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

  Widget _buildSalesTrend(Map<String, double>? salesTrend) {
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
                onPressed: () => onTabChange(3), // Go to reports
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
          _buildBarChart(salesTrend),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, double>? salesTrend) {
    // Default data jika null
    final trendData =
        salesTrend ??
        {'Sen': 0, 'Sel': 0, 'Rab': 0, 'Kam': 0, 'Jum': 0, 'Sab': 0, 'Ming': 0};

    final maxVal = trendData.values.fold<double>(
      0,
      (prev, curr) => curr > prev ? curr : prev,
    );

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trendData.entries.map((entry) {
          final heightFactor = maxVal > 0 ? entry.value / maxVal : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: heightFactor.clamp(
                        0.05,
                        1.0,
                      ), // Min height agar kelihatan
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppColors.primary,
                              AppColors.primaryLight.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
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
