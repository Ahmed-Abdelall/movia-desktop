# Movia Desktop v1.1.0

Movia 1.1.0 adds a movable, resizable desktop countdown companion with Compact,
Countdown, and Upcoming styles. Widget position, size, selected event, opacity,
theme, lock, and always-on-top preferences persist.

Events now preserve localized creation and modification dates through SQLite and
JSON. Existing v1.0.0 databases migrate in place without a reset. Navigation is
predictable with visible Back actions, Escape, Alt+Left, and unsaved-form
confirmation.

The dashboard now groups events into Today, Tomorrow, This Week, This Month, and
Later. Categories have icon-and-color identities, rows expose quick actions, and
empty screens provide useful next steps.

Settings includes a non-blocking GitHub Releases updater. Stable checks reject
drafts and prereleases, select only the expected installer, and verify SHA-256
when a checksum asset is available. The installer retains the v1.0.0 AppId for
an in-place upgrade and user data remains in AppData.

Movia remains unsigned, so Windows SmartScreen may show an unknown-publisher
warning. No analytics, accounts, cloud service, or background service was added.
