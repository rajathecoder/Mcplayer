import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/folder.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/repositories/library_repository.dart';

part 'library_event.dart';
part 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final LibraryRepository _repository;

  LibraryBloc(this._repository) : super(const LibraryState()) {
    on<LibraryLoadRequested>(_onLoadRequested);
    on<LibraryRescanRequested>(_onRescanRequested);
  }

  Future<void> _onLoadRequested(LibraryLoadRequested event, Emitter<LibraryState> emit) async {
    emit(state.copyWith(status: LibraryStatus.loading));
    try {
      final songs = await _repository.getAllSongs();
      final folders = await _repository.getFolders();
      emit(state.copyWith(status: LibraryStatus.loaded, songs: songs, folders: folders));
    } catch (e) {
      emit(state.copyWith(status: LibraryStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onRescanRequested(LibraryRescanRequested event, Emitter<LibraryState> emit) async {
    emit(state.copyWith(status: LibraryStatus.scanning));
    try {
      final songs = await _repository.rescanLibrary();
      final folders = await _repository.getFolders();
      emit(state.copyWith(status: LibraryStatus.loaded, songs: songs, folders: folders));
    } catch (e) {
      emit(state.copyWith(status: LibraryStatus.error, errorMessage: e.toString()));
    }
  }
}
