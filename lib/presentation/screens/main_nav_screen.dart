import 'package:flutter/material.dart';

import '../widgets/mini_player.dart';
import 'album/albums_list_screen.dart';
import 'artist/artists_list_screen.dart';
import 'folder/folder_list_screen.dart';
import 'library/songs_list_screen.dart';
import 'playlist/playlists_screen.dart';
import 'settings/settings_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;

  static const _tabs = [
    (icon: Icons.folder_rounded, label: 'Folders'),
    (icon: Icons.music_note_rounded, label: 'Songs'),
    (icon: Icons.album_rounded, label: 'Albums'),
    (icon: Icons.person_rounded, label: 'Artists'),
    (icon: Icons.playlist_play_rounded, label: 'Playlists'),
    (icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          FolderListScreen(),
          SongsListScreen(),
          AlbumsListScreen(),
          ArtistsListScreen(),
          PlaylistsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              for (final tab in _tabs) NavigationDestination(icon: Icon(tab.icon), label: tab.label),
            ],
          ),
        ],
      ),
    );
  }
}
