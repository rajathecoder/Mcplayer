import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/di/injector.dart';
import '../../../core/backup/backup_service.dart';
import '../../bloc/settings/settings_cubit.dart';
import '../equalizer/equalizer_screen.dart';
import '../statistics/statistics_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>();
    final s = settings.state;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Playback'),
          ListTile(
            title: const Text('Crossfade'),
            subtitle: Text(s.crossfadeSeconds == 0 ? 'Off' : '${s.crossfadeSeconds}s fade near track end'),
            trailing: SizedBox(
              width: 160,
              child: Slider(
                min: 0,
                max: 12,
                divisions: 12,
                value: s.crossfadeSeconds.toDouble(),
                onChanged: (v) => settings.setCrossfadeSeconds(v.round()),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Skip silence'),
            subtitle: const Text('Automatically skip silent gaps'),
            value: s.skipSilence,
            onChanged: settings.setSkipSilence,
          ),
          ListTile(
            title: const Text('Seek interval'),
            subtitle: Text('${s.seekIntervalSeconds}s per skip'),
            trailing: SizedBox(
              width: 160,
              child: Slider(
                min: 5,
                max: 30,
                divisions: 5,
                value: s.seekIntervalSeconds.toDouble(),
                onChanged: (v) => settings.setSeekInterval(v.round()),
              ),
            ),
          ),
          const Divider(),
          _SectionHeader('Audio'),
          ListTile(
            leading: const Icon(Icons.equalizer_rounded),
            title: const Text('Equalizer'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EqualizerScreen())),
          ),
          const Divider(),
          _SectionHeader('Appearance'),
          ListTile(
            title: const Text('Theme'),
            trailing: DropdownButton<AppThemeMode>(
              value: s.themeMode,
              items: const [
                DropdownMenuItem(value: AppThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: AppThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: AppThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(value: AppThemeMode.amoled, child: Text('AMOLED')),
              ],
              onChanged: (mode) {
                if (mode != null) settings.setThemeMode(mode);
              },
            ),
          ),
          if (Platform.isAndroid) ...[
            const Divider(),
            _SectionHeader('Widgets'),
            ListTile(
              leading: const Icon(Icons.widgets_rounded),
              title: const Text('Add home-screen widget'),
              subtitle: const Text('Playback controls on your home screen'),
              onTap: () => _pinWidget(context),
            ),
          ],
          const Divider(),
          _SectionHeader('Backup & Restore'),
          ListTile(
            leading: const Icon(Icons.upload_rounded),
            title: const Text('Export data'),
            subtitle: const Text('Favorites, playlists & EQ presets'),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: const Text('Import data'),
            onTap: () => _import(context),
          ),
          const Divider(),
          _SectionHeader('Privacy'),
          SwitchListTile(
            title: const Text('Enable listening statistics'),
            value: s.statsEnabled,
            onChanged: settings.setStatsEnabled,
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: const Text('View statistics'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StatisticsScreen())),
          ),
          const Divider(),
          _SectionHeader('About'),
          const ListTile(title: Text('Version'), subtitle: Text('1.0.0')),
          const ListTile(
            title: Text('MC Player'),
            subtitle: Text('Offline-first local music player. No account, no analytics, no internet required.'),
          ),
        ],
      ),
    );
  }

  Future<void> _pinWidget(BuildContext context) async {
    final supported = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    if (!supported) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Long-press your home screen and add the MC Player widget manually.'),
      ));
      return;
    }
    await HomeWidget.requestPinWidget(androidName: 'McPlayerWidgetProvider');
  }

  Future<void> _export(BuildContext context) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/mc_player_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = await getIt<BackupService>().exportToFile(path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
  }

  Future<void> _import(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    final path = result?.files.single.path;
    if (path == null) return;
    await getIt<BackupService>().importFromFile(path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import complete')));
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
