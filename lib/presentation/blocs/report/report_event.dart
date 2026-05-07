import 'package:equatable/equatable.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportData extends ReportEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadReportData({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
