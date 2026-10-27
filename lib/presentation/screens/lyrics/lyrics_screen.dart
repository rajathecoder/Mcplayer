import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/lrc_parser.dart';
import '../../bloc/playback/playback_cubit.dart';

/// Lyrics are sourced from a sidecar `.lrc` file next to the audio file (same
/// base name), or can be pasted manually and saved back as one. Reading
/// lyrics embedded directly in ID3 USLT/SYLT frames isn't supported by the
/// current tagging package, so that source from the plan is not implemented.
class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  List<LyricLine>? _lines;
  String? _plainText;
  String? _songPath;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final path = context.read<PlaybackCubit>().state.mediaItem?.id;
    if (path != _songPath) {
      _songPath = path;
      _load(path);
    }
  }

  File _lrcFileFor(String songPath) {
    final withoutExt = p.withoutExtension(songPath);
    return File('$withoutExt.lrc');
  }

  Future<void> _load(String? songPath) async {
    setState(() => _loading = true);
    if (songPath == null) {
      setState(() {
        _lines = null;
        _plainText = null;
        _loading = false;
      });
      return;
    }

    final lrcFile = _lrcFileFor(songPath);
    if (await lrcFile.exists()) {
      final content = await lrcFile.readAsString();
      final parsed = LrcParser.parse(content);
      setState(() {
        _lines = parsed.isEmpty ? null : parsed;
        _plainText = parsed.isEmpty ? content : null;
        _loading = false;
      });
    } else {
      setState(() {
        _lines = null;
        _plainText = null;
        _loading = false;
      });
    }
  }

  Future<void> _pasteLyrics() async {
    final controller = TextEditingController(text: _plainText ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste lyrics'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 12,
            decoration: const InputDecoration(hintText: 'Paste plain text or LRC-formatted lyrics'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty || _songPath == null) return;

    await _lrcFileFor(_songPath!).writeAsString(result);
    _load(_songPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyrics'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: _songPath == null ? null : _pasteLyrics),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lines != null
              ? _SyncedLyricsView(lines: _lines!)
              : _plainText != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Text(_plainText!, style: Theme.of(context).textTheme.bodyLarge),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lyrics_outlined, size: 64),
                          const SizedBox(height: 16),
                          const Text('No lyrics found for this track'),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _songPath == null ? null : _pasteLyrics,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add lyrics'),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _SyncedLyricsView extends StatelessWidget {
  final List<LyricLine> lines;

  const _SyncedLyricsView({required this.lines});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PlaybackCubit>();
    return StreamBuilder<Duration>(
      stream: cubit.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final currentIndex = LrcParser.currentLineIndex(lines, position);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 200, horizontal: 24),
          itemCount: lines.length,
          itemBuilder: (context, index) {
            final isCurrent = index == currentIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                onTap: () => cubit.seek(lines[index].timestamp),
                child: Text(
                  lines[index].text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isCurrent ? 20 : 16,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
