import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ProductRepository productRepository;
  final AuthRepository authRepository;

  ReportBloc({
    required this.productRepository,
    required this.authRepository,
  }) : super(ReportInitial()) {
    on<LoadReportData>(_onLoadReportData);
  }

  Future<void> _onLoadReportData(
    LoadReportData event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final ownerId = authRepository.currentUser.uid;
      final data = await productRepository.getReportData(
        ownerId: ownerId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(ReportLoaded(data));
    } catch (e) {
      emit(ReportError(e.toString()));
    }
  }
}
