# Desktop widget

The widget is a second Flutter window in the same Movia process, not a Windows
11 Widget Board integration. It reads the same SQLite database and preferences.
Only one widget window is created.

- Compact shows icon, title, days, and date.
- Countdown adds hours, minutes, and seconds.
- Upcoming shows the next three active events.

Drag to move, resize while unlocked, and right-click for settings. Double-click
opens the event in Movia. Position, size, event, opacity, style, lock, and
topmost state persist. If the selected event disappears, the next active event
is selected.

Start-with-Windows writes the current user's standard Run registry entry after
explicit opt-in and requires no administrator privileges.
