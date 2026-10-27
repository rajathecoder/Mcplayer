import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/playlist.dart';
import '../../bloc/playlist/playlists_cubit.dart';
import 'playlist_detail_screen.dart';
import 'smart_playlist_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _createPlaylist(context),
          ),
        ],
      ),
      body: BlocBuilder<PlaylistsCubit, List<Playlist>>(
        builder: (context, playlists) {
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
                title: const Text('Favorites'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SmartPlaylistScreen(kind: SmartPlaylistKind.favorites, title: 'Favorites'),
                )),
              ),
              ListTile(
                leading: const Icon(Icons.new_releases_rounded),
                title: const Text('Recently Added'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SmartPlaylistScreen(kind: SmartPlaylistKind.recentlyAdded, title: 'Recently Added'),
                )),
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Recently Played'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SmartPlaylistScreen(kind: SmartPlaylistKind.recentlyPlayed, title: 'Recently Played'),
                )),
              ),
              ListTile(
                leading: const Icon(Icons.trending_up_rounded),
                title: const Text('Most Played'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SmartPlaylistScreen(kind: SmartPlaylistKind.mostPlayed, title: 'Most Played'),
                )),
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off_rounded),
                title: const Text('Never Played'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SmartPlaylistScreen(kind: SmartPlaylistKind.neverPlayed, title: 'Never Played'),
                )),
              ),
              const Divider(),
              for (final playlist in playlists)
                ListTile(
                  leading: Icon(playlist.isPinned ? Icons.push_pin_rounded : Icons.playlist_play_rounded),
                  title: Text(playlist.title),
                  subtitle: Text('${playlist.trackCount} tracks'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist)),
                  ),
                  onLongPress: () => _showPlaylistMenu(context, playlist),
                ),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No custom playlists yet')),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    context.read<PlaylistsCubit>().createPlaylist(name);
  }

  void _showPlaylistMenu(BuildContext context, Playlist playlist) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(playlist.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded),
              title: Text(playlist.isPinned ? 'Unpin' : 'Pin to top'),
              onTap: () {
                context.read<PlaylistsCubit>().togglePinned(playlist);
                Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final controller = TextEditingController(text: playlist.title);
                final name = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Rename playlist'),
                    content: TextField(controller: controller),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
                    ],
                  ),
                );
                if (name != null && name.isNotEmpty && context.mounted) {
                  context.read<PlaylistsCubit>().rename(playlist.id, name);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.error),
              title: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                context.read<PlaylistsCubit>().delete(playlist.id);
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}
