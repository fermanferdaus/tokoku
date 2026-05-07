import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../blocs/cart/cart_bloc.dart';
import '../../blocs/cart/cart_event.dart';
import '../../blocs/cart/cart_state.dart';
import '../../blocs/product/product_bloc.dart';

class InvoiceScreen extends StatefulWidget {
  final CartState cartState;
  final double cash;
  final double change;
  final String invoiceNo;
  final String paymentMethod;

  const InvoiceScreen({
    super.key,
    required this.cartState,
    required this.cash,
    required this.change,
    required this.invoiceNo,
    this.paymentMethod = 'Tunai / Cash',
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareInvoice() async {
    try {
      final imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
      );

      if (imageBytes == null) return;

      if (kIsWeb) {
        // On web, use Share.shareXFiles with bytes directly
        await Share.shareXFiles([
          XFile.fromData(
            imageBytes,
            name: 'invoice_${widget.invoiceNo}.png',
            mimeType: 'image/png',
          ),
        ], text: 'Invoice Tokoku - ${widget.invoiceNo}');
      } else {
        // On mobile, save to temp and share
        final directory = await getTemporaryDirectory();
        final String fileName = 'invoice_${widget.invoiceNo}.png';

        await _screenshotController.captureAndSave(
          directory.path,
          fileName: fileName,
          delay: const Duration(milliseconds: 100),
        );

        final String filePath = '${directory.path}/$fileName';
        await Share.shareXFiles([
          XFile(filePath),
        ], text: 'Invoice Tokoku - ${widget.invoiceNo}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal berbagi invoice: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Invoice'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareInvoice,
          ),
        ],
      ),
      body: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background Watermark/Pattern inside the screenshot
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.1,
                            child: CustomPaint(
                              painter: InvoiceBackgroundPainter(),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header Struk
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Pembayaran Berhasil',
                                    style: AppTextStyles.titleLarge.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    Formatters.currency(widget.cartState.total),
                                    style: AppTextStyles.headlineMedium
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 24),

                                  // Info Transaksi
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildInfoRow(
                                          'No. Invoice',
                                          widget.invoiceNo,
                                          isPrimary: true,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          'Waktu',
                                          Formatters.dateTime(DateTime.now()),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          'Metode',
                                          widget.paymentMethod,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const DashedDivider(),

                            // Item List
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rincian Item',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...widget.cartState.items
                                      .map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${item.quantity}x',
                                                style: AppTextStyles.bodyMedium
                                                    .copyWith(
                                                      color: AppColors
                                                          .textTertiary,
                                                    ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.product.name,
                                                      style: AppTextStyles
                                                          .bodyMedium
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                    Text(
                                                      Formatters.currency(
                                                        item.product.price,
                                                      ),
                                                      style: AppTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                            color: AppColors
                                                                .textTertiary,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                Formatters.currency(
                                                  item.subtotal,
                                                ),
                                                style: AppTextStyles.bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      ,
                                ],
                              ),
                            ),

                            const DashedDivider(),

                            // Summary
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  _buildSummaryRow(
                                    'Subtotal',
                                    Formatters.currency(
                                      widget.cartState.subtotal,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    'Total',
                                    Formatters.currency(widget.cartState.total),
                                    isBold: true,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildSummaryRow(
                                    'Bayar',
                                    Formatters.currency(widget.cash),
                                  ),
                                  const Divider(height: 24),
                                  _buildSummaryRow(
                                    'Kembalian',
                                    Formatters.currency(widget.change),
                                    isBold: true,
                                    color: widget.change < 0
                                        ? AppColors.error
                                        : AppColors.success,
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Text(
                                'Terima kasih telah berbelanja!',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Button (Not included in screenshot)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<CartBloc>().add(const ClearCart());
                          context.read<ProductBloc>().add(
                            const ProductLoadRequested(),
                          );
                          context.go('/home?tab=transaction');
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
                        child: const Text(
                          'Transaksi Baru',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  Widget _buildInfoRow(String label, String value, {bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            color: isPrimary ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: isBold
              ? AppTextStyles.titleMedium.copyWith(
                  color: color ?? AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                )
              : AppTextStyles.bodyMedium.copyWith(
                  color: color ?? AppColors.textPrimary,
                ),
        ),
      ],
    );
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(
          40,
          (index) => Expanded(
            child: Container(
              color: index % 2 == 0
                  ? Colors.transparent
                  : AppColors.border.withValues(alpha: 0.5),
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class InvoiceBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'TOKOKU POS ',
        style: TextStyle(
          color: Colors.grey.withValues(alpha: 0.15),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    for (double i = 0; i < size.width; i += 150) {
      for (double j = 0; j < size.height; j += 150) {
        canvas.save();
        canvas.translate(i, j);
        canvas.rotate(-0.4);
        textPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
