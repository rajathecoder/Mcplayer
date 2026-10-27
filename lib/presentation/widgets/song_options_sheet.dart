import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/di/injector.dart';
import '../../core/media/media_store_delete_service.dart';
import '../../core/utils/format_utils.dart';
import '../../data/datasources/local/songs_local_datasource.dart';
import '../../domain/entities/song.dart';
import '../bloc/favorites/favorites_cubit.dart';
import '../bloc/playback/playback_cubit.dart';
import '../bloc/playlist/playlists_cubit.dart';
import '../screens/tag_editor/tag_editor_screen.dart';
import 'song_artwork.dart';

Future<void> showSongOptionsSheet(BuildContext context, Song song, {VoidCallback? onDeleted}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _SongOptionsSheet(song: song, onDeleted: onDeleted),
  );
}

class _SongOptionsSheet extends StatelessWidget {
  final Song song;
  final VoidCallback? onDeleted;

  const _SongOptionsSheet({required this.song, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final playback = context.read<PlaybackCubit>();
    final favorites = context.read<FavoritesCubit>();
    final isFav = context.watch<FavoritesCubit>().isFavorite(song.path);

    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: SongArtwork(mediaId: song.mediaId),
            title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(song.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? Colors.redAccent : null),
            title: Text(isFav ? 'Remove from favorites' : 'Add to favorites'),
            onTap: () {
              favorites.toggle(song);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_play_rounded),
            title: const Text('Play next'),
            onTap: () {
              playback.playNext(song);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music_rounded),
            title: const Text('Add to queue'),
            onTap: () {
              playback.addToQueue(song);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded),
            title: const Text('Add to playlist'),
            onTap: () async {
              Navigator.pop(context);
              await _showAddToPlaylistDialog(context, song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Song info'),
            onTap: () {
              Navigator.pop(context);
              _showInfoDialog(context, song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: const Text('Edit tags'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => TagEditorScreen(song: song)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              Share.shareXFiles([XFile(song.path)], text: song.title);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_open_rounded),
            title: const Text('Show in folder'),
            subtitle: Text(song.folderPath, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
            title: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () async {
              Navigator.pop(context);
              await _confirmAndDelete(context, song);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddToPlaylistDialog(BuildContext context, Song song) async {
    final playlistsCubit = context.read<PlaylistsCubit>();
    final playlists = playlistsCubit.state;

    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('New playlist'),
              onTap: () async {
                Navigator.pop(context);
                final controller = TextEditingController();
                final name = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('New playlist'),
                    content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
                    ],
                  ),
                );
                if (name == null || name.isEmpty) return;
                await playlistsCubit.createPlaylist(name);
                final created = playlistsCubit.state.firstWhere((p) => p.title == name);
                await playlistsCubit.addSongToPlaylist(created.id, song.path);
              },
            ),
            const Divider(height: 1),
            for (final playlist in playlists)
              ListTile(
                leading: const Icon(Icons.playlist_play_rounded),
                title: Text(playlist.title),
                subtitle: Text('${playlist.trackCount} tracks'),
                onTap: () async {
                  Navigator.pop(context);
                  await playlistsCubit.addSongToPlaylist(playlist.id, song.path);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Song info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow('Title', song.title),
              _infoRow('Artist', song.artist ?? 'Unknown'),
              _infoRow('Album', song.album ?? 'Unknown'),
              _infoRow('Genre', song.genre ?? '-'),
              _infoRow('Year', song.year?.toString() ?? '-'),
              _infoRow('Duration', formatDuration(song.duration)),
              _infoRow('Bitrate', song.bitrate != null ? '${song.bitrate} bps' : '-'),
              _infoRow('Sample rate', song.sampleRate != null ? '${song.sampleRate} Hz' : '-'),
              _infoRow('File size', song.sizeBytes != null ? formatFileSize(song.sizeBytes!) : '-'),
              _infoRow('Format', song.mimeType ?? '-'),
              _infoRow('Path', song.path),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: song.path));
              Navigator.pop(context);
            },
            child: const Text('Copy path'),
          ),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Future<void> _confirmAndDelete(BuildContext context, Song song) async {
    if (song.mediaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This track can\'t be deleted (no media id).')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete song?'),
        content: Text('${song.title} will be permanently deleted from your device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deleted = await getIt<MediaStoreDeleteService>().deleteByMediaIds([song.mediaId!]);
    if (!deleted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete cancelled')));
      }
      return;
    }

    await getIt<SongsLocalDataSource>().deleteSong(song.path);
    onDeleted?.call();
  }
}
