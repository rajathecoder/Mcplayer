import '../../domain/entities/song.dart';

class SongModel extends Song {
  const SongModel({
    super.id,
    super.mediaId,
    required super.path,
    required super.folderPath,
    required super.title,
    super.artist,
    super.album,
    super.albumArtist,
    super.genre,
    super.year,
    super.trackNo,
    required super.durationMs,
    super.sizeBytes,
    super.bitrate,
    super.sampleRate,
    super.mimeType,
    super.dateAdded,
    super.dateModified,
    super.isMissing,
  });

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as int?,
      mediaId: map['media_id'] as int?,
      path: map['song_path'] as String,
      folderPath: map['folder_path'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      albumArtist: map['album_artist'] as String?,
      genre: map['genre'] as String?,
      year: map['year'] as int?,
      trackNo: map['track_no'] as int?,
      durationMs: map['duration_ms'] as int,
      sizeBytes: map['size_bytes'] as int?,
      bitrate: map['bitrate'] as int?,
      sampleRate: map['sample_rate'] as int?,
      mimeType: map['mime_type'] as String?,
      dateAdded: map['date_added'] as int?,
      dateModified: map['date_modified'] as int?,
      isMissing: (map['is_missing'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'media_id': mediaId,
      'song_path': path,
      'folder_path': folderPath,
      'title': title,
      'artist': artist,
      'album': album,
      'album_artist': albumArtist,
      'genre': genre,
      'year': year,
      'track_no': trackNo,
      'duration_ms': durationMs,
      'size_bytes': sizeBytes,
      'bitrate': bitrate,
      'sample_rate': sampleRate,
      'mime_type': mimeType,
      'date_added': dateAdded,
      'date_modified': dateModified,
      'is_missing': isMissing ? 1 : 0,
    };
  }

  factory SongModel.fromEntity(Song song) => SongModel(
        id: song.id,
        mediaId: song.mediaId,
        path: song.path,
        folderPath: song.folderPath,
        title: song.title,
        artist: song.artist,
        album: song.album,
        albumArtist: song.albumArtist,
        genre: song.genre,
        year: song.year,
        trackNo: song.trackNo,
        durationMs: song.durationMs,
        sizeBytes: song.sizeBytes,
        bitrate: song.bitrate,
        sampleRate: song.sampleRate,
        mimeType: song.mimeType,
        dateAdded: song.dateAdded,
        dateModified: song.dateModified,
        isMissing: song.isMissing,
      );
}
