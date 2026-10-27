import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/format_utils.dart';
import '../../bloc/playback/playback_cubit.dart';
import '../../widgets/song_artwork.dart';
import 'artists_list_screen.dart';

class ArtistDetailScreen extends StatelessWidget {
  final ArtistGroup artist;

  const ArtistDetailScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final byAlbum = <String, List<int>>{};
    for (var i = 0; i < artist.songs.length; i++) {
      byAlbum.putIfAbsent(artist.songs[i].album ?? 'Unknown Album', () => []).add(i);
    }

    return Scaffold(
      appBar: AppBar(title: Text(artist.artist)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => context.read<PlaybackCubit>().playQueue(artist.songs),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('Play all ${artist.songs.length} tracks'),
            ),
          ),
          for (final entry in byAlbum.entries) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final i in entry.value)
              ListTile(
                leading: SongArtwork(mediaId: artist.songs[i].mediaId),
                title: Text(artist.songs[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(formatDuration(artist.songs[i].duration)),
                onTap: () => context.read<PlaybackCubit>().playQueue(artist.songs, startIndex: i),
              ),
          ],
        ],
      ),
    );
  }
}
