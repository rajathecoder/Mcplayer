import '../../domain/repositories/queue_repository.dart';
import '../datasources/local/queue_local_datasource.dart';
import '../datasources/local/songs_local_datasource.dart';

class QueueRepositoryImpl implements QueueRepository {
  final QueueLocalDataSource _queueLocal;
  final SongsLocalDataSource _songsLocal;

  QueueRepositoryImpl(this._queueLocal, this._songsLocal);

  @override
  Future<void> saveQueue(List<String> songPaths, int currentIndex, Duration position) {
    return _queueLocal.saveQueue(songPaths, currentIndex, position.inMilliseconds);
  }

  @override
  Future<RestoredQueue?> restoreQueue() async {
    final snapshot = await _queueLocal.loadQueue();
    if (snapshot == null) return null;

    final songs = await _songsLocal.getSongsByPaths(snapshot.paths);
    if (songs.isEmpty) return null;

    final clampedIndex = snapshot.currentIndex.clamp(0, songs.length - 1);
    return RestoredQueue(
      songs: songs,
      currentIndex: clampedIndex,
      position: Duration(milliseconds: snapshot.positionMs),
    );
  }

  @override
  Future<void> clearQueue() => _queueLocal.clearQueue();
}
