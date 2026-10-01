program main;
{ Animated parallax mountains behind the flamingo + cheetah. The ranges are 2D
  canvases drawn in src/AppLogic.pas; CSS @keyframes drift each at its own speed. }
{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}
uses SysUtils, AppLogic, Tina4App;
var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  if FileExists('app.html') then
    RunApp('Mountains', GetCurrentDir, 'app.html', '{}', '', 480, 640)
  else if FileExists(here + 'app.html') then
    RunApp('Mountains', here, 'app.html', '{}', '', 480, 640)
  else
    RunApp('Mountains', '', '<body style="padding:36px;font-family:sans-serif">app.html not found</body>', '{}', '', 480, 640);
end.
