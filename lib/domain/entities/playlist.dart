import 'package:equatable/equatable.dart';

class Playlist extends Equatable {
  final int id;
  final String title;
  final String? description;
  final String? coverPath;
  final bool isPinned;
  final int createdAt;
  final int updatedAt;
  final int trackCount;

  const Playlist({
    required this.id,
    required this.title,
    this.description,
    this.coverPath,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
    this.trackCount = 0,
  });

  @override
  List<Object?> get props => [id];
}
