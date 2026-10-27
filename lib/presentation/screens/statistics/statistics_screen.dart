import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/datasources/local/stats_local_datasource.dart';
import '../../../domain/entities/song.dart';
import '../../bloc/library/library_bloc.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _stats = getIt<StatsLocalDataSource>();
  int _totalMs = 0;
  int _totalPlays = 0;
  List<Song> _topSongs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final totalMs = await _stats.totalListeningMs();
    final totalPlays = await _stats.totalPlays();
    final topPaths = await _stats.mostPlayedPaths(limit: 10);
    final allSongs = context.read<LibraryBloc>().state.songs;
    final byPath = {for (final s in allSongs) s.path: s};
    final topSongs = topPaths.map((p) => byPath[p]).whereType<Song>().toList();

    if (!mounted) return;
    setState(() {
      _totalMs = totalMs;
      _totalPlays = totalPlays;
      _topSongs = topSongs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listening Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Total listening time', value: formatDuration(Duration(milliseconds: _totalMs)))),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Total plays', value: '$_totalPlays')),
            ],
          ),
          const SizedBox(height: 24),
          Text('Top 10 tracks', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_topSongs.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No listening history yet'))
          else
            for (var i = 0; i < _topSongs.length; i++)
              ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(_topSongs[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(_topSongs[i].artist ?? 'Unknown Artist'),
              ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
