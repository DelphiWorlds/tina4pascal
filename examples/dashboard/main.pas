program main;
{ Native operations dashboard — HTML + the default tina4pascal.css + Pascal actions.
  No JavaScript: the chart is pure CSS, the theme toggle and buttons are AppLogic. }
{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}
uses SysUtils, AppLogic, Tina4App;
var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  if FileExists('app.html') then
    RunApp('Dashboard', GetCurrentDir, 'app.html', '{}', '', 1120, 820)
  else if FileExists(here + 'app.html') then
    RunApp('Dashboard', here, 'app.html', '{}', '', 1120, 820)
  else
    RunApp('Dashboard', '', '<body style="padding:36px;font-family:sans-serif">app.html not found</body>', '{}', '', 1120, 820);
end.
