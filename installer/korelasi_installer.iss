[Setup]
AppId={{83A1E8F4-5C6B-4A2A-9D2A-0A61B3C48F12}}
AppName=Korelasi
AppVersion=1.0.0
AppPublisher=Korelasi
DefaultDirName={pf}\Korelasi
DefaultGroupName=Korelasi
OutputDir=out
OutputBaseFilename=Korelasi-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\korelasi.exe
PrivilegesRequired=admin
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs
Source: "bin\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\Korelasi"; Filename: "{app}\korelasi.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall Korelasi"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Korelasi"; Filename: "{app}\korelasi.exe"; WorkingDir: "{app}"

[Run]
Filename: "{app}\korelasi.exe"; Description: "Jalankan Korelasi"; Flags: nowait postinstall skipifsilent
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Menginstal Microsoft Visual C++ Redistributable"; Flags: waituntilterminated; Check: not IsVCInstalled

[Code]
function IsVCInstalled: Boolean;
var v: Cardinal;
begin
  if RegQueryDWordValue(HKLM, 'SOFTWARE\\Microsoft\\VisualStudio\\14.0\\VC\\Runtimes\\x64', 'Installed', v) then
    Result := v = 1
  else
    Result := False;
end;
