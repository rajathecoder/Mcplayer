import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const _dbName = 'mc_player.db';
  static const _dbVersion = 2;

  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE songs_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_id INTEGER,
        song_path TEXT UNIQUE NOT NULL,
        folder_path TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        album_artist TEXT,
        genre TEXT,
        year INTEGER,
        track_no INTEGER,
        duration_ms INTEGER NOT NULL,
        size_bytes INTEGER,
        bitrate INTEGER,
        sample_rate INTEGER,
        mime_type TEXT,
        date_added INTEGER,
        date_modified INTEGER,
        is_missing INTEGER DEFAULT 0
      )
    ''');
    batch.execute('CREATE INDEX idx_songs_folder ON songs_cache(folder_path)');
    batch.execute('CREATE INDEX idx_songs_title ON songs_cache(title)');
    batch.execute('CREATE INDEX idx_songs_artist ON songs_cache(artist)');

    batch.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_path TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        artist TEXT,
        date_added INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        cover_path TEXT,
        is_pinned INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE playlist_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
        song_path TEXT NOT NULL,
        track_order INTEGER NOT NULL,
        added_at INTEGER NOT NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_pl_tracks ON playlist_tracks(playlist_id, track_order)');

    batch.execute('''
      CREATE TABLE playback_stats (
        song_path TEXT PRIMARY KEY,
        play_count INTEGER DEFAULT 0,
        skip_count INTEGER DEFAULT 0,
        total_play_ms INTEGER DEFAULT 0,
        last_played INTEGER
      )
    ''');

    batch.execute('''
      CREATE TABLE play_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_path TEXT NOT NULL,
        played_at INTEGER NOT NULL,
        duration_listened_ms INTEGER
      )
    ''');

    batch.execute('''
      CREATE TABLE queue_state (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_path TEXT NOT NULL,
        queue_order INTEGER NOT NULL,
        is_current INTEGER DEFAULT 0,
        position_ms INTEGER DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE excluded_paths (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT UNIQUE NOT NULL,
        type TEXT CHECK(type IN ('blacklist','whitelist'))
      )
    ''');

    batch.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_path TEXT NOT NULL,
        label TEXT,
        position_ms INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE eq_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        band_values TEXT NOT NULL,
        bass_boost INTEGER DEFAULT 0,
        virtualizer INTEGER DEFAULT 0,
        is_builtin INTEGER DEFAULT 0
      )
    ''');

    // Seed default blacklist paths.
    for (final path in const [
      '/Android/media/com.whatsapp/WhatsApp Voice Notes',
      '/Notifications',
      '/Ringtones',
      '/Alarms',
      '/Recordings',
    ]) {
      batch.insert('excluded_paths', {'path': path, 'type': 'blacklist'});
    }

    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Schema is currently at version 2 with no live installs to migrate yet.
  }
}
