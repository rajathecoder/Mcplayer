import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/playback/playback_cubit.dart';
import '../screens/player/now_playing_screen.dart';
import 'song_artwork.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaybackCubit, PlaybackUiState>(
      buildWhen: (prev, curr) =>
          prev.mediaItem?.id != curr.mediaItem?.id || prev.playing != curr.playing,
      builder: (context, state) {
        if (!state.hasTrack) return const SizedBox.shrink();

        final cubit = context.read<PlaybackCubit>();
        final item = state.mediaItem!;

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
          ),
          child: Material(
            elevation: 4,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniProgressBar(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          SongArtwork(
                            mediaId: item.extras?['mediaId'] as int?,
                            size: 40,
                            borderRadius: 20,
                            iconSize: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  item.artist ?? 'Unknown Artist',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            onPressed: cubit.togglePlayPause,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            onPressed: cubit.skipNext,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniProgressBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlaybackCubit>();
    final total = context.select<PlaybackCubit, Duration>(
      (c) => c.state.mediaItem?.duration ?? Duration.zero,
    );
    return StreamBuilder<Duration>(
      stream: cubit.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final progress = total.inMilliseconds > 0
            ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;
        return LinearProgressIndicator(
          value: progress,
          minHeight: 2,
          backgroundColor: Colors.transparent,
        );
      },
    );
  }
}
