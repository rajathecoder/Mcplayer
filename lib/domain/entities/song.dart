import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final int? id;
  final int? mediaId;
  final String path;
  final String folderPath;
  final String title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final String? genre;
  final int? year;
  final int? trackNo;
  final int durationMs;
  final int? sizeBytes;
  final int? bitrate;
  final int? sampleRate;
  final String? mimeType;
  final int? dateAdded;
  final int? dateModified;
  final bool isMissing;

  const Song({
    this.id,
    this.mediaId,
    required this.path,
    required this.folderPath,
    required this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.genre,
    this.year,
    this.trackNo,
    required this.durationMs,
    this.sizeBytes,
    this.bitrate,
    this.sampleRate,
    this.mimeType,
    this.dateAdded,
    this.dateModified,
    this.isMissing = false,
  });

  Duration get duration => Duration(milliseconds: durationMs);

  Song copyWith({
    int? id,
    bool? isMissing,
  }) {
    return Song(
      id: id ?? this.id,
      mediaId: mediaId,
      path: path,
      folderPath: folderPath,
      title: title,
      artist: artist,
      album: album,
      albumArtist: albumArtist,
      genre: genre,
      year: year,
      trackNo: trackNo,
      durationMs: durationMs,
      sizeBytes: sizeBytes,
      bitrate: bitrate,
      sampleRate: sampleRate,
      mimeType: mimeType,
      dateAdded: dateAdded,
      dateModified: dateModified,
      isMissing: isMissing ?? this.isMissing,
    );
  }

  @override
  List<Object?> get props => [path];
}
