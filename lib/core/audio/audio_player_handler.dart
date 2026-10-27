import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/entities/song.dart';

/// Bridges just_audio's [AudioPlayer] to audio_service's [BaseAudioHandler],
/// giving us background playback, lockscreen controls, media notification,
/// and audio-focus/headset handling for free.
class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AndroidEqualizer equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer loudnessEnhancer = AndroidLoudnessEnhancer();
  late final AudioPlayer player;
  ConcatenatingAudioSource? _playlist;

  AudioPlayerHandler() {
    player = AudioPlayer(
      audioPipeline: AudioPipeline(androidAudioEffects: [loudnessEnhancer, equalizer]),
    );
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await loudnessEnhancer.setEnabled(false);
    await loudnessEnhancer.setTargetGain(0);

    // Using .listen(playbackState.add) rather than .pipe() — pipe() calls
    // addStream() under the hood, which takes an exclusive lock on the
    // controller and throws if anything else (the shuffle/loop listeners
    // below) calls .add() on it concurrently.
    player.playbackEventStream.map(_transformEvent).listen(playbackState.add);

    player.currentIndexStream.listen((index) {
      final currentQueue = queue.value;
      if (index != null && index >= 0 && index < currentQueue.length) {
        mediaItem.add(currentQueue[index]);
      }
    });

    player.shuffleModeEnabledStream.listen((enabled) {
      playbackState.add(playbackState.value.copyWith(
        shuffleMode: enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      ));
    });

    player.loopModeStream.listen((loopMode) {
      playbackState.add(playbackState.value.copyWith(repeatMode: _loopModeToRepeatMode(loopMode)));
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
      shuffleMode: player.shuffleModeEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      repeatMode: _loopModeToRepeatMode(player.loopMode),
    );
  }

  AudioServiceRepeatMode _loopModeToRepeatMode(LoopMode loopMode) {
    switch (loopMode) {
      case LoopMode.off:
        return AudioServiceRepeatMode.none;
      case LoopMode.one:
        return AudioServiceRepeatMode.one;
      case LoopMode.all:
        return AudioServiceRepeatMode.all;
    }
  }

  LoopMode _repeatModeToLoopMode(AudioServiceRepeatMode repeatMode) {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        return LoopMode.off;
      case AudioServiceRepeatMode.one:
        return LoopMode.one;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        return LoopMode.all;
    }
  }

  MediaItem songToMediaItem(Song song) => MediaItem(
        id: song.path,
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        album: song.album,
        duration: song.duration,
        extras: {'folderPath': song.folderPath, 'mediaId': song.mediaId},
      );

  UriAudioSource _songToAudioSource(Song song) =>
      AudioSource.uri(Uri.file(song.path), tag: songToMediaItem(song));

  /// Replaces the current queue with [songs] and starts playback at [initialIndex].
  Future<void> setQueue(
    List<Song> songs, {
    int initialIndex = 0,
    Duration initialPosition = Duration.zero,
    bool playImmediately = true,
  }) async {
    if (songs.isEmpty) return;
    _playlist = ConcatenatingAudioSource(children: songs.map(_songToAudioSource).toList());
    queue.add(songs.map(songToMediaItem).toList());
    await player.setAudioSource(
      _playlist!,
      initialIndex: initialIndex,
      initialPosition: initialPosition,
    );
    mediaItem.add(queue.value[initialIndex]);
    if (playImmediately) {
      await play();
    }
  }

  Future<void> addToQueueNext(Song song) async {
    final index = player.currentIndex ?? -1;
    await _playlist?.insert(index + 1, _songToAudioSource(song));
    final updated = List<MediaItem>.from(queue.value)..insert(index + 1, songToMediaItem(song));
    queue.add(updated);
  }

  Future<void> addToQueueEnd(Song song) async {
    await _playlist?.add(_songToAudioSource(song));
    queue.add(List<MediaItem>.from(queue.value)..add(songToMediaItem(song)));
  }

  Future<void> removeQueueItemAt(int index) async {
    await _playlist?.removeAt(index);
    queue.add(List<MediaItem>.from(queue.value)..removeAt(index));
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    await _playlist?.move(oldIndex, newIndex);
    final updated = List<MediaItem>.from(queue.value);
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    queue.add(updated);
  }

  Future<void> clearQueue() async {
    await player.stop();
    await _playlist?.clear();
    queue.add([]);
    mediaItem.add(null);
  }

  /// Regenerates the shuffle traversal order without changing the underlying queue order.
  Future<void> reshuffle() => player.shuffle();

  Stream<Duration> get positionStream => player.positionStream;

  int? get currentIndex => player.currentIndex;

  Future<void> setSkipSilenceEnabled(bool enabled) => player.setSkipSilenceEnabled(enabled);

  /// [boostPercent] 0-150; values above 100 use the loudness enhancer for extra gain.
  Future<void> setVolumeBoost(int boostPercent) async {
    final clamped = boostPercent.clamp(0, 150);
    if (clamped <= 100) {
      await loudnessEnhancer.setEnabled(false);
      await player.setVolume(clamped / 100);
    } else {
      await player.setVolume(1.0);
      await loudnessEnhancer.setEnabled(true);
      // Map 100-150% to 0-1000 millibels of extra gain.
      await loudnessEnhancer.setTargetGain((clamped - 100) / 50 * 10);
    }
  }

  Future<void> fadeVolumeTo(double target, Duration duration) async {
    const steps = 20;
    final start = player.volume;
    final stepDuration = duration ~/ steps;
    for (var i = 1; i <= steps; i++) {
      final v = start + (target - start) * (i / steps);
      await player.setVolume(v.clamp(0.0, 1.0));
      await Future.delayed(stepDuration);
    }
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() => player.seekToNext();

  @override
  Future<void> skipToPrevious() => player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) => player.seek(Duration.zero, index: index);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enable = shuffleMode != AudioServiceShuffleMode.none;
    if (enable) {
      await player.shuffle();
    }
    await player.setShuffleModeEnabled(enable);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) =>
      player.setLoopMode(_repeatModeToLoopMode(repeatMode));

  @override
  Future<void> setSpeed(double speed) => player.setSpeed(speed);

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }
}
