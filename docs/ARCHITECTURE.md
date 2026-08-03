# Architecture

Movia Desktop uses clean architecture with feature-first ownership.

```text
lib/
├─ core/
│  └─ localization/       English/Arabic strings and RTL selection
├─ features/
│  └─ events/
│     ├─ domain/          Framework-independent event entity
│     ├─ data/            SQLite repository and JSON adapter
│     ├─ application/     Riverpod controllers and app settings
│     └─ presentation/    Dashboard, calendar, archive, details, editor
├─ app.dart               Material 3 theme, GoRouter, desktop shell
└─ main.dart              Windows and SQLite initialization
```

The presentation layer depends on application providers. Controllers depend on
the repository abstraction boundary; persistence models never leak into UI components.
GoRouter owns URL-like navigation, while Riverpod owns application state.

SQLite is initialized through `sqflite_common_ffi`, keeping Room and all Android
APIs out of this project. Theme and language preferences use Windows-local
shared preferences because they are configuration, not event-domain data.

The app starts with platform initialization only; database opening is lazy.
Queries are indexed by the event primary key and sorted by ISO-8601 target time.
There are no background services or network dependencies.

Schema v2 adds `created_at` and `updated_at`; migration backfills legacy records
without deleting data. The updater is an on-demand HTTPS client. Movia uses one
Flutter engine and one main Windows application window; there are no auxiliary
window processes.

User data path: `%APPDATA%\Ahmed Abdelaal\Movia Desktop\movia.db`.
