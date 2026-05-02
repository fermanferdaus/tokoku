import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/repositories/category_repository.dart';
import '../../../injection_container.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/product/product_bloc.dart';
import '../../blocs/product/product_event.dart';
import '../../blocs/product/product_state.dart';
import '../../widgets/common/app_button.dart';

/// Form shared untuk Tambah dan Edit produk.
class ProductFormScreen extends StatefulWidget {
  final ProductEntity? product; // null = mode tambah

  const ProductFormScreen({super.key, this.product});

  bool get isEditing => product != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();

  File? _selectedImage;
  String? _existingImageUrl;
  String? _selectedCategory;
  bool _isActive = true;
  bool _isLoadingCategories = true;
  List<CategoryEntity> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.isEditing) {
      final p = widget.product!;
      _nameController.text = p.name;
      _descriptionController.text = p.description ?? '';
      _skuController.text = p.sku != null && p.sku!.isNotEmpty
          ? p.sku!
          : _generateSKU();
      _buyPriceController.text = p.buyPrice > 0
          ? Formatters.number(p.buyPrice.toInt())
          : '';
      _sellPriceController.text = p.price > 0 ? Formatters.number(p.price.toInt()) : '';
      _stockController.text = p.stock.toString();
      _selectedCategory = p.category;
      _existingImageUrl = p.imageUrl;
      _isActive = p.isActive;
    } else {
      _skuController.text = _generateSKU();
    }
  }

  String _generateSKU() {
    final state = context.read<ProductBloc>().state;
    if (state is ProductLoaded) {
      int maxNumber = 0;
      for (final product in state.products) {
        if (product.sku != null && product.sku!.startsWith('PRD-')) {
          final numberPart = product.sku!.substring(4);
          final number = int.tryParse(numberPart);
          if (number != null && number > maxNumber) {
            maxNumber = number;
          }
        }
      }
      return 'PRD-${(maxNumber + 1).toString().padLeft(5, '0')}';
    }
    return 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
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
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primary,
                ),
                title: Text('Kamera', style: AppTextStyles.titleMedium),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.primary,
                ),
                title: Text('Galeri', style: AppTextStyles.titleMedium),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _onSubmit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authState = context.read<AuthBloc>().state;
    final ownerId = authState is AuthAuthenticated ? authState.user.uid : '';

    final product = ProductEntity(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      price: double.tryParse(_sellPriceController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
      buyPrice: double.tryParse(_buyPriceController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
      stock: int.tryParse(_stockController.text) ?? 0,
      minStock: 0,
      sku: _skuController.text.trim().isEmpty
          ? _generateSKU()
          : _skuController.text.trim(),
      category: _selectedCategory,
      imageUrl: _existingImageUrl ?? '',
      ownerId: ownerId,
      isActive: _isActive,
      createdAt: widget.isEditing ? widget.product!.createdAt : DateTime.now(),
    );

    if (widget.isEditing) {
      context.read<ProductBloc>().add(
        ProductUpdateRequested(
          product: product,
          imageFile: _selectedImage,
          originalImageUrl: widget.product?.imageUrl,
        ),
      );
    } else {
      context.read<ProductBloc>().add(
        ProductAddRequested(product: product, imageFile: _selectedImage),
      );
    }
  }

  void _showManageCategoriesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _ManageCategoriesModal(
          initialCategories: _categories,
          onCategoriesUpdated: (updatedCategories) {
            setState(() {
              _categories = updatedCategories;
              // Reset selected category if it was deleted
              if (_selectedCategory != null &&
                  !updatedCategories.any((c) => c.name == _selectedCategory)) {
                _selectedCategory = null;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductOperationSuccess) {
          context.pop();
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
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          final isLoading = state is ProductLoading;

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
                widget.isEditing ? 'Edit Produk' : 'Tambah Produk',
                style: AppTextStyles.titleLarge,
              ),
              centerTitle: true,
              actions: widget.isEditing
                  ? [
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                'Hapus Produk?',
                                style: AppTextStyles.headlineSmall,
                              ),
                              content: Text(
                                'Produk ini akan dihapus.',
                                style: AppTextStyles.bodyMedium,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    context.read<ProductBloc>().add(
                                      ProductDeleteRequested(
                                        widget.product!.id,
                                        imageUrl: widget.product!.imageUrl,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: Text(
                                    'Hapus',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ]
                  : null,
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Foto Produk
                        _buildImageSection(),
                        const SizedBox(height: 24),

                        // Informasi Dasar
                        _buildSectionCard(
                          title: 'Informasi Dasar',
                          children: [
                            _buildLabel('Nama Produk *'),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: Kantong Kresek',
                              ),
                              validator: (v) =>
                                  Validators.validateRequired(v, 'Nama Produk'),
                            ),
                            const SizedBox(height: 16),

                            _buildLabel('Kategori *'),
                            _buildCategoryDropdown(),
                            const SizedBox(height: 16),

                            _buildLabel('Deskripsi Produk'),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Jelaskan detail produk Anda...',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Harga & Inventaris
                        _buildSectionCard(
                          title: 'Harga & Inventaris',
                          children: [
                            _buildLabel('SKU (Stock Keeping Unit)'),
                            TextFormField(
                              controller: _skuController,
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'Contoh: KKM-001',
                                filled: true,
                                fillColor: AppColors.surfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Harga Beli *'),
                                      TextFormField(
                                        controller: _buyPriceController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          CurrencyInputFormatter(),
                                        ],
                                        decoration: const InputDecoration(
                                          prefixText: 'Rp ',
                                        ),
                                        validator: (v) => Validators.validateRequired(v, 'Harga Beli'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Harga Jual *'),
                                      TextFormField(
                                        controller: _sellPriceController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          CurrencyInputFormatter(),
                                        ],
                                        decoration: const InputDecoration(
                                          prefixText: 'Rp ',
                                        ),
                                        validator: (v) =>
                                            Validators.validateRequired(
                                              v,
                                              'Harga Jual',
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildLabel(
                              widget.isEditing
                                  ? 'Stok Tersedia *'
                                  : 'Stok Awal *',
                            ),
                            TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(hintText: '0'),
                              validator: (v) => Validators.validateStock(v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Status Produk (hanya mode edit)
                        if (widget.isEditing) ...[
                          _buildSectionCard(
                            title: 'Status Produk',
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Produk Aktif',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  Switch.adaptive(
                                    value: _isActive,
                                    activeTrackColor: AppColors.primary,
                                    onChanged: (v) =>
                                        setState(() => _isActive = v),
                                  ),
                                ],
                              ),
                              if (widget.product?.updatedAt != null)
                                Text(
                                  'Terakhir diubah: ${_formatDate(widget.product!.updatedAt!)}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Submit
                        const SizedBox(height: 8),
                        if (widget.isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: 'Batal',
                                  isOutlined: true,
                                  onPressed: () => context.pop(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppButton(
                                  text: 'Simpan Perubahan',
                                  isLoading: isLoading,
                                  onPressed: isLoading ? null : _onSubmit,
                                ),
                              ),
                            ],
                          )
                        else
                          AppButton(
                            text: 'Simpan Produk',
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _onSubmit,
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                if (isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Foto Produk', style: AppTextStyles.titleMedium),
              Text(
                'Max. 5MB',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: _buildImagePreview(),
            ),
          ),
          if (_selectedImage != null ||
              (_existingImageUrl != null && _existingImageUrl!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _existingImageUrl = null;
                  });
                },
                child: Text(
                  'Hapus Foto',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    }

    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: _existingImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (context, url, error) => _buildImagePlaceholder(),
        ),
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 36,
          color: AppColors.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 8),
        Text(
          'Klik untuk unggah',
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
        ),
        Text(
          'atau tarik & lepas file ke sini',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
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

  Widget _buildCategoryDropdown() {
    if (_isLoadingCategories) {
      return const LinearProgressIndicator();
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _categories.any((c) => c.id == _selectedCategory || c.name == _selectedCategory)
                ? _categories.firstWhere((c) => c.id == _selectedCategory || c.name == _selectedCategory).id
                : null,
            decoration: const InputDecoration(hintText: 'Pilih Kategori'),
            items: _categories
                .map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
            validator: (v) =>
                v == null || v.isEmpty ? 'Kategori wajib dipilih' : null,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _showManageCategoriesModal,
          icon: const Icon(
            Icons.settings_suggest_rounded,
            color: AppColors.primary,
          ),
          tooltip: 'Kelola Kategori',
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ManageCategoriesModal extends StatefulWidget {
  final List<CategoryEntity> initialCategories;
  final Function(List<CategoryEntity>) onCategoriesUpdated;

  const _ManageCategoriesModal({
    required this.initialCategories,
    required this.onCategoriesUpdated,
  });

  @override
  State<_ManageCategoriesModal> createState() => _ManageCategoriesModalState();
}

class _ManageCategoriesModalState extends State<_ManageCategoriesModal> {
  late List<CategoryEntity> _categories;
  final _addController = TextEditingController();
  bool _isLoading = false;
  String? _editingCategoryId;
  final _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.initialCategories);
  }

  @override
  void dispose() {
    _addController.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _addController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final newCategory = await sl<CategoryRepository>().addCategory(name);
      setState(() {
        _categories.add(newCategory);
        _addController.clear();
      });
      widget.onCategoriesUpdated(_categories);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambah kategori'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCategory(CategoryEntity category) async {
    final newName = _editController.text.trim();
    if (newName.isEmpty || newName == category.name) {
      setState(() => _editingCategoryId = null);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updatedCategory = CategoryEntity(
        id: category.id,
        name: newName,
        ownerId: category.ownerId,
      );
      await sl<CategoryRepository>().updateCategory(updatedCategory);
      setState(() {
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) _categories[index] = updatedCategory;
        _editingCategoryId = null;
      });
      widget.onCategoriesUpdated(_categories);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengupdate kategori'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCategory(CategoryEntity category) async {
    setState(() => _isLoading = true);
    try {
      await sl<CategoryRepository>().deleteCategory(category.id);
      setState(() {
        _categories.removeWhere((c) => c.id == category.id);
      });
      widget.onCategoriesUpdated(_categories);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus kategori'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kelola Kategori', style: AppTextStyles.headlineSmall),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          if (_isLoading) const LinearProgressIndicator(),

          // List Kategori
          Expanded(
            child: _categories.isEmpty
                ? Center(
                    child: Text('Belum ada kategori', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _categories.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isEditing = _editingCategoryId == category.id;

                      if (isEditing) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _editController,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                                onPressed: () => _updateCategory(category),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel_rounded, color: AppColors.textTertiary),
                                onPressed: () => setState(() => _editingCategoryId = null),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(category.name, style: AppTextStyles.titleMedium),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                              onPressed: () {
                                setState(() {
                                  _editingCategoryId = category.id;
                                  _editController.text = category.name;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Kategori?'),
                                    content: const Text('Kategori akan dihapus selamanya.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _deleteCategory(category);
                                        },
                                        child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Form Tambah
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addController,
                    decoration: const InputDecoration(
                      hintText: 'Kategori baru...',
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addCategory,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
