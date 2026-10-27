import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/datasources/local/stats_local_datasource.dart';
import '../../../domain/entities/song.dart';
import '../../bloc/favorites/favorites_cubit.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/playback/playback_cubit.dart';
import '../../widgets/song_artwork.dart';

enum SmartPlaylistKind { favorites, recentlyAdded, recentlyPlayed, mostPlayed, neverPlayed }

class SmartPlaylistScreen extends StatefulWidget {
  final SmartPlaylistKind kind;
  final String title;

  const SmartPlaylistScreen({super.key, required this.kind, required this.title});

  @override
  State<SmartPlaylistScreen> createState() => _SmartPlaylistScreenState();
}

class _SmartPlaylistScreenState extends State<SmartPlaylistScreen> {
  final _stats = getIt<StatsLocalDataSource>();
  List<Song>? _songs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final allSongs = context.read<LibraryBloc>().state.songs;
    final byPath = {for (final s in allSongs) s.path: s};
    List<Song> result;

    switch (widget.kind) {
      case SmartPlaylistKind.favorites:
        final paths = await context.read<FavoritesCubit>().favoritePathsOrdered();
        result = paths.map((p) => byPath[p]).whereType<Song>().toList();
      case SmartPlaylistKind.recentlyAdded:
        result = [...allSongs]..sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
        result = result.take(50).toList();
      case SmartPlaylistKind.recentlyPlayed:
        final paths = await _stats.recentlyPlayedPaths();
        result = paths.map((p) => byPath[p]).whereType<Song>().toList();
      case SmartPlaylistKind.mostPlayed:
        final paths = await _stats.mostPlayedPaths();
        result = paths.map((p) => byPath[p]).whereType<Song>().toList();
      case SmartPlaylistKind.neverPlayed:
        final played = await _stats.everPlayedPaths();
        result = allSongs.where((s) => !played.contains(s.path)).toList();
    }

    if (!mounted) return;
    setState(() => _songs = result);
  }

  @override
  Widget build(BuildContext context) {
    final songs = _songs;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: songs == null
          ? const Center(child: CircularProgressIndicator())
          : songs.isEmpty
              ? const Center(child: Text('Nothing here yet'))
              : ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      leading: SongArtwork(mediaId: song.mediaId),
                      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(song.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(formatDuration(song.duration)),
                      onTap: () => context.read<PlaybackCubit>().playQueue(songs, startIndex: index),
                    );
                  },
                ),
    );
  }
}
