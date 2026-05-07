import 'package:equatable/equatable.dart';
import '../../../domain/entities/product_entity.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final ProductEntity product;
  const AddToCart(this.product);

  @override
  List<Object?> get props => [product];
}

class RemoveFromCart extends CartEvent {
  final String productId;
  const RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

class UpdateQuantity extends CartEvent {
  final String productId;
  final int quantity;
  const UpdateQuantity(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

class ClearCart extends CartEvent {
  const ClearCart();
}

class ProcessCheckout extends CartEvent {
  final String invoiceNo;
  final double cash;
  final double change;
  final String paymentMethod;

  const ProcessCheckout({
    required this.invoiceNo,
    required this.cash,
    required this.change,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [invoiceNo, cash, change];
}
