part of 'library_bloc.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

class LibraryLoadRequested extends LibraryEvent {
  const LibraryLoadRequested();
}

class LibraryRescanRequested extends LibraryEvent {
  const LibraryRescanRequested();
}
