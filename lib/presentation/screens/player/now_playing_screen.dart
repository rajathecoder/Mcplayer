import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/format_utils.dart';
import '../../../domain/entities/song.dart';
import '../../bloc/favorites/favorites_cubit.dart';
import '../../bloc/playback/playback_cubit.dart';
import '../../widgets/song_artwork.dart';
import '../../widgets/song_options_sheet.dart';
import '../../widgets/sleep_timer_sheet.dart';
import '../lyrics/lyrics_screen.dart';
import '../queue/queue_screen.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QueueScreen()),
            ),
          ),
        ],
      ),
      body: BlocBuilder<PlaybackCubit, PlaybackUiState>(
        builder: (context, state) {
          if (!state.hasTrack) {
            return const Center(child: Text('Nothing is playing'));
          }
          final item = state.mediaItem!;
          final cubit = context.read<PlaybackCubit>();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SongArtwork(
                        mediaId: item.extras?['mediaId'] as int?,
                        size: 260,
                        borderRadius: 24,
                        iconSize: 96,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.artist ?? 'Unknown Artist',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 8),
                      BlocBuilder<FavoritesCubit, Set<String>>(
                        builder: (context, favorites) {
                          final isFav = favorites.contains(item.id);
                          return IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? Colors.redAccent : null,
                            ),
                            onPressed: () => context.read<FavoritesCubit>().toggle(_songFromMediaItem(item)),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SeekBar(duration: item.duration ?? Duration.zero),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: state.shuffleMode == AudioServiceShuffleMode.none
                              ? null
                              : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: cubit.toggleShuffle,
                      ),
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_previous_rounded),
                        onPressed: cubit.skipPrevious,
                      ),
                      IconButton(
                        iconSize: 64,
                        icon: Icon(state.playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded),
                        onPressed: cubit.togglePlayPause,
                      ),
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed: cubit.skipNext,
                      ),
                      IconButton(
                        icon: Icon(
                          switch (state.repeatMode) {
                            AudioServiceRepeatMode.one => Icons.repeat_one_rounded,
                            _ => Icons.repeat_rounded,
                          },
                          color: state.repeatMode == AudioServiceRepeatMode.none
                              ? null
                              : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: cubit.cycleRepeatMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.speed_rounded),
                        tooltip: 'Playback speed',
                        onPressed: () => _showSpeedSheet(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bedtime_rounded),
                        tooltip: 'Sleep timer',
                        onPressed: () => showSleepTimerSheet(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.lyrics_outlined),
                        tooltip: 'Lyrics',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LyricsScreen()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        tooltip: 'More',
                        onPressed: () => showSongOptionsSheet(context, _songFromMediaItem(item)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Song _songFromMediaItem(MediaItem item) {
    return Song(
      path: item.id,
      folderPath: (item.extras?['folderPath'] as String?) ?? '',
      mediaId: item.extras?['mediaId'] as int?,
      title: item.title,
      artist: item.artist,
      album: item.album,
      durationMs: item.duration?.inMilliseconds ?? 0,
    );
  }

  void _showSpeedSheet(BuildContext context) {
    final cubit = context.read<PlaybackCubit>();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            for (final speed in [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0])
              ListTile(
                title: Text('${speed}x'),
                onTap: () {
                  cubit.setSpeed(speed);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SeekBar extends StatefulWidget {
  final Duration duration;

  const _SeekBar({required this.duration});

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlaybackCubit>();
    return StreamBuilder<Duration>(
      stream: cubit.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final maxMs = widget.duration.inMilliseconds.toDouble();
        final value = _dragValue ?? position.inMilliseconds.toDouble().clamp(0.0, maxMs <= 0 ? 1.0 : maxMs);

        return Column(
          children: [
            Slider(
              value: maxMs <= 0 ? 0.0 : value,
              max: maxMs <= 0 ? 1.0 : maxMs,
              onChanged: maxMs <= 0 ? null : (v) => setState(() => _dragValue = v),
              onChangeEnd: (v) {
                cubit.seek(Duration(milliseconds: v.round()));
                setState(() => _dragValue = null);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(position)),
                  Text(formatDuration(widget.duration)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
