# Windows build and packaging

1. Install Flutter stable and Visual Studio 2022.
2. In Visual Studio Installer, select **Desktop development with C++**.
3. Enable Windows Developer Mode.
4. Run:

```powershell
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```

The portable release bundle is under
`build\windows\x64\runner\Release\`.

Run `tool\build_release.ps1` to produce the v1.2.1 installer, standalone
portable ZIP, Portable Installed ZIP, `build-info.json`, and SHA-256 sidecars.

## Installer

The included Inno Setup script packages the full Release directory, creates
main-app Start Menu/Desktop shortcuts, removes obsolete companion shortcuts and
startup entries during upgrade, and registers an uninstaller:

```powershell
iscc installer\movia-desktop.iss
```

The stable installer AppId is `51ED7D03-BE63-4EEC-AD43-A91B0AF8D907`; do not
change it between upgrades. Generate hashes only after the installer and
portable ZIP are final.

The portfolio release is intentionally unsigned. Windows SmartScreen may show a
warning; download binaries only from the official GitHub Release.

## Build-host note

The project was successfully built with Flutter 3.44.8 and Visual Studio Build
Tools 2022 17.14. Enable Developer Mode so Flutter can create generated plugin
links.
