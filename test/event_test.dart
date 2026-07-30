import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:movia_desktop/features/events/data/event_repository.dart';
import 'package:movia_desktop/features/events/domain/event.dart';
import 'package:movia_desktop/features/events/presentation/screens.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Android schema v1 remains compatible and supplies safe timestamps', () {
    final source = <String, Object?>{
      'externalId': '926ed3f1-d37d-44e2-b06b-3c1d134cc641',
      'title': 'Trip',
      'description': 'Pack passports',
      'targetInstant': '2026-08-01T12:00:00Z',
      'timeZone': 'Asia/Dubai',
      'colorArgb': 4284831961,
      'icon': 'travel',
      'archived': false,
    };
    final event = MoviaEvent.fromMap(source, json: true);
    expect(event.createdAt, DateTime.parse(source['targetInstant']! as String));
    expect(event.updatedAt, event.createdAt);
  });

  test('schema v2 JSON round-trip preserves both timestamps', () {
    final event = MoviaEvent(
      externalId: 'id',
      title: 'Launch',
      targetInstant: DateTime.parse('2027-01-10T12:00:00+04:00'),
      createdAt: DateTime.parse('2026-01-01T08:00:00Z'),
      updatedAt: DateTime.parse('2026-02-01T09:00:00Z'),
      archived: true,
    );
    final restored = MoviaEvent.fromMap(event.toJson(), json: true);
    expect(restored.createdAt, event.createdAt);
    expect(restored.updatedAt, event.updatedAt);
    expect(restored.toDb()['archived'], 1);
  });

  test('timeline grouping respects boundaries', () {
    final now = DateTime(2026, 7, 30);
    expect(groupKey(DateTime(2026, 7, 30, 20), now: now), 'today');
    expect(groupKey(DateTime(2026, 7, 31), now: now), 'tomorrow');
    expect(groupKey(DateTime(2026, 8, 1), now: now), 'thisWeek');
    expect(groupKey(DateTime(2026, 8, 20), now: now), 'later');
  });

  test(
    'v1 database migrates idempotently without deleting existing data',
    () async {
      final dir = await Directory.systemTemp.createTemp('movia-migration-');
      final path = '${dir.path}${Platform.pathSeparator}movia.db';
      final legacy = await openDatabase(
        path,
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''CREATE TABLE events(
        external_id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT NOT NULL,
        target_instant TEXT NOT NULL, time_zone TEXT NOT NULL, color_argb INTEGER NOT NULL,
        icon TEXT NOT NULL, archived INTEGER NOT NULL DEFAULT 0)''');
          await db.insert('events', {
            'external_id': 'legacy',
            'title': 'Existing',
            'description': '',
            'target_instant': '2026-12-10T08:00:00.000Z',
            'time_zone': 'Asia/Dubai',
            'color_argb': 0xFF7C3AED,
            'icon': 'personal',
            'archived': 0,
          });
        },
      );
      await legacy.close();
      final repo = EventRepository(databasePath: path);
      final first = await repo.all();
      expect(first.single.externalId, 'legacy');
      expect(
        first.single.createdAt,
        DateTime.parse('2026-12-10T08:00:00.000Z'),
      );
      await repo.close();
      final reopened = EventRepository(databasePath: path);
      expect((await reopened.all()).single.externalId, 'legacy');
      await reopened.close();
      await dir.delete(recursive: true);
    },
  );
}
