import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/audio/audio_player_handler.dart';
import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/library_repository.dart';
import 'domain/repositories/queue_repository.dart';
import 'presentation/bloc/favorites/favorites_cubit.dart';
import 'presentation/bloc/library/library_bloc.dart';
import 'presentation/bloc/playback/playback_cubit.dart';
import 'presentation/bloc/playlist/playlists_cubit.dart';
import 'presentation/bloc/settings/settings_cubit.dart';
import 'presentation/screens/splash/permission_gate_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupInjector();

  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.kugan.mcplayer.mc_player.audio',
      androidNotificationChannelName: 'MC Player playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  registerAudioHandler(audioHandler);

  runApp(const McPlayerApp());
}

class McPlayerApp extends StatelessWidget {
  const McPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PlaybackCubit(getIt<AudioPlayerHandler>(), getIt<QueueRepository>(), getIt(), getIt())
            ..restoreLastSession(),
        ),
        BlocProvider(create: (_) => FavoritesCubit(getIt())),
        BlocProvider(create: (_) => PlaylistsCubit(getIt())),
        BlocProvider(
          create: (_) => LibraryBloc(getIt<LibraryRepository>())..add(const LibraryLoadRequested()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return BlocProvider(
            create: (_) => SettingsCubit(getIt<AudioPlayerHandler>(), context.read<PlaybackCubit>()),
            child: BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, settings) {
                return MaterialApp(
                  title: 'MC Player',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light(),
                  darkTheme: settings.themeMode == AppThemeMode.amoled ? AppTheme.amoled() : AppTheme.dark(),
                  themeMode: switch (settings.themeMode) {
                    AppThemeMode.system => ThemeMode.system,
                    AppThemeMode.light => ThemeMode.light,
                    AppThemeMode.dark || AppThemeMode.amoled => ThemeMode.dark,
                  },
                  home: const PermissionGateScreen(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
