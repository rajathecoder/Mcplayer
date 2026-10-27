import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/utils/format_utils.dart';
import '../../../domain/entities/folder.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/repositories/library_repository.dart';
import '../../bloc/playback/playback_cubit.dart';
import '../../widgets/song_artwork.dart';
import '../../widgets/song_options_sheet.dart';

class FolderDetailScreen extends StatefulWidget {
  final MusicFolder folder;

  const FolderDetailScreen({super.key, required this.folder});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  bool _includeSubfolders = false;
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _songsFuture = getIt<LibraryRepository>()
        .getSongsInFolder(widget.folder.path, includeSubfolders: _includeSubfolders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.folder.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.folder.trackCount} tracks • ${formatDuration(Duration(milliseconds: widget.folder.totalDurationMs))}',
                  ),
                ),
                const Text('Include subfolders'),
                Switch(
                  value: _includeSubfolders,
                  onChanged: (v) => setState(() {
                    _includeSubfolders = v;
                    _load();
                  }),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      final songs = await _songsFuture;
                      if (songs.isEmpty || !context.mounted) return;
                      context.read<PlaybackCubit>().playQueue(songs);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final songs = await _songsFuture;
                      if (songs.isEmpty || !context.mounted) return;
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
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Song>>(
              future: _songsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final songs = snapshot.data!;
                if (songs.isEmpty) {
                  return const Center(child: Text('No tracks in this folder'));
                }
                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      leading: SongArtwork(mediaId: song.mediaId),
                      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        song.artist ?? 'Unknown Artist',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(formatDuration(song.duration)),
                      onTap: () => context.read<PlaybackCubit>().playQueue(songs, startIndex: index),
                      onLongPress: () => showSongOptionsSheet(context, song, onDeleted: () {
                        setState(_load);
                      }),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
