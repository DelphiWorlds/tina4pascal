program main;

{ CSS + HTML lava lamp — no canvas, no app logic. The whole animation is CSS
  (@keyframes + a blur/contrast "goo" filter), which the engine interpolates on
  its own ticker. So the host is just RunApp pointed at app.html.

  Desktop:  tina4pascal dev .
  Snapshot: ./main --snapshot lava.png                                         }

{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}

uses
  SysUtils,
  Tina4App;            // RunApp — the shared cross-platform host

var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  if FileExists('app.html') then
    RunApp('Tina4 Lava Lamp (CSS)', GetCurrentDir, 'app.html', '{}', '', 420, 720)
  else if FileExists(here + 'app.html') then
    RunApp('Tina4 Lava Lamp (CSS)', here, 'app.html', '{}', '', 420, 720)
  else
    RunApp('Tina4 Lava Lamp (CSS)', '',
      '<body style="background:#0b0710;color:#fff;font-family:sans-serif;padding:36px">' +
      'app.html was not found</body>', '{}', '', 420, 720);
end.
