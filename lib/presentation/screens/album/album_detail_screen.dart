import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/format_utils.dart';
import '../../bloc/playback/playback_cubit.dart';
import '../../widgets/song_artwork.dart';
import 'albums_list_screen.dart';

class AlbumDetailScreen extends StatelessWidget {
  final AlbumGroup album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final songs = [...album.songs]..sort((a, b) => (a.trackNo ?? 0).compareTo(b.trackNo ?? 0));

    return Scaffold(
      appBar: AppBar(title: Text(album.album)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: SongArtwork(
                mediaId: songs.isNotEmpty ? songs.first.mediaId : null,
                size: 160,
                borderRadius: 16,
                iconSize: 56,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.read<PlaybackCubit>().playQueue(songs),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final cubit = context.read<PlaybackCubit>();
                      await cubit.playQueue(songs);
                      await cubit.toggleShuffle();
                    },
                    icon: const Icon(Icons.shuffle_rounded),
                    label: const Text('Shuffle'),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < songs.length; i++)
            ListTile(
              leading: SizedBox(width: 32, child: Text('${songs[i].trackNo ?? i + 1}', textAlign: TextAlign.center)),
              title: Text(songs[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text(formatDuration(songs[i].duration)),
              onTap: () => context.read<PlaybackCubit>().playQueue(songs, startIndex: i),
            ),
        ],
      ),
    );
  }
}
