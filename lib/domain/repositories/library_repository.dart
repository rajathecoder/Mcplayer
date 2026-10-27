import '../entities/folder.dart';
import '../entities/song.dart';

abstract class LibraryRepository {
  Future<List<Song>> getAllSongs();

  Future<List<Song>> getSongsInFolder(String folderPath, {bool includeSubfolders = false});

  Future<List<MusicFolder>> getFolders();

  /// Rescans the device media store and syncs the local cache.
  /// Returns the freshly synced song list.
  Future<List<Song>> rescanLibrary();
}
