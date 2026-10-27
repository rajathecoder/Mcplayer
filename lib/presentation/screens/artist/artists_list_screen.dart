import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/song.dart';
import '../../bloc/library/library_bloc.dart';
import '../search/search_screen.dart';
import 'artist_detail_screen.dart';

class ArtistGroup {
  final String artist;
  final List<Song> songs;

  ArtistGroup({required this.artist, required this.songs});

  int get albumCount => songs.map((s) => s.album ?? 'Unknown Album').toSet().length;
}

List<ArtistGroup> groupByArtist(List<Song> songs) {
  final map = <String, ArtistGroup>{};
  for (final song in songs) {
    final artist = song.artist ?? 'Unknown Artist';
    map.putIfAbsent(artist, () => ArtistGroup(artist: artist, songs: [])).songs.add(song);
  }
  final list = map.values.toList()..sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
  return list;
}

class ArtistsListScreen extends StatelessWidget {
  const ArtistsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artists'),
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
          final artists = groupByArtist(state.songs);
          if (artists.isEmpty) {
            return const Center(child: Text('No artists found'));
          }
          return ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
                title: Text(artist.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${artist.albumCount} albums • ${artist.songs.length} tracks'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ArtistDetailScreen(artist: artist)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
