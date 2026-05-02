import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tokoku/presentation/blocs/product/product_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _cashController = TextEditingController();
  double _change = 0;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _calculateChange(double total) {
    if (_cashController.text.isEmpty) {
      setState(() {
        _change = 0;
      });
      return;
    }

    final cashStr = _cashController.text.replaceAll(RegExp(r'[^\d]'), '');
    final cash = double.tryParse(cashStr) ?? 0;
    setState(() {
      _change = cash - total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (!state.isProcessing &&
            state.items.isEmpty &&
            Navigator.canPop(context)) {
          // If cart is cleared after success, handled in invoice
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Keranjang'),
          backgroundColor: AppColors.surface,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          actions: [
            TextButton(
              onPressed: () => _confirmClearCart(context),
              child: Text(
                'Kosongkan',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state.items.isEmpty && !state.isProcessing) {
              return _buildEmptyCart(context);
            }

            // Initial calculation if total changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _calculateChange(state.total);
            });

            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: state.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) =>
                            _buildCartItem(context, state.items[index]),
                      ),
                    ),
                    _buildOrderSummary(context, state),
                    _buildActionButtons(context, state),
                  ],
                ),
                if (state.isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text('Keranjang Kosong', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Mulai Belanja',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, dynamic item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              child:
                  item.product.imageUrl != null &&
                      item.product.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.product.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  Formatters.currency(item.product.price),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildQtyButton(Icons.remove, () {
                  if (item.quantity == 1) {
                    _confirmRemoveItem(context, item);
                  } else {
                    context.read<CartBloc>().add(
                      UpdateQuantity(item.product.id, item.quantity - 1),
                    );
                  }
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildQtyButton(
                  Icons.add,
                  () => context.read<CartBloc>().add(
                    UpdateQuantity(item.product.id, item.quantity + 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Pesanan', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          _buildSummaryRow('Total Items', '${state.totalItems.toInt()} Produk'),
          _buildSummaryRow('Subtotal', Formatters.currency(state.subtotal)),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Bayar', style: AppTextStyles.titleLarge),
              Text(
                Formatters.currency(state.total),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Input Uang Bayar
          Text(
            'Uang Tunai',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cashController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter(),
            ],
            onChanged: (_) => _calculateChange(state.total),
            decoration: InputDecoration(
              hintText: 'Masukkan jumlah uang...',
              prefixText: 'Rp ',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Tampilan Kembalian
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kembalian', style: AppTextStyles.bodyMedium),
              Text(
                Formatters.currency(_change),
                style: AppTextStyles.titleMedium.copyWith(
                  color: _change < 0 ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isNegative ? AppColors.error : AppColors.textPrimary,
              fontWeight: isNegative ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CartState state) {
    final bool canPay =
        _change >= 0 &&
        state.items.isNotEmpty &&
        _cashController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: canPay ? () => _goToInvoice(context, state) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.border,
                ),
                child: const Text(
                  'Bayar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final dateStr =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
    return "INV-$dateStr-$timeStr";
  }

  Future<void> _goToInvoice(BuildContext context, CartState state) async {
    final cashStr = _cashController.text.replaceAll(RegExp(r'[^\d]'), '');
    final cash = double.tryParse(cashStr) ?? 0;
    final invoiceNo = _generateInvoiceNumber();

    // Proses potong stok dan simpan transaksi di Bloc
    context.read<CartBloc>().add(
      ProcessCheckout(invoiceNo: invoiceNo, cash: cash, change: _change),
    );

    final bloc = context.read<CartBloc>();
    late StreamSubscription<CartState> subscription;
    subscription = bloc.stream.listen((newState) {
      if (!newState.isProcessing && newState.errorMessage == null) {
        // Hentikan pendengar agar tidak memicu navigasi ulang saat ClearCart
        subscription.cancel();

        // Muat ulang data produk agar stok terupdate di UI
        if (context.mounted) {
          context.read<ProductBloc>().add(const ProductLoadRequested());

          context.pushNamed(
            'invoice',
            extra: {
              'cartState': state,
              'cash': cash,
              'change': _change,
              'invoiceNo': invoiceNo,
            },
          );
        }
      }
    });

    // Cleanup subscription setelah navigasi atau timeout
    Future.delayed(const Duration(seconds: 10), () => subscription.cancel());
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Keranjang?'),
        content: const Text('Semua item dalam keranjang akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<CartBloc>().add(const ClearCart());
              Navigator.pop(ctx);
            },
            child: const Text(
              'Kosongkan',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveItem(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Item?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${item.product.name} dari keranjang?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context.read<CartBloc>().add(RemoveFromCart(item.product.id));
              Navigator.pop(ctx);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
