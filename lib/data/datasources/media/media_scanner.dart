import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:path/path.dart' as p;

import '../../models/song_model.dart';

/// Wraps on_audio_query to scan the device's MediaStore for audio files.
class MediaScanner {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  static const supportedExtensions = {
    'mp3', 'm4a', 'aac', 'flac', 'wav', 'ogg', 'opus', 'wma', 'aiff', 'ape',
  };

  /// MediaStore columns are typed loosely by the OS and can arrive as either
  /// `int` or `String` depending on device/vendor — parse defensively.
  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<List<SongModel>> scanLibrary({
    int minDurationSeconds = 30,
    int minSizeBytes = 100 * 1024,
  }) async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
    );

    final result = <SongModel>[];
    for (final song in songs) {
      final durationMs = song.duration ?? 0;
      final sizeBytes = song.size;

      if (durationMs < minDurationSeconds * 1000) continue;
      if (sizeBytes < minSizeBytes) continue;

      final ext = p.extension(song.data).replaceFirst('.', '').toLowerCase();
      if (!supportedExtensions.contains(ext)) continue;

      result.add(SongModel(
        mediaId: song.id,
        path: song.data,
        folderPath: p.dirname(song.data),
        title: song.title.isNotEmpty ? song.title : p.basenameWithoutExtension(song.data),
        artist: (song.artist == null || song.artist == '<unknown>') ? null : song.artist,
        album: (song.album == null || song.album == '<unknown>') ? null : song.album,
        albumArtist: song.getMap['album_artist'] as String?,
        genre: song.genre,
        year: _asInt(song.getMap['year']),
        trackNo: _asInt(song.track),
        durationMs: durationMs,
        sizeBytes: sizeBytes,
        bitrate: _asInt(song.getMap['bitrate']),
        mimeType: song.fileExtension,
        dateAdded: song.dateAdded,
        dateModified: song.dateModified,
      ));
    }

    return result;
  }
}
