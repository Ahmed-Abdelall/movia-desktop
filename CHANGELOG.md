# Changelog

## 1.2.1 — 2026-08-03

- Removed the Windows desktop companion widget and all related settings, startup behavior, shortcuts, preferences, dependencies, and update handling.
- Rebalanced Overview with a navigable event calendar and a four-item summary card.
- Kept legacy `--widget` shortcuts safe by opening the single main Movia window.
- Preserved existing event data, appearance preferences, and Portable Installed updates.

## 1.2.0 — 2026-08-02

- Redesigned the desktop shell and Overview with Movia's purple/blue visual system.
- Added build provenance to About and clean, staged release packaging.
- Hardened Windows installer identity, icon metadata, and stale-output prevention.

All notable changes to Movia Desktop are documented here.

## 1.1.0 — 2026-07-30

- Added creation/update timestamps and a non-destructive SQLite migration.
- Added secure GitHub Releases update checking and download progress.
- Repaired back navigation and protected unsaved forms.
- Added timeline groups, category identities, quick actions, and empty states.
- Added a new Windows icon and in-place installer upgrade support.

## 1.0.0 — 2026-07-29

- Initial independent Windows release.
- Added dashboard, live countdowns, calendar, and event details.
- Added event creation, editing, deletion, archive, and restore.
- Added search, sorting, categories, keyboard shortcuts, and context menus.
- Added local SQLite persistence and Android-compatible JSON import/export.
- Added English and Arabic localization, RTL, and light/dark/system themes.
- Added portable and installer release options.
