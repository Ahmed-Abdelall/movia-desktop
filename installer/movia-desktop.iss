#define MyAppName "Movia Desktop"
#define MyAppVersion "1.2.0"
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
OutputBaseFilename=Movia-Desktop-Setup-1.2.0-rc
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
CloseApplications=yes
RestartApplications=no
UsePreviousAppDir=yes
UsePreviousTasks=yes
DisableProgramGroupPage=auto
UninstallDisplayIcon={app}\{#MyAppExeName}
VersionInfoVersion=1.2.0.3
VersionInfoProductVersion=1.2.0.0
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayName=Movia Desktop
ChangesAssociations=no
CloseApplicationsFilter=movia_desktop.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Files]
Source: "..\staging\windows-release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Movia Desktop"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\Movia Desktop"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch Movia Desktop"; Flags: nowait postinstall skipifsilent

[Code]
function IsDowngrade: Boolean;
var
  InstalledVersion: String;
begin
  Result := False;
  if RegQueryStringValue(HKCU,
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\{51ED7D03-BE63-4EEC-AD43-A91B0AF8D907}_is1',
    'DisplayVersion', InstalledVersion) then
    Result := CompareStr(InstalledVersion, '{#MyAppVersion}') > 0;
end;

function InitializeSetup: Boolean;
begin
  Result := True;
  if IsDowngrade then begin
    MsgBox('A newer Movia Desktop version is already installed.', mbError, MB_OK);
    Result := False;
  end;
end;
