program main;
{ Form + validation example. The UI is app.html; the rules are src/AppLogic.pas
  (registered as form.check), the same unit on desktop and mobile (appUnits). }
{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}
uses SysUtils, AppLogic, Tina4App;
var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  if FileExists('app.html') then
    RunApp('Forms', GetCurrentDir, 'app.html', '{}', '', 480, 640)
  else if FileExists(here + 'app.html') then
    RunApp('Forms', here, 'app.html', '{}', '', 480, 640)
  else
    RunApp('Forms', '', '<body style="padding:36px;font-family:sans-serif">app.html not found</body>', '{}', '', 480, 640);
end.
