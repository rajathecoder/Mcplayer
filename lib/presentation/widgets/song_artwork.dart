import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;

/// Shows a song's embedded artwork (via on_audio_query/MediaStore), falling
/// back to a plain music-note icon when there's no artwork or no media id
/// (e.g. a track whose file no longer matches a MediaStore entry).
class SongArtwork extends StatelessWidget {
  final int? mediaId;
  final double size;
  final double borderRadius;
  final double iconSize;

  const SongArtwork({
    super.key,
    required this.mediaId,
    this.size = 48,
    this.borderRadius = 8,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = _Fallback(size: size, borderRadius: borderRadius, iconSize: iconSize);
    if (mediaId == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: QueryArtworkWidget(
        id: mediaId!,
        type: ArtworkType.AUDIO,
        artworkWidth: size,
        artworkHeight: size,
        artworkFit: BoxFit.cover,
        artworkQuality: FilterQuality.medium,
        keepOldArtwork: true,
        nullArtworkWidget: fallback,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final double size;
  final double borderRadius;
  final double iconSize;

  const _Fallback({required this.size, required this.borderRadius, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(Icons.music_note_rounded, size: iconSize),
    );
  }
}
