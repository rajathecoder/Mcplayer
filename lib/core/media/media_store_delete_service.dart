import 'package:flutter/services.dart';

/// Deletes audio files through Android's MediaStore delete-request flow
/// (shows a one-time system confirmation dialog) rather than raw file I/O,
/// which scoped storage blocks for files this app doesn't own.
class MediaStoreDeleteService {
  static const _channel = MethodChannel('com.kugan.mcplayer.mc_player/media_store');

  /// Returns true if the user confirmed and the file(s) were deleted.
  Future<bool> deleteByMediaIds(List<int> mediaIds) async {
    if (mediaIds.isEmpty) return true;
    final uris = mediaIds.map((id) => 'content://media/external/audio/media/$id').toList();
    final result = await _channel.invokeMethod<bool>('deleteMediaItems', uris);
    return result ?? false;
  }
}
