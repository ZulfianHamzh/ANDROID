; ============================================================
; DHBH POS — Windows Installer (Inno Setup)
; ------------------------------------------------------------
; Build order:
;   1. flutter build windows --release
;   2. Open this file in Inno Setup Compiler (v6+) and click Build
;   3. Output: installer\Output\DHBH-POS-Setup.exe
;
; Per-user install (no UAC), desktop + Start Menu shortcuts.
; ============================================================

#define MyAppName "DHBH POS"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "DHBH"
#define MyAppExeName "dhbh_app.exe"
#define MyAppIcon "..\windows\runner\resources\app_icon.ico"
#define SourceReleaseDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{8E5C6C22-0A3B-4F1E-9D4C-1A2B3C4D5E6F}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=Output
OutputBaseFilename=DHBH-POS-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile={#MyAppIcon}
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
Source: "{#SourceReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
