MOVIA DESKTOP 1.2.0 - PORTABLE INSTALLED MODE

This package installs Movia without running an installer executable or requiring
administrator privileges.

1. Extract this ZIP completely.
2. Open PowerShell in the extracted folder.
3. Verify the package:
     powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\verify-package.ps1
4. Install with Start Menu, Desktop, and widget shortcuts:
     powershell -NoProfile -ExecutionPolicy RemoteSigned -File .\install-portable.ps1 -Source .\Movia -DesktopShortcut -WidgetShortcut

Application: %LOCALAPPDATA%\Programs\Movia\movia_desktop.exe
User data:   %APPDATA%\Ahmed Abdelaal\Movia Desktop\

The installation script verifies the approved executable SHA-256, backs up the
previous application folder, preserves AppData, and rolls back if launch fails.
It does not change Smart App Control, WDAC, Defender, Secure Boot, or security
policy. Keep the whole extracted package until installation succeeds.

UNINSTALL

Run uninstall-portable.ps1. Application files and shortcuts are removed. User
data is kept by default. Deleting data requires the separate -DeleteUserData
switch and an exact typed confirmation.

DEPLOYMENT MODES

- Traditional Installer: for unrestricted Windows devices; not verified on this
  Smart App Control device because Inno Setup's temporary executable is blocked.
- Portable Installed Mode: stable LocalAppData location plus shortcuts and safe
  replacement/rollback scripts. This is the recommended mode for this device.
- Standalone Portable Mode: extract anywhere and run movia_desktop.exe directly.

SMART APP CONTROL

Windows decides whether each new binary is authorized. If a future update is
blocked, keep or restore the previous working version. Source code cannot
guarantee Smart App Control authorization.
