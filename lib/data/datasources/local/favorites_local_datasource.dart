import 'package:sqflite/sqflite.dart';

import '../../db/app_database.dart';

class FavoritesLocalDataSource {
  Future<Database> get _db async => AppDatabase.instance;

  Future<Set<String>> getFavoritePaths() async {
    final db = await _db;
    final rows = await db.query('favorites', columns: ['song_path']);
    return rows.map((r) => r['song_path'] as String).toSet();
  }

  Future<bool> isFavorite(String path) async {
    final db = await _db;
    final rows = await db.query('favorites', where: 'song_path = ?', whereArgs: [path], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> addFavorite(String path, String title, String? artist) async {
    final db = await _db;
    await db.insert(
      'favorites',
      {
        'song_path': path,
        'title': title,
        'artist': artist,
        'date_added': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeFavorite(String path) async {
    final db = await _db;
    await db.delete('favorites', where: 'song_path = ?', whereArgs: [path]);
  }

  Future<List<String>> getFavoritePathsOrdered() async {
    final db = await _db;
    final rows = await db.query('favorites', orderBy: 'date_added DESC', columns: ['song_path']);
    return rows.map((r) => r['song_path'] as String).toList();
  }
}
