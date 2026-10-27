import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../db/app_database.dart';

class EqPresetRow {
  final int id;
  final String name;
  final List<int> bandValues;
  final int bassBoost;
  final int virtualizer;
  final bool isBuiltin;

  EqPresetRow({
    required this.id,
    required this.name,
    required this.bandValues,
    required this.bassBoost,
    required this.virtualizer,
    required this.isBuiltin,
  });
}

class EqLocalDataSource {
  Future<Database> get _db async => AppDatabase.instance;

  Future<List<EqPresetRow>> getPresets() async {
    final db = await _db;
    final rows = await db.query('eq_presets', orderBy: 'is_builtin DESC, name');
    return rows
        .map((r) => EqPresetRow(
              id: r['id'] as int,
              name: r['name'] as String,
              bandValues: (jsonDecode(r['band_values'] as String) as List).cast<int>(),
              bassBoost: r['bass_boost'] as int? ?? 0,
              virtualizer: r['virtualizer'] as int? ?? 0,
              isBuiltin: (r['is_builtin'] as int? ?? 0) == 1,
            ))
        .toList();
  }

  Future<void> savePreset(String name, List<int> bandValues, {int bassBoost = 0, int virtualizer = 0}) async {
    final db = await _db;
    await db.insert(
      'eq_presets',
      {
        'name': name,
        'band_values': jsonEncode(bandValues),
        'bass_boost': bassBoost,
        'virtualizer': virtualizer,
        'is_builtin': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePreset(int id) async {
    final db = await _db;
    await db.delete('eq_presets', where: 'id = ? AND is_builtin = 0', whereArgs: [id]);
  }
}
