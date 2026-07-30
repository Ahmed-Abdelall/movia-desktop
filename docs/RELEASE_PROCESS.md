# Release process

1. Set the same version in `pubspec.yaml` and Inno Setup.
2. Run dependency restore, analysis, tests, clean restore, and Windows release build.
3. Compile `installer/movia-desktop.iss` and ZIP the release runner directory.
4. Generate SHA-256 sidecars after artifacts are final.
5. Install v1.0.0, create data/settings, upgrade, and verify AppData, one install,
   version metadata, shortcuts, and the uninstall entry.
6. Tag `v{version}`. The Windows workflow validates and creates a draft release.
7. Review artifacts and notes, then explicitly publish the draft.

Do not add signing secrets. Unsigned releases are permitted with a SmartScreen notice.
