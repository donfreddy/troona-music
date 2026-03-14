part of 'settings_cubit.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  const factory SettingsState.loading() = SettingsLoading;
  const factory SettingsState.loaded(AppSettings settings) = SettingsLoaded;
  const factory SettingsState.error(String message) = SettingsError;

  T? mapOrNull<T>({T Function(SettingsLoaded value)? loaded}) {
    if (this is SettingsLoaded) return loaded?.call(this as SettingsLoaded);
    return null;
  }
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();

  @override
  List<Object?> get props => [];
}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  const SettingsLoaded(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
