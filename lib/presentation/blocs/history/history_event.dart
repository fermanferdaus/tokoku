import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryFetchRequested extends HistoryEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const HistoryFetchRequested({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
