import 'package:test/test.dart';
import 'package:movia_desktop/features/events/domain/event.dart';

void main() {
  test('Android schema v1 event round-trips without data loss', () {
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
    final exported = event.toJson();
    expect(DateTime.parse(exported['targetInstant']! as String), DateTime.parse(source['targetInstant']! as String));
    exported.remove('targetInstant');
    source.remove('targetInstant');
    expect(exported, source);
  });

  test('database representation preserves archive state and UTC instant', () {
    final event = MoviaEvent(
      externalId: 'id',
      title: 'Launch',
      targetInstant: DateTime.parse('2027-01-10T12:00:00+04:00'),
      archived: true,
    );
    final row = event.toDb();
    expect(row['target_instant'], '2027-01-10T08:00:00.000Z');
    expect(row['archived'], 1);
  });
}
