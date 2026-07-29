# Android JSON compatibility

Movia Desktop implements the Android project's proposed cross-platform schema
version 1 exactly:

```json
{
  "schemaVersion": 1,
  "exportedAt": "2026-07-28T00:00:00Z",
  "events": [{
    "externalId": "uuid",
    "title": "Trip",
    "description": "",
    "targetInstant": "2026-08-01T12:00:00Z",
    "timeZone": "Asia/Dubai",
    "colorArgb": 4284831961,
    "icon": "travel",
    "archived": false
  }],
  "settings": {"theme": "system", "language": "system"}
}
```

Instants are parsed as ISO-8601 and exported in UTC. IANA time-zone identifiers,
signed/unsigned ARGB values, icon identifiers, and archive state are preserved.
Unknown schema versions, missing event arrays, malformed values, and blank
titles are rejected before writes occur.

Merge upserts by `externalId`. Replace deletes existing desktop events inside a
single transaction before inserting the validated import. Device identifiers,
widget identifiers, permissions, notification state, and secrets are neither
accepted as domain fields nor exported.
