import 'dart:convert';
import 'dart:io';

import '../../data/datasources/local/eq_local_datasource.dart';
import '../../data/datasources/local/favorites_local_datasource.dart';
import '../../data/datasources/local/playlists_local_datasource.dart';

const int _schemaVersion = 2;

/// Exports/imports the user's favorites, playlists, and EQ presets as a single
/// JSON file (per the plan; kept unzipped for simplicity since it's already
/// small structured text — a zip wrapper adds no real benefit here).
class BackupService {
  final FavoritesLocalDataSource favorites;
  final PlaylistsLocalDataSource playlists;
  final EqLocalDataSource eq;

  BackupService({required this.favorites, required this.playlists, required this.eq});

  Future<Map<String, dynamic>> _buildExportMap() async {
    final favoritePaths = await favorites.getFavoritePathsOrdered();
    final playlistList = await playlists.getPlaylists();
    final playlistExports = <Map<String, dynamic>>[];
    for (final playlist in playlistList) {
      final paths = await playlists.getPlaylistSongPaths(playlist.id);
      playlistExports.add({
        'title': playlist.title,
        'description': playlist.description,
        'isPinned': playlist.isPinned,
        'songPaths': paths,
      });
    }
    final presets = await eq.getPresets();

    return {
      'schemaVersion': _schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'favorites': favoritePaths,
      'playlists': playlistExports,
      'eqPresets': presets
          .where((p) => !p.isBuiltin)
          .map((p) => {
                'name': p.name,
                'bandValues': p.bandValues,
                'bassBoost': p.bassBoost,
                'virtualizer': p.virtualizer,
              })
          .toList(),
    };
  }

  Future<File> exportToFile(String filePath) async {
    final data = await _buildExportMap();
    final file = File(filePath);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    return file;
  }

  Future<void> importFromFile(String filePath, {bool merge = true}) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;

    if (!merge) {
      // Replace mode: caller is responsible for clearing tables beforehand
      // via the repositories if a full wipe is desired.
    }

    for (final path in (data['favorites'] as List? ?? [])) {
      await favorites.addFavorite(path as String, path, null);
    }

    for (final playlistJson in (data['playlists'] as List? ?? [])) {
      final map = playlistJson as Map<String, dynamic>;
      final id = await playlists.createPlaylist(map['title'] as String, description: map['description'] as String?);
      for (final songPath in (map['songPaths'] as List? ?? [])) {
        await playlists.addTrack(id, songPath as String);
      }
    }

    for (final presetJson in (data['eqPresets'] as List? ?? [])) {
      final map = presetJson as Map<String, dynamic>;
      await eq.savePreset(
        map['name'] as String,
        (map['bandValues'] as List).cast<int>(),
        bassBoost: map['bassBoost'] as int? ?? 0,
        virtualizer: map['virtualizer'] as int? ?? 0,
      );
    }
  }
}
