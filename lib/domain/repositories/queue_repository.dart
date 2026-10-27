import '../entities/song.dart';

class RestoredQueue {
  final List<Song> songs;
  final int currentIndex;
  final Duration position;

  RestoredQueue({required this.songs, required this.currentIndex, required this.position});
}

abstract class QueueRepository {
  Future<void> saveQueue(List<String> songPaths, int currentIndex, Duration position);

  Future<RestoredQueue?> restoreQueue();

  Future<void> clearQueue();
}
