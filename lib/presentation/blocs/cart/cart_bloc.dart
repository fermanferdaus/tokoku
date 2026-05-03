import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/repositories/product_repository_impl.dart';
import '../../../domain/repositories/product_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final ProductRepository _productRepository;

  CartBloc({required ProductRepository productRepository})
    : _productRepository = productRepository,
      super(const CartState()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
    on<ProcessCheckout>(_onProcessCheckout);
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    final updatedItems = List<CartItemModel>.from(state.items);
    final index = updatedItems.indexWhere(
      (item) => item.product.id == event.product.id,
    );

    if (index >= 0) {
      if (updatedItems[index].quantity < event.product.stock) {
        updatedItems[index] = updatedItems[index].copyWith(
          quantity: updatedItems[index].quantity + 1,
        );
      }
    } else {
      if (event.product.stock > 0) {
        updatedItems.add(CartItemModel(product: event.product, quantity: 1));
      }
    }

    emit(state.copyWith(items: updatedItems, errorMessage: null));
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    final updatedItems = state.items
        .where((item) => item.product.id != event.productId)
        .toList();
    emit(state.copyWith(items: updatedItems, errorMessage: null));
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<CartState> emit) {
    if (event.quantity <= 0) {
      add(RemoveFromCart(event.productId));
      return;
    }

    final updatedItems = List<CartItemModel>.from(state.items);
    final index = updatedItems.indexWhere(
      (item) => item.product.id == event.productId,
    );

    if (index >= 0) {
      if (event.quantity <= updatedItems[index].product.stock) {
        updatedItems[index] = updatedItems[index].copyWith(
          quantity: event.quantity,
        );
      }
    }

    emit(state.copyWith(items: updatedItems, errorMessage: null));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(const CartState());
  }

  Future<void> _onProcessCheckout(
    ProcessCheckout event,
    Emitter<CartState> emit,
  ) async {
    if (state.items.isEmpty) return;

    emit(state.copyWith(isProcessing: true, errorMessage: null));

    try {
      final user = (_productRepository as ProductRepositoryImpl)
          .authRepository
          .currentUser;
      final displayName = user.displayName;
      final String cashierName = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : (user.email);

      // Map item ke format yang diinginkan Firestore
      final itemsMap = state.items
          .map(
            (item) => {
              'productId': item.product.id,
              'name': item.product.name,
              'productName': item
                  .product
                  .name, // Tambahkan alias agar konsisten dengan UI detail
              'price': item.product.price,
              'quantity': item.quantity,
              'subtotal': item.subtotal,
              'userName':
                  cashierName, // Masukkan nama kasir ke setiap item/header
            },
          )
          .toList();

      await _productRepository.createTransaction(
        invoiceNo: event.invoiceNo,
        items: itemsMap,
        subtotal: state.subtotal,
        total: state.total,
        cash: event.cash,
        change: event.change,
      );

      emit(state.copyWith(isProcessing: false));
    } catch (e) {
      emit(state.copyWith(isProcessing: false, errorMessage: e.toString()));
    }
  }
}
