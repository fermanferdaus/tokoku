import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/product_repository.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ProductRepository _productRepository;

  DashboardBloc({required ProductRepository productRepository})
      : _productRepository = productRepository,
        super(DashboardInitial()) {
    on<DashboardFetchRequested>(_onFetchRequested);
  }

  Future<void> _onFetchRequested(
    DashboardFetchRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final stats = await _productRepository.getDashboardStats();
      emit(DashboardLoaded(stats));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
