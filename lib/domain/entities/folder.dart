import 'package:equatable/equatable.dart';

class MusicFolder extends Equatable {
  final String path;
  final String name;
  final int trackCount;
  final int totalDurationMs;
  final int totalSizeBytes;
  final bool isPinned;

  const MusicFolder({
    required this.path,
    required this.name,
    required this.trackCount,
    required this.totalDurationMs,
    required this.totalSizeBytes,
    this.isPinned = false,
  });

  @override
  List<Object?> get props => [path];
}
