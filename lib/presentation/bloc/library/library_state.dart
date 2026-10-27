part of 'library_bloc.dart';

enum LibraryStatus { initial, loading, scanning, loaded, error }

class LibraryState extends Equatable {
  final LibraryStatus status;
  final List<Song> songs;
  final List<MusicFolder> folders;
  final String? errorMessage;

  const LibraryState({
    this.status = LibraryStatus.initial,
    this.songs = const [],
    this.folders = const [],
    this.errorMessage,
  });

  LibraryState copyWith({
    LibraryStatus? status,
    List<Song>? songs,
    List<MusicFolder>? folders,
    String? errorMessage,
  }) {
    return LibraryState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      folders: folders ?? this.folders,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, songs, folders, errorMessage];
}
