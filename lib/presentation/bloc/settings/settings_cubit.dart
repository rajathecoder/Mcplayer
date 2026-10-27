import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/audio/audio_player_handler.dart';
import '../playback/playback_cubit.dart';

part 'settings_state.dart';

const _kThemeMode = 'settings.themeMode';
const _kSkipSilence = 'settings.skipSilence';
const _kVolumeBoost = 'settings.volumeBoost';
const _kCrossfade = 'settings.crossfadeSeconds';
const _kSeekInterval = 'settings.seekInterval';
const _kEqEnabled = 'settings.eqEnabled';
const _kStatsEnabled = 'settings.statsEnabled';

class SettingsCubit extends Cubit<SettingsState> {
  final AudioPlayerHandler _handler;
  final PlaybackCubit _playbackCubit;
  SharedPreferences? _prefs;

  SettingsCubit(this._handler, this._playbackCubit) : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final loaded = SettingsState(
      themeMode: AppThemeMode.values[prefs.getInt(_kThemeMode) ?? 0],
      skipSilence: prefs.getBool(_kSkipSilence) ?? false,
      volumeBoostPercent: prefs.getInt(_kVolumeBoost) ?? 100,
      crossfadeSeconds: prefs.getInt(_kCrossfade) ?? 0,
      seekIntervalSeconds: prefs.getInt(_kSeekInterval) ?? 10,
      eqEnabled: prefs.getBool(_kEqEnabled) ?? false,
      statsEnabled: prefs.getBool(_kStatsEnabled) ?? true,
    );
    emit(loaded);
    await _applyToHandler(loaded);
    _playbackCubit.crossfadeSeconds = loaded.crossfadeSeconds;
    _playbackCubit.statsEnabled = loaded.statsEnabled;
  }

  Future<void> _applyToHandler(SettingsState s) async {
    await _handler.setSkipSilenceEnabled(s.skipSilence);
    await _handler.setVolumeBoost(s.volumeBoostPercent);
    await _handler.equalizer.setEnabled(s.eqEnabled);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _prefs?.setInt(_kThemeMode, mode.index);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setSkipSilence(bool enabled) async {
    await _prefs?.setBool(_kSkipSilence, enabled);
    await _handler.setSkipSilenceEnabled(enabled);
    emit(state.copyWith(skipSilence: enabled));
  }

  Future<void> setVolumeBoost(int percent) async {
    await _prefs?.setInt(_kVolumeBoost, percent);
    await _handler.setVolumeBoost(percent);
    emit(state.copyWith(volumeBoostPercent: percent));
  }

  /// Note: with just_audio's single-decoder pipeline this produces a fade
  /// near the end of each track rather than true overlapping dual-track
  /// crossfade (which would require running two decoders in parallel).
  Future<void> setCrossfadeSeconds(int seconds) async {
    await _prefs?.setInt(_kCrossfade, seconds);
    _playbackCubit.crossfadeSeconds = seconds;
    emit(state.copyWith(crossfadeSeconds: seconds));
  }

  Future<void> setSeekInterval(int seconds) async {
    await _prefs?.setInt(_kSeekInterval, seconds);
    emit(state.copyWith(seekIntervalSeconds: seconds));
  }

  Future<void> setEqEnabled(bool enabled) async {
    await _prefs?.setBool(_kEqEnabled, enabled);
    await _handler.equalizer.setEnabled(enabled);
    emit(state.copyWith(eqEnabled: enabled));
  }

  Future<void> setStatsEnabled(bool enabled) async {
    await _prefs?.setBool(_kStatsEnabled, enabled);
    _playbackCubit.statsEnabled = enabled;
    emit(state.copyWith(statsEnabled: enabled));
  }
}
