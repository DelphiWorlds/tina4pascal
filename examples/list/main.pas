program main;
{ Live data-table example. UI in app.html; add/delete/clear in src/AppLogic.pas. }
{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}
uses SysUtils, AppLogic, Tina4App;
var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  if FileExists('app.html') then
    RunApp('List', GetCurrentDir, 'app.html', '{}', '', 600, 640)
  else if FileExists(here + 'app.html') then
    RunApp('List', here, 'app.html', '{}', '', 600, 640)
  else
    RunApp('List', '', '<body style="padding:36px;font-family:sans-serif">app.html not found</body>', '{}', '', 600, 640);
end.
