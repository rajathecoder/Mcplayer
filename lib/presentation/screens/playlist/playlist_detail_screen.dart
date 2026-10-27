import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/playback/playback_cubit.dart';
import '../../bloc/playlist/playlists_cubit.dart';
import '../../widgets/song_artwork.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<Song>? _songs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final paths = await context.read<PlaylistsCubit>().getSongPaths(widget.playlist.id);
    final allSongs = context.read<LibraryBloc>().state.songs;
    final byPath = {for (final s in allSongs) s.path: s};
    final songs = paths.map((p) => byPath[p]).whereType<Song>().toList();
    if (!mounted) return;
    setState(() => _songs = songs);
  }

  @override
  Widget build(BuildContext context) {
    final songs = _songs;
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.title)),
      body: songs == null
          ? const Center(child: CircularProgressIndicator())
          : songs.isEmpty
              ? const Center(child: Text('This playlist is empty'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton.icon(
                        onPressed: () => context.read<PlaybackCubit>().playQueue(songs),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play All'),
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        itemCount: songs.length,
                        onReorder: (oldIndex, newIndex) async {
                          if (newIndex > oldIndex) newIndex -= 1;
                          await context.read<PlaylistsCubit>().reorderTracks(widget.playlist.id, oldIndex, newIndex);
                          setState(() {
                            final item = songs.removeAt(oldIndex);
                            songs.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return Dismissible(
                            key: ValueKey(song.path),
                            onDismissed: (_) async {
                              await context.read<PlaylistsCubit>().removeTrackAt(widget.playlist.id, index);
                              setState(() => songs.removeAt(index));
                            },
                            child: ListTile(
                              leading: SongArtwork(mediaId: song.mediaId),
                              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(song.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
                              onTap: () => context.read<PlaybackCubit>().playQueue(songs, startIndex: index),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
