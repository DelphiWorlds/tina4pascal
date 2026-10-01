program main;
{ Bar-chart example. UI in app.html; bars (re)built in src/AppLogic.pas. }
{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}
uses SysUtils, AppLogic, Tina4App;
var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  if FileExists('app.html') then
    RunApp('Chart', GetCurrentDir, 'app.html', '{}', '', 600, 560)
  else if FileExists(here + 'app.html') then
    RunApp('Chart', here, 'app.html', '{}', '', 600, 560)
  else
    RunApp('Chart', '', '<body style="padding:36px;font-family:sans-serif">app.html not found</body>', '{}', '', 600, 560);
end.
