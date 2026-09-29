program main;

{ Tina4Pascal lava lamp — the four-file app shape (main.pas / app.html /
  src/AppLogic.pas / tina4.json), so it builds for every target.

  All the motion lives in the portable unit AppLogic, which registers a Pascal
  painter for <canvas id="lava"> in its initialization. RunApp (Tina4App) is the
  shared cross-platform host; the same main.pas + app.html run on macOS, Windows
  and Linux, and RunApp's --dump-html lets the CLI bundle the UI for iOS/Android
  (AppLogic ships in the engine via "appUnits" in tina4.json).

  Desktop:  tina4pascal dev .            (live-edit app.html)
  Snapshot: ./main --snapshot lava.png
  Mobile:   tina4pascal build ios        (or deploy ios / build android)        }

{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}

uses
  SysUtils,
  AppLogic,            // registers the 'lava' canvas painter in its initialization
  Tina4App;            // RunApp — the shared cross-platform host

var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  if FileExists('app.html') then
    RunApp('Tina4 Lava Lamp', GetCurrentDir, 'app.html', '{}', '', 420, 720)
  else if FileExists(here + 'app.html') then
    RunApp('Tina4 Lava Lamp', here, 'app.html', '{}', '', 420, 720)
  else
    RunApp('Tina4 Lava Lamp', '',
      '<body style="margin:0;background:#0b0710">' +
      '<canvas id="lava" width="380" height="600"></canvas></body>',
      '{}', '', 420, 720);
end.
