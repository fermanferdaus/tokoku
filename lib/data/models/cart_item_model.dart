import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entity.dart';

class CartItemModel extends Equatable {
  final ProductEntity product;
  final int quantity;

  const CartItemModel({
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;

  CartItemModel copyWith({
    ProductEntity? product,
    int? quantity,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}
