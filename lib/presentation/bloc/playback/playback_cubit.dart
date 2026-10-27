import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../../core/audio/audio_player_handler.dart';
import '../../../core/widget/home_widget_service.dart';
import '../../../data/datasources/local/stats_local_datasource.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/repositories/queue_repository.dart';

part 'playback_state.dart';

/// Combines the [AudioPlayerHandler]'s streams into a single UI-friendly state
/// and exposes intent methods (play, skip, shuffle, ...) for the presentation layer.
class PlaybackCubit extends Cubit<PlaybackUiState> {
  final AudioPlayerHandler _handler;
  final QueueRepository _queueRepository;
  final StatsLocalDataSource _stats;
  final HomeWidgetService _homeWidget;

  StreamSubscription? _stateSub;
  StreamSubscription<Duration>? _crossfadeSub;
  Timer? _persistTimer;
  final Stopwatch _trackStopwatch = Stopwatch();
  String? _trackingPath;

  /// Seconds of fade-out applied near the end of a track. Set by [SettingsCubit].
  /// Note: just_audio uses a single decoder, so this fades the outgoing track's
  /// volume rather than overlapping it with the next one (true dual-track
  /// crossfade isn't achievable without a second decoder instance).
  int crossfadeSeconds = 0;
  bool _fading = false;

  /// Set by [SettingsCubit]; when false, play/skip stats are not recorded.
  bool statsEnabled = true;

  PlaybackCubit(this._handler, this._queueRepository, this._stats, this._homeWidget)
      : super(const PlaybackUiState()) {
    _crossfadeSub = _handler.positionStream.listen(_maybeFadeForCrossfade);
    _stateSub = Rx.combineLatest3<MediaItem?, PlaybackState, List<MediaItem>, PlaybackUiState>(
      _handler.mediaItem,
      _handler.playbackState,
      _handler.queue,
      (mediaItem, playbackState, queue) => PlaybackUiState(
        mediaItem: mediaItem,
        queue: queue,
        currentIndex: playbackState.queueIndex ?? -1,
        playing: playbackState.playing,
        bufferedPosition: playbackState.bufferedPosition,
        repeatMode: playbackState.repeatMode,
        shuffleMode: playbackState.shuffleMode,
        processingState: playbackState.processingState,
      ),
    ).listen(_onStateChanged);

    _persistTimer = Timer.periodic(const Duration(seconds: 5), (_) => _persistQueueState());
  }

  Stream<Duration> get positionStream => _handler.positionStream;

  Duration get position => _handler.player.position;

  void _onStateChanged(PlaybackUiState newState) {
    final trackChanged = newState.mediaItem?.id != state.mediaItem?.id;
    final playingChanged = newState.playing != state.playing;

    if (trackChanged) {
      _finalizeTrackStats();
      _trackingPath = newState.mediaItem?.id;
      _trackStopwatch
        ..reset()
        ..stop();
      if (newState.playing) _trackStopwatch.start();
      _fading = false;
      _handler.player.setVolume(1.0);
    } else if (playingChanged) {
      if (newState.playing) {
        _trackStopwatch.start();
      } else {
        _trackStopwatch.stop();
      }
    }

    emit(newState);
    if (trackChanged) _persistQueueState();
    if (trackChanged || playingChanged) _updateHomeWidget(newState);
  }

  void _updateHomeWidget(PlaybackUiState state) {
    if (state.mediaItem == null) {
      _homeWidget.clear();
    } else {
      _homeWidget.update(
        title: state.mediaItem!.title,
        artist: state.mediaItem!.artist ?? 'Unknown Artist',
        isPlaying: state.playing,
      );
    }
  }

  void _maybeFadeForCrossfade(Duration position) {
    final duration = state.mediaItem?.duration;
    if (crossfadeSeconds <= 0 || duration == null || duration == Duration.zero) return;
    final remaining = duration - position;
    if (remaining.inSeconds <= crossfadeSeconds && remaining > Duration.zero) {
      if (!_fading) _fading = true;
      final fraction = remaining.inMilliseconds / (crossfadeSeconds * 1000);
      _handler.player.setVolume(fraction.clamp(0.05, 1.0));
    }
  }

  /// Records a play (>=30% listened or >=10s) or a skip for the track that just ended.
  void _finalizeTrackStats() {
    if (!statsEnabled) return;
    final path = _trackingPath;
    if (path == null) return;
    final listenedMs = _trackStopwatch.elapsedMilliseconds;
    final durationMs = state.mediaItem?.duration?.inMilliseconds ?? 0;
    final countedAsPlay = listenedMs >= 10000 || (durationMs > 0 && listenedMs >= durationMs * 0.3);
    if (countedAsPlay) {
      _stats.recordPlay(path, listenedMs: listenedMs);
    } else if (listenedMs > 0) {
      _stats.recordSkip(path);
    }
  }

  Future<void> _persistQueueState() async {
    if (state.queue.isEmpty || state.currentIndex < 0) return;
    final paths = state.queue.map((m) => m.id).toList();
    await _queueRepository.saveQueue(paths, state.currentIndex, position);
  }

  /// Attempts to restore the last session's queue without auto-playing.
  Future<void> restoreLastSession() async {
    final restored = await _queueRepository.restoreQueue();
    if (restored == null) return;
    await _handler.setQueue(
      restored.songs,
      initialIndex: restored.currentIndex,
      initialPosition: restored.position,
      playImmediately: false,
    );
  }

  Future<void> playQueue(List<Song> songs, {int startIndex = 0}) async {
    await _handler.setQueue(songs, initialIndex: startIndex);
  }

  Future<void> playSingle(Song song) => playQueue([song]);

  void togglePlayPause() {
    if (state.playing) {
      _handler.pause();
    } else {
      _handler.play();
    }
  }

  Future<void> skipNext() => _handler.skipToNext();

  Future<void> skipPrevious() => _handler.skipToPrevious();

  Future<void> seek(Duration position) => _handler.seek(position);

  Future<void> setSpeed(double speed) => _handler.setSpeed(speed);

  Future<void> skipToQueueItem(int index) => _handler.skipToQueueItem(index);

  Future<void> playNext(Song song) => _handler.addToQueueNext(song);

  Future<void> addToQueue(Song song) => _handler.addToQueueEnd(song);

  Future<void> removeFromQueue(int index) => _handler.removeQueueItemAt(index);

  Future<void> reorderQueue(int oldIndex, int newIndex) => _handler.reorderQueue(oldIndex, newIndex);

  Future<void> clearQueue() async {
    await _handler.clearQueue();
    await _queueRepository.clearQueue();
  }

  Future<void> toggleShuffle() {
    final newMode =
        state.shuffleMode == AudioServiceShuffleMode.none ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none;
    return _handler.setShuffleMode(newMode);
  }

  Future<void> reshuffle() => _handler.reshuffle();

  Future<void> cycleRepeatMode() {
    final next = switch (state.repeatMode) {
      AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
      AudioServiceRepeatMode.one => AudioServiceRepeatMode.none,
      AudioServiceRepeatMode.group => AudioServiceRepeatMode.none,
    };
    return _handler.setRepeatMode(next);
  }

  @override
  Future<void> close() async {
    _finalizeTrackStats();
    await _persistQueueState();
    _persistTimer?.cancel();
    await _stateSub?.cancel();
    await _crossfadeSub?.cancel();
    return super.close();
  }
}
