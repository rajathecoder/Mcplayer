import 'package:get_it/get_it.dart';

import '../../data/datasources/local/eq_local_datasource.dart';
import '../../data/datasources/local/favorites_local_datasource.dart';
import '../../data/datasources/local/playlists_local_datasource.dart';
import '../../data/datasources/local/queue_local_datasource.dart';
import '../../data/datasources/local/songs_local_datasource.dart';
import '../../data/datasources/local/stats_local_datasource.dart';
import '../../data/datasources/media/media_scanner.dart';
import '../../data/repositories/library_repository_impl.dart';
import '../../data/repositories/queue_repository_impl.dart';
import '../../domain/repositories/library_repository.dart';
import '../../domain/repositories/queue_repository.dart';
import '../audio/audio_player_handler.dart';
import '../audio/sleep_timer.dart';
import '../backup/backup_service.dart';
import '../media/media_store_delete_service.dart';
import '../utils/permission_manager.dart';
import '../widget/home_widget_service.dart';

final getIt = GetIt.instance;

void setupInjector() {
  getIt.registerLazySingleton(() => PermissionManager());
  getIt.registerLazySingleton(() => MediaScanner());
  getIt.registerLazySingleton(() => SongsLocalDataSource());
  getIt.registerLazySingleton(() => QueueLocalDataSource());
  getIt.registerLazySingleton(() => FavoritesLocalDataSource());
  getIt.registerLazySingleton(() => PlaylistsLocalDataSource());
  getIt.registerLazySingleton(() => StatsLocalDataSource());
  getIt.registerLazySingleton(() => EqLocalDataSource());
  getIt.registerLazySingleton(() => MediaStoreDeleteService());
  getIt.registerLazySingleton<LibraryRepository>(
    () => LibraryRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<QueueRepository>(
    () => QueueRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => HomeWidgetService());
  getIt.registerLazySingleton(() => BackupService(
        favorites: getIt(),
        playlists: getIt(),
        eq: getIt(),
      ));
}

/// Registered separately in main() once AudioService.init() has resolved.
void registerAudioHandler(AudioPlayerHandler handler) {
  getIt.registerSingleton<AudioPlayerHandler>(handler);
  getIt.registerSingleton<SleepTimer>(SleepTimer(handler));
}
