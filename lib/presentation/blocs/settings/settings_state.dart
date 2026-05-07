part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final String code;

  const SettingsLoaded(this.code);

  @override
  List<Object?> get props => [code];
}

class SettingsSuccess extends SettingsState {
  final String message;

  const SettingsSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
