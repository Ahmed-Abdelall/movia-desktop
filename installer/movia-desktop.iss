#define MyAppName "Movia Desktop"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Ahmed Abdelaal"
#define MyAppExeName "movia_desktop.exe"

[Setup]
AppId={{51ED7D03-BE63-4EEC-AD43-A91B0AF8D907}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Movia
DefaultGroupName=Movia Desktop
OutputDir=..\release
OutputBaseFilename=Movia-Desktop-Setup-1.0.0
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Movia Desktop"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\Movia Desktop"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch Movia Desktop"; Flags: nowait postinstall skipifsilent
