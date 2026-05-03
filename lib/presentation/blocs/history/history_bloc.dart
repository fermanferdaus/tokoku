import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/product_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final ProductRepository _productRepository;

  HistoryBloc({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(HistoryInitial()) {
    on<HistoryFetchRequested>(_onFetchRequested);
  }

  Future<void> _onFetchRequested(
    HistoryFetchRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    try {
      final transactions = await _productRepository.getTransactions(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(HistoryLoaded(transactions));
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }
}
