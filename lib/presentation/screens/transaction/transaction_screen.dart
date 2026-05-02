import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../injection_container.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  String _priceSort = 'none';
  double? _minPrice;
  double? _maxPrice;
  String? _selectedCategoryId;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryList(),
          Expanded(child: _buildProductGrid()),
          _buildCartSummary(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                  hintText: 'Cari produk, SKU...',
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

  Widget _buildCategoryList() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 60,
        child: Center(child: LinearProgressIndicator()),
      );
    }

    return Container(
      height: 60,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryChip(null, 'Semua Produk');
          }
          final category = _categories[index - 1];
          return _buildCategoryChip(category.id, category.name);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String? id, String label) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected && id != null) {
            _selectedCategoryId = null;
          } else {
            _selectedCategoryId = id;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        return BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProductLoaded) {
              final products = state.products.where((p) {
                // Category
                if (_selectedCategoryId != null) {
                  final selectedCat = _categories.firstWhere(
                    (c) => c.id == _selectedCategoryId,
                    orElse: () => CategoryEntity(
                      id: '',
                      name: _selectedCategoryId!,
                      ownerId: '',
                    ),
                  );

                  if (p.category != selectedCat.id &&
                      p.category != selectedCat.name) {
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
                products.sort((a, b) => a.price.compareTo(b.price));
              } else if (_priceSort == 'desc') {
                products.sort((a, b) => b.price.compareTo(a.price));
              }

              if (products.isEmpty) {
                return const Center(child: Text('No products found'));
              }

              // Dynamic bottom padding:
              // 130 if cart is visible, 80 if cart is empty
              final double bottomPadding = cartState.items.isNotEmpty
                  ? 25
                  : 140;

              return MasonryGridView.count(
                padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                itemCount: products.length,
                itemBuilder: (context, index) =>
                    _buildProductCard(products[index]),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildProductCard(ProductEntity product) {
    final isLowStock = product.stock > 0 && product.stock <= product.minStock;
    final isOutOfStock = product.stock <= 0;

    return GestureDetector(
      onTap: () => _showProductDetail(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image),
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.inventory_2_outlined),
                        ),
                ),
                if (isLowStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stok Menipis',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.currency(product.price),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOutOfStock
                                ? 'Stok Habis'
                                : '${product.stock} tersedia',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isOutOfStock
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: isOutOfStock
                            ? null
                            : () => context.read<CartBloc>().add(
                                AddToCart(product),
                              ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? AppColors.surfaceVariant
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: isOutOfStock
                                ? AppColors.textTertiary
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state.items.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            120,
          ), // Padding atas ditambah (24) agar lebih tinggi, bawah 120 untuk Navbar
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            bottom:
                false, // Matikan SafeArea bottom karena kita pakai padding manual yang lebih besar
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Keranjang',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      Formatters.currency(state.subtotal),
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => context.push('/transaction/cart'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(
                    'Checkout (${state.totalItems.toInt()})',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterModal() {
    String tempPriceSort = _priceSort;
    String? tempCategory = _selectedCategoryId;

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

                    // Urutkan Harga
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
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _priceSort = tempPriceSort;
                                _selectedCategoryId = tempCategory;

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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Terapkan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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

  void _showProductDetail(ProductEntity product) {
    final isOutOfStock = product.stock <= 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle Bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child:
                            product.imageUrl != null &&
                                product.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image),
                              )
                            : Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Badge Category
                    if (product.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _categories
                              .firstWhere(
                                (c) =>
                                    c.id == product.category ||
                                    c.name == product.category,
                                orElse: () => CategoryEntity(
                                  id: '',
                                  name: product.category!,
                                  ownerId: '',
                                ),
                              )
                              .name,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Name & Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: AppTextStyles.headlineSmall,
                          ),
                        ),
                        Text(
                          Formatters.currency(product.price),
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // SKU & Stock
                    Row(
                      children: [
                        const Icon(
                          Icons.qr_code_rounded,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.sku ?? '-',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: isOutOfStock
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOutOfStock
                              ? 'Stok Habis'
                              : '${product.stock} tersedia',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isOutOfStock
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text('Deskripsi Produk', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      product.description ?? 'Tidak ada deskripsi.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isOutOfStock
                            ? null
                            : () {
                                context.read<CartBloc>().add(
                                  AddToCart(product),
                                );
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: Text(
                          isOutOfStock
                              ? 'Stok Habis'
                              : 'Tambahkan ke Keranjang',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
