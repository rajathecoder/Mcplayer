import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/local/favorites_local_datasource.dart';
import '../../../domain/entities/song.dart';

/// Tracks the set of favorited song paths as a single source of truth so the
/// heart toggle stays in sync across mini player, full player, and lists.
class FavoritesCubit extends Cubit<Set<String>> {
  final FavoritesLocalDataSource _local;

  FavoritesCubit(this._local) : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    emit(await _local.getFavoritePaths());
  }

  bool isFavorite(String path) => state.contains(path);

  Future<void> toggle(Song song) async {
    if (state.contains(song.path)) {
      await _local.removeFavorite(song.path);
      emit({...state}..remove(song.path));
    } else {
      await _local.addFavorite(song.path, song.title, song.artist);
      emit({...state, song.path});
    }
  }

  Future<List<String>> favoritePathsOrdered() => _local.getFavoritePathsOrdered();
}
