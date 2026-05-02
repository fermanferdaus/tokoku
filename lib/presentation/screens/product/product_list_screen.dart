import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:tokoku/presentation/blocs/auth/auth_bloc.dart';
import 'package:tokoku/presentation/blocs/auth/auth_state.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../injection_container.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../widgets/common/app_button.dart';

/// Halaman daftar produk dengan fitur search dan CRUD.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  String _priceSort = 'none'; // 'none', 'asc', 'desc'
  double? _minPrice;
  double? _maxPrice;
  String? _selectedCategory;
  List<CategoryEntity> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const ProductLoadRequested());
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await sl<CategoryRepository>().getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final isAdmin = user?.role == 'admin';

        return BlocListener<ProductBloc, ProductState>(
          listener: (context, state) {
            if (state is ProductOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is ProductError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                _buildSearchBar(),
                Expanded(child: _buildProductList()),
              ],
            ),
            floatingActionButton: isAdmin
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: FloatingActionButton(
                      onPressed: () => context.push('/product/add'),
                      backgroundColor: AppColors.primary,
                      child: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  context.read<ProductBloc>().add(
                    ProductSearchRequested(value),
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama atau SKU produk...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context.read<ProductBloc>().add(
                              const ProductLoadRequested(),
                            );
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showFilterModal,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ProductEntity> _getFilteredProducts(List<ProductEntity> products) {
    var filtered = products.where((p) {
      // Category
      if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
        final selectedCat = _categories.firstWhere(
          (c) => c.id == _selectedCategory,
          orElse: () =>
              CategoryEntity(id: '', name: _selectedCategory!, ownerId: ''),
        );

        if (p.category != selectedCat.id && p.category != selectedCat.name) {
          return false;
        }
      }

      // Min price
      if (_minPrice != null && p.price < _minPrice!) {
        return false;
      }

      // Max price
      if (_maxPrice != null && p.price > _maxPrice!) {
        return false;
      }

      return true;
    }).toList();

    // Sort
    if (_priceSort == 'asc') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_priceSort == 'desc') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    }

    return filtered;
  }

  Widget _buildProductList() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is ProductLoaded) {
          if (state.products.isEmpty && _searchController.text.isEmpty) {
            return _buildEmptyState();
          }

          final filteredProducts = _getFilteredProducts(state.products);

          if (filteredProducts.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada produk yang sesuai filter',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ProductBloc>().add(const ProductLoadRequested());
            },
            child: MasonryGridView.count(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductItem(filteredProducts[index]);
              },
            ),
          );
        }

        if (state is ProductError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.read<ProductBloc>().add(
                    const ProductLoadRequested(),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 72,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada produk',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan produk pertamamu\ndengan menekan tombol + di bawah',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(ProductEntity product) {
    final isArchived = !product.isActive;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bagian Gambar
          Stack(
            children: [
              Container(
                height:
                    150, // Fixed height for image area to keep it consistent but allow card to expand
                width: double.infinity,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.textTertiary,
                          size: 32,
                        ),
                      ),
              ),
              if (isArchived)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'DIARSIPKAN',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Bagian Detail
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.sku != null && product.sku!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${product.sku}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  Formatters.currency(product.price),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: const Color(0xFFFF7A00),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final user = authState is AuthAuthenticated
                        ? authState.user
                        : null;
                    final isAdmin = user?.role == 'admin';

                    if (!isAdmin) return const SizedBox(height: 8);

                    return Column(
                      children: [
                        const Divider(height: 1, color: AppColors.border),
                        Row(
                          children: [
                            Expanded(
                              child: IconButton(
                                onPressed: () =>
                                    context.push('/product/edit/${product.id}'),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                constraints: const BoxConstraints(
                                  minHeight: 36,
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: IconButton(
                                onPressed: () => _confirmDelete(product),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: Color(0xFFFF4D6D),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                constraints: const BoxConstraints(
                                  minHeight: 36,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ProductEntity product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Produk?', style: AppTextStyles.headlineSmall),
        content: Text(
          'Produk "${product.name}" akan dihapus. Tindakan ini tidak dapat dibatalkan.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProductBloc>().add(
                ProductDeleteRequested(product.id, imageUrl: product.imageUrl),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Hapus',
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    String tempPriceSort = _priceSort;
    String? tempCategory = _selectedCategory;

    // Copy current values to controllers
    _minPriceController.text = _minPrice != null
        ? Formatters.number(_minPrice!)
        : '';
    _maxPriceController.text = _maxPrice != null
        ? Formatters.number(_maxPrice!)
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filter Produk', style: AppTextStyles.titleLarge),
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sort Harga
                    Text('Urutkan Harga', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Semua'),
                          selected: tempPriceSort == 'none',
                          selectedColor: AppColors.primaryContainer,
                          onSelected: (selected) {
                            if (selected)
                              setModalState(() => tempPriceSort = 'none');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Terendah'),
                          selected: tempPriceSort == 'asc',
                          selectedColor: AppColors.primaryContainer,
                          onSelected: (selected) {
                            if (selected)
                              setModalState(() => tempPriceSort = 'asc');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Tertinggi'),
                          selected: tempPriceSort == 'desc',
                          selectedColor: AppColors.primaryContainer,
                          onSelected: (selected) {
                            if (selected)
                              setModalState(() => tempPriceSort = 'desc');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Kategori
                    if (!_isLoadingCategories && _categories.isNotEmpty) ...[
                      Text('Kategori', style: AppTextStyles.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Semua'),
                            selected: tempCategory == null,
                            selectedColor: AppColors.primaryContainer,
                            onSelected: (selected) {
                              if (selected)
                                setModalState(() => tempCategory = null);
                            },
                          ),
                          ..._categories.map((cat) {
                            return ChoiceChip(
                              label: Text(cat.name),
                              selected: tempCategory == cat.id,
                              selectedColor: AppColors.primaryContainer,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() => tempCategory = cat.id);
                                }
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Rentang Harga
                    Text('Rentang Harga', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            decoration: InputDecoration(
                              hintText: 'Minimal',
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                            decoration: InputDecoration(
                              hintText: 'Maksimal',
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                tempPriceSort = 'none';
                                tempCategory = null;
                                _minPriceController.clear();
                                _maxPriceController.clear();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            text: 'Terapkan',
                            onPressed: () {
                              setState(() {
                                _priceSort = tempPriceSort;
                                _selectedCategory = tempCategory;

                                final minText = _minPriceController.text
                                    .replaceAll(RegExp(r'[^\d]'), '');
                                _minPrice = minText.isNotEmpty
                                    ? double.tryParse(minText)
                                    : null;

                                final maxText = _maxPriceController.text
                                    .replaceAll(RegExp(r'[^\d]'), '');
                                _maxPrice = maxText.isNotEmpty
                                    ? double.tryParse(maxText)
                                    : null;
                              });
                              context.pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
