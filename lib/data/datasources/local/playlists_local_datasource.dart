import 'package:sqflite/sqflite.dart';

import '../../db/app_database.dart';
import '../../../domain/entities/playlist.dart';

class PlaylistsLocalDataSource {
  Future<Database> get _db async => AppDatabase.instance;

  Future<List<Playlist>> getPlaylists() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT p.*, COUNT(pt.id) as track_count
      FROM playlists p
      LEFT JOIN playlist_tracks pt ON pt.playlist_id = p.id
      GROUP BY p.id
      ORDER BY p.is_pinned DESC, p.updated_at DESC
    ''');
    return rows.map(_fromRow).toList();
  }

  Playlist _fromRow(Map<String, dynamic> row) => Playlist(
        id: row['id'] as int,
        title: row['title'] as String,
        description: row['description'] as String?,
        coverPath: row['cover_path'] as String?,
        isPinned: (row['is_pinned'] as int? ?? 0) == 1,
        createdAt: row['created_at'] as int,
        updatedAt: row['updated_at'] as int,
        trackCount: (row['track_count'] as int?) ?? 0,
      );

  Future<int> createPlaylist(String title, {String? description}) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert('playlists', {
      'title': title,
      'description': description,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> renamePlaylist(int id, String title) async {
    final db = await _db;
    await db.update(
      'playlists',
      {'title': title, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePlaylist(int id) async {
    final db = await _db;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setPinned(int id, bool pinned) async {
    final db = await _db;
    await db.update('playlists', {'is_pinned': pinned ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getPlaylistSongPaths(int playlistId) async {
    final db = await _db;
    final rows = await db.query(
      'playlist_tracks',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'track_order',
    );
    return rows.map((r) => r['song_path'] as String).toList();
  }

  Future<void> addTrack(int playlistId, String songPath) async {
    final db = await _db;
    final countResult = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM playlist_tracks WHERE playlist_id = ?', [playlistId]),
    );
    await db.insert('playlist_tracks', {
      'playlist_id': playlistId,
      'song_path': songPath,
      'track_order': countResult ?? 0,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    });
    await db.update('playlists', {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?', whereArgs: [playlistId]);
  }

  Future<void> removeTrackAt(int playlistId, int order) async {
    final db = await _db;
    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ? AND track_order = ?',
      whereArgs: [playlistId, order],
    );
    await _resequence(db, playlistId);
  }

  Future<void> reorderTracks(int playlistId, int oldIndex, int newIndex) async {
    final db = await _db;
    final rows = await db.query(
      'playlist_tracks',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'track_order',
    );
    final ids = rows.map((r) => r['id'] as int).toList();
    final movedId = ids.removeAt(oldIndex);
    ids.insert(newIndex, movedId);

    final batch = db.batch();
    for (var i = 0; i < ids.length; i++) {
      batch.update('playlist_tracks', {'track_order': i}, where: 'id = ?', whereArgs: [ids[i]]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> _resequence(Database db, int playlistId) async {
    final rows = await db.query(
      'playlist_tracks',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'track_order',
    );
    final batch = db.batch();
    for (var i = 0; i < rows.length; i++) {
      batch.update('playlist_tracks', {'track_order': i}, where: 'id = ?', whereArgs: [rows[i]['id']]);
    }
    await batch.commit(noResult: true);
  }
}
