import 'package:path/path.dart' as p;

import '../../domain/entities/folder.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/library_repository.dart';
import '../datasources/local/songs_local_datasource.dart';
import '../datasources/media/media_scanner.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final MediaScanner _scanner;
  final SongsLocalDataSource _local;

  LibraryRepositoryImpl(this._scanner, this._local);

  @override
  Future<List<Song>> getAllSongs() => _local.getAllSongs();

  @override
  Future<List<Song>> getSongsInFolder(String folderPath, {bool includeSubfolders = false}) {
    return _local.getSongsInFolder(folderPath, includeSubfolders: includeSubfolders);
  }

  @override
  Future<List<Song>> rescanLibrary() async {
    final scanned = await _scanner.scanLibrary();
    await _local.syncSongs(scanned);
    return _local.getAllSongs();
  }

  @override
  Future<List<MusicFolder>> getFolders() async {
    final songs = await _local.getAllSongs();
    final grouped = <String, List<Song>>{};
    for (final song in songs) {
      grouped.putIfAbsent(song.folderPath, () => []).add(song);
    }

    return grouped.entries.map((entry) {
      final tracks = entry.value;
      final totalDuration = tracks.fold<int>(0, (sum, s) => sum + s.durationMs);
      final totalSize = tracks.fold<int>(0, (sum, s) => sum + (s.sizeBytes ?? 0));
      return MusicFolder(
        path: entry.key,
        name: p.basename(entry.key),
        trackCount: tracks.length,
        totalDurationMs: totalDuration,
        totalSizeBytes: totalSize,
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}
