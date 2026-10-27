import 'package:sqflite/sqflite.dart';

import '../../db/app_database.dart';
import '../../models/song_model.dart';

class SongsLocalDataSource {
  Future<Database> get _db async => AppDatabase.instance;

  Future<List<SongModel>> getAllSongs() async {
    final db = await _db;
    final rows = await db.query('songs_cache', where: 'is_missing = 0', orderBy: 'title COLLATE NOCASE');
    return rows.map(SongModel.fromMap).toList();
  }

  Future<List<SongModel>> getSongsInFolder(String folderPath, {bool includeSubfolders = false}) async {
    final db = await _db;
    final where = includeSubfolders ? 'folder_path LIKE ? AND is_missing = 0' : 'folder_path = ? AND is_missing = 0';
    final whereArgs = includeSubfolders ? ['$folderPath%'] : [folderPath];
    final rows = await db.query('songs_cache', where: where, whereArgs: whereArgs, orderBy: 'title COLLATE NOCASE');
    return rows.map(SongModel.fromMap).toList();
  }

  Future<List<SongModel>> getSongsByPaths(List<String> paths) async {
    if (paths.isEmpty) return [];
    final db = await _db;
    final placeholders = List.filled(paths.length, '?').join(',');
    final rows = await db.query('songs_cache', where: 'song_path IN ($placeholders)', whereArgs: paths);
    final byPath = {for (final row in rows) row['song_path'] as String: SongModel.fromMap(row)};
    return paths.map((p) => byPath[p]).whereType<SongModel>().toList();
  }

  Future<Map<String, int>> getPathModifiedMap() async {
    final db = await _db;
    final rows = await db.query('songs_cache', columns: ['song_path', 'date_modified']);
    return {
      for (final row in rows) row['song_path'] as String: (row['date_modified'] as int?) ?? 0,
    };
  }

  /// Applies an incremental diff: upserts [songs], marks paths not present as missing,
  /// and removes stale "missing" rows older than the scan set.
  Future<void> syncSongs(List<SongModel> songs) async {
    final db = await _db;
    final incomingPaths = songs.map((s) => s.path).toSet();

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final song in songs) {
        batch.insert(
          'songs_cache',
          song.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);

      final existing = await txn.query('songs_cache', columns: ['song_path']);
      final existingPaths = existing.map((r) => r['song_path'] as String).toSet();
      final missingPaths = existingPaths.difference(incomingPaths);

      if (missingPaths.isNotEmpty) {
        final placeholders = List.filled(missingPaths.length, '?').join(',');
        await txn.update(
          'songs_cache',
          {'is_missing': 1},
          where: 'song_path IN ($placeholders)',
          whereArgs: missingPaths.toList(),
        );
      }
    });
  }

  Future<void> deleteSong(String path) async {
    final db = await _db;
    await db.delete('songs_cache', where: 'song_path = ?', whereArgs: [path]);
  }

  Future<void> updateMetadata(
    String path, {
    required String title,
    String? artist,
    String? album,
    String? albumArtist,
    String? genre,
    int? year,
    int? trackNo,
  }) async {
    final db = await _db;
    await db.update(
      'songs_cache',
      {
        'title': title,
        'artist': artist,
        'album': album,
        'album_artist': albumArtist,
        'genre': genre,
        'year': year,
        'track_no': trackNo,
      },
      where: 'song_path = ?',
      whereArgs: [path],
    );
  }
}
