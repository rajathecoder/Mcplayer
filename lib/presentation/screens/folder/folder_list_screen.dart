import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/format_utils.dart';
import '../../bloc/library/library_bloc.dart';
import '../search/search_screen.dart';
import 'folder_detail_screen.dart';

class FolderListScreen extends StatelessWidget {
  const FolderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          BlocBuilder<LibraryBloc, LibraryState>(
            builder: (context, state) {
              final scanning = state.status == LibraryStatus.scanning;
              return IconButton(
                tooltip: 'Rescan Library',
                icon: scanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                onPressed: scanning
                    ? null
                    : () => context.read<LibraryBloc>().add(const LibraryRescanRequested()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state.status == LibraryStatus.loading || state.status == LibraryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == LibraryStatus.error) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }

          if (state.folders.isEmpty) {
            return _EmptyState(
              onScan: () => context.read<LibraryBloc>().add(const LibraryRescanRequested()),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<LibraryBloc>().add(const LibraryRescanRequested()),
            child: ListView.builder(
              itemCount: state.folders.length,
              itemBuilder: (context, index) {
                final folder = state.folders[index];
                return ListTile(
                  leading: const Icon(Icons.folder_rounded),
                  title: Text(folder.name),
                  subtitle: Text(
                    '${folder.trackCount} tracks • ${formatDuration(Duration(milliseconds: folder.totalDurationMs))}',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FolderDetailScreen(folder: folder)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onScan;

  const _EmptyState({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_off_rounded, size: 64),
          const SizedBox(height: 16),
          const Text('No music found yet'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Scan Library'),
          ),
        ],
      ),
    );
  }
}
