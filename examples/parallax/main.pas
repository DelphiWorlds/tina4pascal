program main;
{ Parallax showcase: fixed backdrop + onscroll-driven logo drift + CSS perspective.
  Behaviour (the scroll-linked layer moves) lives in src/AppLogic.pas via the
  engine's onscroll dispatch. Same main.pas + app.html on every platform. }
{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}
uses SysUtils, AppLogic, Tina4App;
var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  if FileExists('app.html') then
    RunApp('Parallax', GetCurrentDir, 'app.html', '{}', '', 480, 640)
  else if FileExists(here + 'app.html') then
    RunApp('Parallax', here, 'app.html', '{}', '', 480, 640)
  else
    RunApp('Parallax', '', '<body style="padding:36px;font-family:sans-serif">app.html not found</body>', '{}', '', 480, 640);
end.
