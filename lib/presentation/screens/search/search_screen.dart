import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/format_utils.dart';
import '../../../domain/entities/song.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/playback/playback_cubit.dart';
import '../../widgets/song_artwork.dart';

const _kRecentSearches = 'search.recent';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<String> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _recent = prefs.getStringList(_kRecentSearches) ?? []);
  }

  Future<void> _saveRecent(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final updated = [query, ..._recent.where((r) => r != query)].take(10).toList();
    await prefs.setStringList(_kRecentSearches, updated);
    setState(() => _recent = updated);
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      setState(() => _query = value);
    });
  }

  List<Song> _filter(List<Song> songs) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return songs.where((s) {
      return s.title.toLowerCase().contains(q) ||
          (s.artist?.toLowerCase().contains(q) ?? false) ||
          (s.album?.toLowerCase().contains(q) ?? false) ||
          (s.genre?.toLowerCase().contains(q) ?? false) ||
          s.folderPath.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search songs, artists, albums...',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
          onSubmitted: _saveRecent,
        ),
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (_query.trim().isEmpty) {
            return _recent.isEmpty
                ? const Center(child: Text('Search your library'))
                : ListView(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Recent searches', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      for (final term in _recent)
                        ListTile(
                          leading: const Icon(Icons.history_rounded),
                          title: Text(term),
                          onTap: () {
                            _controller.text = term;
                            setState(() => _query = term);
                          },
                        ),
                    ],
                  );
          }

          final results = _filter(state.songs);
          if (results.isEmpty) {
            return const Center(child: Text('No results'));
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final song = results[index];
              return ListTile(
                leading: SongArtwork(mediaId: song.mediaId),
                title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Text(formatDuration(song.duration)),
                onTap: () {
                  _saveRecent(_query);
                  context.read<PlaybackCubit>().playQueue(results, startIndex: index);
                },
              );
            },
          );
        },
      ),
    );
  }
}
