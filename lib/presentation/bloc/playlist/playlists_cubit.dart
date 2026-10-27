import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/local/playlists_local_datasource.dart';
import '../../../domain/entities/playlist.dart';

class PlaylistsCubit extends Cubit<List<Playlist>> {
  final PlaylistsLocalDataSource _local;

  PlaylistsCubit(this._local) : super(const []) {
    refresh();
  }

  Future<void> refresh() async {
    emit(await _local.getPlaylists());
  }

  Future<void> createPlaylist(String title) async {
    await _local.createPlaylist(title);
    await refresh();
  }

  Future<void> rename(int id, String title) async {
    await _local.renamePlaylist(id, title);
    await refresh();
  }

  Future<void> delete(int id) async {
    await _local.deletePlaylist(id);
    await refresh();
  }

  Future<void> togglePinned(Playlist playlist) async {
    await _local.setPinned(playlist.id, !playlist.isPinned);
    await refresh();
  }

  Future<void> addSongToPlaylist(int playlistId, String songPath) async {
    await _local.addTrack(playlistId, songPath);
    await refresh();
  }

  Future<List<String>> getSongPaths(int playlistId) => _local.getPlaylistSongPaths(playlistId);

  Future<void> removeTrackAt(int playlistId, int order) async {
    await _local.removeTrackAt(playlistId, order);
    await refresh();
  }

  Future<void> reorderTracks(int playlistId, int oldIndex, int newIndex) async {
    await _local.reorderTracks(playlistId, oldIndex, newIndex);
  }
}
