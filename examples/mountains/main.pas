program main;
{ Parallax desert scene — layered image depths (far range, range, rock ledge, duo)
  with gentle CSS sway/bob. Pure HTML + CSS + images; no app code, no WebView. }
{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}
uses SysUtils, Tina4App;
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
