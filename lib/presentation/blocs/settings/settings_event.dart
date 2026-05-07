part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsLoadRequested extends SettingsEvent {}

class SettingsUpdateRequested extends SettingsEvent {
  final String newCode;

  const SettingsUpdateRequested(this.newCode);

  @override
  List<Object?> get props => [newCode];
}
