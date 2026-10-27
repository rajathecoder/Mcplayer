import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/song.dart';
import '../../bloc/library/library_bloc.dart';
import '../search/search_screen.dart';
import 'album_detail_screen.dart';

class AlbumGroup {
  final String album;
  final String? artist;
  final List<Song> songs;

  AlbumGroup({required this.album, required this.artist, required this.songs});
}

List<AlbumGroup> groupByAlbum(List<Song> songs) {
  final map = <String, AlbumGroup>{};
  for (final song in songs) {
    final albumKey = song.album ?? 'Unknown Album';
    final artist = song.albumArtist ?? song.artist;
    final key = '$albumKey|${artist ?? ''}';
    map.putIfAbsent(key, () => AlbumGroup(album: albumKey, artist: artist, songs: [])).songs.add(song);
  }
  final list = map.values.toList()..sort((a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()));
  return list;
}

class AlbumsListScreen extends StatelessWidget {
  const AlbumsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state.status == LibraryStatus.loading || state.status == LibraryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          final albums = groupByAlbum(state.songs);
          if (albums.isEmpty) {
            return const Center(child: Text('No albums found'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AlbumDetailScreen(album: album)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.album_rounded, size: 48),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(album.album, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                    Text(album.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
