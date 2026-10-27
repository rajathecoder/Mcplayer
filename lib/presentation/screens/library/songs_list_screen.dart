import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/di/injector.dart';
import '../../../core/media/media_store_delete_service.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/datasources/local/songs_local_datasource.dart';
import '../../../domain/entities/song.dart';
import '../../bloc/favorites/favorites_cubit.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/playback/playback_cubit.dart';
import '../../bloc/playlist/playlists_cubit.dart';
import '../../widgets/song_artwork.dart';
import '../../widgets/song_options_sheet.dart';
import '../search/search_screen.dart';

enum SongSortField { title, artist, album, duration, dateAdded }

const _kSortField = 'songs.sortField';
const _kSortAsc = 'songs.sortAsc';

class SongsListScreen extends StatefulWidget {
  const SongsListScreen({super.key});

  @override
  State<SongsListScreen> createState() => _SongsListScreenState();
}

class _SongsListScreenState extends State<SongsListScreen> {
  SongSortField _sortField = SongSortField.title;
  bool _ascending = true;
  final Set<String> _selected = {};

  bool get _selecting => _selected.isNotEmpty;

  void _toggleSelection(Song song) {
    setState(() {
      if (!_selected.remove(song.path)) _selected.add(song.path);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSortPrefs();
  }

  Future<void> _loadSortPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortField = SongSortField.values[prefs.getInt(_kSortField) ?? 0];
      _ascending = prefs.getBool(_kSortAsc) ?? true;
    });
  }

  Future<void> _setSort(SongSortField field) async {
    final prefs = await SharedPreferences.getInstance();
    final ascending = field == _sortField ? !_ascending : true;
    await prefs.setInt(_kSortField, field.index);
    await prefs.setBool(_kSortAsc, ascending);
    setState(() {
      _sortField = field;
      _ascending = ascending;
    });
  }

  List<Song> _sorted(List<Song> songs) {
    final sorted = [...songs];
    int compare(Song a, Song b) {
      switch (_sortField) {
        case SongSortField.title:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SongSortField.artist:
          return (a.artist ?? '').toLowerCase().compareTo((b.artist ?? '').toLowerCase());
        case SongSortField.album:
          return (a.album ?? '').toLowerCase().compareTo((b.album ?? '').toLowerCase());
        case SongSortField.duration:
          return a.durationMs.compareTo(b.durationMs);
        case SongSortField.dateAdded:
          return (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0);
      }
    }

    sorted.sort(compare);
    if (!_ascending) return sorted.reversed.toList();
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selecting ? _buildSelectionAppBar() : _buildNormalAppBar(context),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state.status == LibraryStatus.loading || state.status == LibraryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.songs.isEmpty) {
            return const Center(child: Text('No songs found'));
          }
          final songs = _sorted(state.songs);
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final isSelected = _selected.contains(song.path);
              return ListTile(
                selected: isSelected,
                leading: _selecting
                    ? Checkbox(value: isSelected, onChanged: (_) => _toggleSelection(song))
                    : SongArtwork(mediaId: song.mediaId),
                title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  song.artist ?? 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: _selecting
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BlocBuilder<FavoritesCubit, Set<String>>(
                            builder: (context, favorites) {
                              final isFav = favorites.contains(song.path);
                              return IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isFav ? Colors.redAccent : null,
                                ),
                                onPressed: () => context.read<FavoritesCubit>().toggle(song),
                              );
                            },
                          ),
                          Text(formatDuration(song.duration)),
                        ],
                      ),
                onTap: _selecting
                    ? () => _toggleSelection(song)
                    : () => context.read<PlaybackCubit>().playQueue(songs, startIndex: index),
                onLongPress: _selecting ? null : () => _toggleSelection(song),
              );
            },
          );
        },
      ),
    );
  }

  AppBar _buildNormalAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Songs'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
        ),
        PopupMenuButton<SongSortField>(
          icon: const Icon(Icons.sort_rounded),
          onSelected: _setSort,
          itemBuilder: (context) => const [
            PopupMenuItem(value: SongSortField.title, child: Text('Title')),
            PopupMenuItem(value: SongSortField.artist, child: Text('Artist')),
            PopupMenuItem(value: SongSortField.album, child: Text('Album')),
            PopupMenuItem(value: SongSortField.duration, child: Text('Duration')),
            PopupMenuItem(value: SongSortField.dateAdded, child: Text('Date added')),
          ],
        ),
      ],
    );
  }

  AppBar _buildSelectionAppBar() {
    final state = context.watch<LibraryBloc>().state;
    final selectedSongs = state.songs.where((s) => _selected.contains(s.path)).toList();

    return AppBar(
      leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(_selected.clear)),
      title: Text('${_selected.length} selected'),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all_rounded),
          tooltip: 'Select all',
          onPressed: () => setState(() => _selected.addAll(state.songs.map((s) => s.path))),
        ),
        IconButton(
          icon: const Icon(Icons.queue_music_rounded),
          tooltip: 'Add to queue',
          onPressed: () async {
            final playback = context.read<PlaybackCubit>();
            for (final song in selectedSongs) {
              await playback.addToQueue(song);
            }
            setState(_selected.clear);
          },
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border_rounded),
          tooltip: 'Add to favorites',
          onPressed: () async {
            final favorites = context.read<FavoritesCubit>();
            for (final song in selectedSongs) {
              if (!favorites.isFavorite(song.path)) await favorites.toggle(song);
            }
            setState(_selected.clear);
          },
        ),
        IconButton(
          icon: const Icon(Icons.playlist_add_rounded),
          tooltip: 'Add to playlist',
          onPressed: () => _batchAddToPlaylist(selectedSongs),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: 'Delete',
          onPressed: () => _batchDelete(selectedSongs),
        ),
      ],
    );
  }

  Future<void> _batchAddToPlaylist(List<Song> songs) async {
    final playlistsCubit = context.read<PlaylistsCubit>();
    final playlist = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final playlist in playlistsCubit.state)
              ListTile(
                title: Text(playlist.title),
                onTap: () => Navigator.pop(context, playlist.id),
              ),
          ],
        ),
      ),
    );
    if (playlist == null) return;
    for (final song in songs) {
      await playlistsCubit.addSongToPlaylist(playlist, song.path);
    }
    setState(_selected.clear);
  }

  Future<void> _batchDelete(List<Song> songs) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${songs.length} songs?'),
        content: const Text('They will be permanently deleted from your device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final mediaIds = songs.map((s) => s.mediaId).whereType<int>().toList();
    final deleted = await getIt<MediaStoreDeleteService>().deleteByMediaIds(mediaIds);
    if (!mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete cancelled')));
      return;
    }

    for (final song in songs) {
      await getIt<SongsLocalDataSource>().deleteSong(song.path);
    }
    if (!mounted) return;
    setState(_selected.clear);
    context.read<LibraryBloc>().add(const LibraryLoadRequested());
  }
}
