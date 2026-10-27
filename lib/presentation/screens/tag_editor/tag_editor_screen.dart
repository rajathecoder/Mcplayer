import 'package:audiotags/audiotags.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injector.dart';
import '../../../data/datasources/local/songs_local_datasource.dart';
import '../../../domain/entities/song.dart';

class TagEditorScreen extends StatefulWidget {
  final Song song;

  const TagEditorScreen({super.key, required this.song});

  @override
  State<TagEditorScreen> createState() => _TagEditorScreenState();
}

class _TagEditorScreenState extends State<TagEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _artist;
  late final TextEditingController _album;
  late final TextEditingController _albumArtist;
  late final TextEditingController _genre;
  late final TextEditingController _year;
  late final TextEditingController _trackNo;
  bool _saving = false;
  List<Picture> _existingPictures = const [];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.song.title);
    _artist = TextEditingController(text: widget.song.artist ?? '');
    _album = TextEditingController(text: widget.song.album ?? '');
    _albumArtist = TextEditingController(text: widget.song.albumArtist ?? '');
    _genre = TextEditingController(text: widget.song.genre ?? '');
    _year = TextEditingController(text: widget.song.year?.toString() ?? '');
    _trackNo = TextEditingController(text: widget.song.trackNo?.toString() ?? '');
    _loadExistingTag();
  }

  Future<void> _loadExistingTag() async {
    final tag = await AudioTags.read(widget.song.path);
    if (!mounted || tag == null) return;
    setState(() => _existingPictures = tag.pictures);
  }

  @override
  void dispose() {
    for (final c in [_title, _artist, _album, _albumArtist, _genre, _year, _trackNo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final tag = Tag(
        title: _title.text.trim(),
        trackArtist: _artist.text.trim().isEmpty ? null : _artist.text.trim(),
        album: _album.text.trim().isEmpty ? null : _album.text.trim(),
        albumArtist: _albumArtist.text.trim().isEmpty ? null : _albumArtist.text.trim(),
        genre: _genre.text.trim().isEmpty ? null : _genre.text.trim(),
        year: int.tryParse(_year.text.trim()),
        trackNumber: int.tryParse(_trackNo.text.trim()),
        pictures: _existingPictures,
      );
      await AudioTags.write(widget.song.path, tag);

      await getIt<SongsLocalDataSource>().updateMetadata(
        widget.song.path,
        title: tag.title ?? widget.song.title,
        artist: tag.trackArtist,
        album: tag.album,
        albumArtist: tag.albumArtist,
        genre: tag.genre,
        year: tag.year,
        trackNo: tag.trackNumber,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save tags: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit tags'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('Title', _title),
          _field('Artist', _artist),
          _field('Album', _album),
          _field('Album Artist', _albumArtist),
          _field('Genre', _genre),
          _field('Year', _year, keyboardType: TextInputType.number),
          _field('Track number', _trackNo, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
