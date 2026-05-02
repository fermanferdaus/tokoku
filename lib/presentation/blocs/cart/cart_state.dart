import 'package:equatable/equatable.dart';
import '../../../data/models/cart_item_model.dart';

class CartState extends Equatable {
  final List<CartItemModel> items;
  final double discount;
  final double taxRate;
  final bool isProcessing;
  final String? errorMessage;

  const CartState({
    this.items = const [],
    this.discount = 0,
    this.taxRate = 0.0,
    this.isProcessing = false,
    this.errorMessage,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get totalItems => items.fold(0, (sum, item) => sum + item.quantity).toDouble();
  double get taxAmount => (subtotal - discount) * taxRate;
  double get total => (subtotal - discount) + taxAmount;

  CartState copyWith({
    List<CartItemModel>? items,
    double? discount,
    double? taxRate,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [items, discount, taxRate, isProcessing, errorMessage];
}
