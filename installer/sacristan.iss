; SACRISTAN — Windows installer script (Inno Setup)
;
; What this does: packages the release build produced by
; `flutter build windows --release` into a single distributable
; SACRISTAN-Setup-<version>.exe that installs the app to the current
; user's own profile (no admin rights needed), adds a Start Menu entry,
; offers an optional desktop icon, and registers a normal Windows
; uninstaller ("Apps & features").
;
; This does NOT submit anything to the Microsoft Store — it's a
; standalone installer you can host anywhere (your own site, GitHub
; Releases, email) and hand to sacristans directly. See the "Microsoft
; Store (MSIX)" note at the bottom of this file if you want that instead
; or as well.
;
; ---------------------------------------------------------------------
; ONE-TIME SETUP (only needs doing once on this machine):
;   1. Install Inno Setup (free): https://jrsoftware.org/isdl.php
;      Any recent 6.x release works. Accept the defaults.
;   2. That's it — Inno Setup adds itself to the Start Menu and to the
;      right-click "Compile" option for .iss files.
;
; TO BUILD THE INSTALLER (every time you want a new one):
;   1. From the app folder, build the release binaries:
;        cd Desktop\SACRISTAN\SACRISTAN\app
;        flutter build windows --release
;      This produces build\windows\x64\runner\Release\ containing
;      sacristan.exe and its supporting files.
;   2. Open this file (sacristan.iss) in Inno Setup and click
;      Build > Compile (or press Ctrl+F9). It writes the finished
;      installer to installer\Output\SACRISTAN-Setup-<version>.exe.
;
; If Flutter's output folder name ever differs from what's referenced
; below (Flutter has changed this path between versions before), open
; build\windows\ in File Explorer, find the folder actually containing
; sacristan.exe, and update the "ReleaseDir" line just below to match.
; ---------------------------------------------------------------------

#define MyAppName "SACRISTAN"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "SACRISTAN"
#define MyAppExeName "sacristan.exe"
; Path is relative to this .iss file's own location (installer\).
#define ReleaseDir "..\app\build\windows\x64\runner\Release"

[Setup]
AppId={{B7B2E4B4-9C6E-4B7A-9C0A-3C3C3C0F0A11}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
; Installs into the current user's own profile (no admin prompt needed)
; rather than Program Files — a better fit for a shared parish office
; computer where whoever's signed in may not have an admin password.
; To install once for every account on the machine instead, change
; DefaultDirName to "{autopf}\{#MyAppName}" and PrivilegesRequired to
; "admin".
DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=Output
OutputBaseFilename=SACRISTAN-Setup-{#MyAppVersion}
; Uses the same icon the app itself ships with, so the installer and
; the installed app match in Explorer/Start Menu. This is the .ico
; `flutter_launcher_icons` generates from app_icon_source.png — re-run
; that tool first if you haven't yet (see README.md's "Icons" section).
SetupIconFile=..\app\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
; No code-signing certificate is applied here — see the note at the
; bottom of this file. Unsigned installers trigger a Windows SmartScreen
; warning ("Windows protected your PC") that the user has to click
; through ("More info" > "Run anyway"). That's expected until a
; certificate is added, not a sign anything is broken.

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
; Recursively bundles everything Flutter's release build produced —
; the exe, its DLLs, and the data\ folder with the compiled app assets.
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

; ---------------------------------------------------------------------
; CODE SIGNING (not set up yet — a paid step, when you're ready):
;   A code-signing certificate (roughly $70-300/year from a CA like
;   DigiCert, Sectigo, or SSL.com) lets you sign the finished .exe so
;   Windows SmartScreen stops warning people on first run. Once you
;   have one, Inno Setup can sign automatically during compile —
;   add a [Setup] line:
;     SignTool=mysigner sign /f "C:\path\to\cert.pfx" /p $q<password>$q $f
;   and register that SignTool name under Inno Setup's Tools > Configure
;   Sign Tools menu. Not required to distribute the app — just removes
;   the warning screen.
;
; MICROSOFT STORE (MSIX) — a separate, stretch-goal path:
;   If you'd rather list SACRISTAN in the Microsoft Store instead of
;   (or alongside) a direct-download installer like this one, that's a
;   different packaging format (MSIX) built through Flutter's own
;   tooling (the `msix` pub package), not this Inno Setup script, and
;   requires a (paid, one-time ~$19) Microsoft Partner Center account.
;   Ask for help setting that up separately when you're ready for it —
;   it's independent of this installer and doesn't need to happen first.
; ---------------------------------------------------------------------
