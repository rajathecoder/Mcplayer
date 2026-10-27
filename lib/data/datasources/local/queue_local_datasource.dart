import 'package:sqflite/sqflite.dart';

import '../../db/app_database.dart';

class QueueSnapshotRow {
  final List<String> paths;
  final int currentIndex;
  final int positionMs;

  QueueSnapshotRow({required this.paths, required this.currentIndex, required this.positionMs});
}

class QueueLocalDataSource {
  Future<Database> get _db async => AppDatabase.instance;

  Future<void> saveQueue(List<String> paths, int currentIndex, int positionMs) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('queue_state');
      final batch = txn.batch();
      for (var i = 0; i < paths.length; i++) {
        batch.insert('queue_state', {
          'song_path': paths[i],
          'queue_order': i,
          'is_current': i == currentIndex ? 1 : 0,
          'position_ms': i == currentIndex ? positionMs : 0,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  Future<QueueSnapshotRow?> loadQueue() async {
    final db = await _db;
    final rows = await db.query('queue_state', orderBy: 'queue_order');
    if (rows.isEmpty) return null;

    final paths = rows.map((r) => r['song_path'] as String).toList();
    final currentIndex = rows.indexWhere((r) => (r['is_current'] as int) == 1);
    final positionMs = currentIndex >= 0 ? rows[currentIndex]['position_ms'] as int : 0;

    return QueueSnapshotRow(
      paths: paths,
      currentIndex: currentIndex < 0 ? 0 : currentIndex,
      positionMs: positionMs,
    );
  }

  Future<void> clearQueue() async {
    final db = await _db;
    await db.delete('queue_state');
  }
}
