part of 'settings_cubit.dart';

enum AppThemeMode { system, light, dark, amoled }

class SettingsState extends Equatable {
  final AppThemeMode themeMode;
  final bool skipSilence;
  final int volumeBoostPercent;
  final int crossfadeSeconds;
  final int seekIntervalSeconds;
  final bool eqEnabled;
  final bool statsEnabled;

  const SettingsState({
    this.themeMode = AppThemeMode.system,
    this.skipSilence = false,
    this.volumeBoostPercent = 100,
    this.crossfadeSeconds = 0,
    this.seekIntervalSeconds = 10,
    this.eqEnabled = false,
    this.statsEnabled = true,
  });

  SettingsState copyWith({
    AppThemeMode? themeMode,
    bool? skipSilence,
    int? volumeBoostPercent,
    int? crossfadeSeconds,
    int? seekIntervalSeconds,
    bool? eqEnabled,
    bool? statsEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      skipSilence: skipSilence ?? this.skipSilence,
      volumeBoostPercent: volumeBoostPercent ?? this.volumeBoostPercent,
      crossfadeSeconds: crossfadeSeconds ?? this.crossfadeSeconds,
      seekIntervalSeconds: seekIntervalSeconds ?? this.seekIntervalSeconds,
      eqEnabled: eqEnabled ?? this.eqEnabled,
      statsEnabled: statsEnabled ?? this.statsEnabled,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        skipSilence,
        volumeBoostPercent,
        crossfadeSeconds,
        seekIntervalSeconds,
        eqEnabled,
        statsEnabled,
      ];
}
