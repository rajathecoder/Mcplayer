import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/playback/playback_cubit.dart';
import '../../widgets/song_artwork.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all_rounded),
            tooltip: 'Clear queue',
            onPressed: () => context.read<PlaybackCubit>().clearQueue(),
          ),
        ],
      ),
      body: BlocBuilder<PlaybackCubit, PlaybackUiState>(
        builder: (context, state) {
          if (state.queue.isEmpty) {
            return const Center(child: Text('Queue is empty'));
          }
          final cubit = context.read<PlaybackCubit>();

          return ReorderableListView.builder(
            itemCount: state.queue.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              cubit.reorderQueue(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final item = state.queue[index];
              final isCurrent = index == state.currentIndex;
              return Dismissible(
                key: ValueKey(item.id),
                onDismissed: (_) => cubit.removeFromQueue(index),
                background: Container(color: Theme.of(context).colorScheme.errorContainer),
                child: ListTile(
                  tileColor: isCurrent ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
                  leading: SongArtwork(mediaId: item.extras?['mediaId'] as int?),
                  title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(item.artist ?? 'Unknown Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: isCurrent ? const Icon(Icons.equalizer_rounded) : null,
                  onTap: () => cubit.skipToQueueItem(index),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
