part of 'playback_cubit.dart';

class PlaybackUiState extends Equatable {
  final MediaItem? mediaItem;
  final List<MediaItem> queue;
  final int currentIndex;
  final bool playing;
  final Duration bufferedPosition;
  final AudioServiceRepeatMode repeatMode;
  final AudioServiceShuffleMode shuffleMode;
  final AudioProcessingState processingState;

  const PlaybackUiState({
    this.mediaItem,
    this.queue = const [],
    this.currentIndex = -1,
    this.playing = false,
    this.bufferedPosition = Duration.zero,
    this.repeatMode = AudioServiceRepeatMode.none,
    this.shuffleMode = AudioServiceShuffleMode.none,
    this.processingState = AudioProcessingState.idle,
  });

  bool get hasTrack => mediaItem != null;

  PlaybackUiState copyWith({
    MediaItem? mediaItem,
    List<MediaItem>? queue,
    int? currentIndex,
    bool? playing,
    Duration? bufferedPosition,
    AudioServiceRepeatMode? repeatMode,
    AudioServiceShuffleMode? shuffleMode,
    AudioProcessingState? processingState,
  }) {
    return PlaybackUiState(
      mediaItem: mediaItem ?? this.mediaItem,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      playing: playing ?? this.playing,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      processingState: processingState ?? this.processingState,
    );
  }

  @override
  List<Object?> get props => [
        mediaItem,
        queue,
        currentIndex,
        playing,
        bufferedPosition,
        repeatMode,
        shuffleMode,
        processingState,
      ];
}
