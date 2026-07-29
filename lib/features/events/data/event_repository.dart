import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../domain/event.dart';

class EventRepository {
  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    _db = await openDatabase(p.join(dir.path, 'movia.db'), version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE events(
          external_id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT NOT NULL,
          target_instant TEXT NOT NULL, time_zone TEXT NOT NULL, color_argb INTEGER NOT NULL,
          icon TEXT NOT NULL, archived INTEGER NOT NULL DEFAULT 0
        )'''));
    return _db!;
  }
  Future<List<MoviaEvent>> all() async {
    final rows = await (await database).query('events', orderBy: 'target_instant ASC');
    return rows.map(MoviaEvent.fromMap).toList();
  }
  Future<void> save(MoviaEvent event) async => (await database).insert(
    'events', event.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> delete(String id) async =>
      (await database).delete('events', where: 'external_id = ?', whereArgs: [id]);
  Future<String> exportJson(String theme, String language) async =>
      const JsonEncoder.withIndent('  ').convert({
        'schemaVersion': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'events': (await all()).map((e) => e.toJson()).toList(),
        'settings': {'theme': theme, 'language': language},
      });
  Future<List<MoviaEvent>> parseImport(File file) async {
    final root = jsonDecode(await file.readAsString());
    if (root is! Map<String, dynamic> ||
        root['schemaVersion'] != 1 ||
        root['events'] is! List) {
      throw const FormatException('Unsupported schema');
    }
    return (root['events'] as List).map((raw) {
      if (raw is! Map<String, dynamic>) throw const FormatException('Malformed event');
      final event = MoviaEvent.fromMap(raw, json: true);
      if (event.title.trim().isEmpty) throw const FormatException('Empty title');
      return event;
    }).toList();
  }
  Future<void> applyImport(List<MoviaEvent> events, {required bool replace}) async {
    final db = await database;
    await db.transaction((txn) async {
      if (replace) await txn.delete('events');
      for (final event in events) {
        await txn.insert('events', event.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
