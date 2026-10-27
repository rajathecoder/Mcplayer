import 'package:sqflite/sqflite.dart';

import '../../db/app_database.dart';

class TopStatRow {
  final String label;
  final int value;
  TopStatRow(this.label, this.value);
}

class StatsLocalDataSource {
  Future<Database> get _db async => AppDatabase.instance;

  Future<void> recordPlay(String songPath, {required int listenedMs}) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      final existing = await txn.query('playback_stats', where: 'song_path = ?', whereArgs: [songPath]);
      if (existing.isEmpty) {
        await txn.insert('playback_stats', {
          'song_path': songPath,
          'play_count': 1,
          'skip_count': 0,
          'total_play_ms': listenedMs,
          'last_played': now,
        });
      } else {
        await txn.rawUpdate(
          'UPDATE playback_stats SET play_count = play_count + 1, total_play_ms = total_play_ms + ?, last_played = ? WHERE song_path = ?',
          [listenedMs, now, songPath],
        );
      }
      await txn.insert('play_history', {
        'song_path': songPath,
        'played_at': now,
        'duration_listened_ms': listenedMs,
      });
    });
  }

  Future<void> recordSkip(String songPath) async {
    final db = await _db;
    final existing = await db.query('playback_stats', where: 'song_path = ?', whereArgs: [songPath]);
    if (existing.isEmpty) {
      await db.insert('playback_stats', {'song_path': songPath, 'skip_count': 1});
    } else {
      await db.rawUpdate('UPDATE playback_stats SET skip_count = skip_count + 1 WHERE song_path = ?', [songPath]);
    }
  }

  Future<List<String>> mostPlayedPaths({int limit = 100}) async {
    final db = await _db;
    final rows = await db.query('playback_stats',
        orderBy: 'play_count DESC', limit: limit, where: 'play_count > 0');
    return rows.map((r) => r['song_path'] as String).toList();
  }

  Future<List<String>> recentlyPlayedPaths({int limit = 50}) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT song_path, MAX(played_at) as last FROM play_history GROUP BY song_path ORDER BY last DESC LIMIT ?',
      [limit],
    );
    return rows.map((r) => r['song_path'] as String).toList();
  }

  Future<Set<String>> everPlayedPaths() async {
    final db = await _db;
    final rows = await db.query('playback_stats', columns: ['song_path'], where: 'play_count > 0');
    return rows.map((r) => r['song_path'] as String).toSet();
  }

  Future<int> totalListeningMs() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT SUM(total_play_ms) as total FROM playback_stats');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> totalPlays() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT SUM(play_count) as total FROM playback_stats');
    return (result.first['total'] as int?) ?? 0;
  }
}
