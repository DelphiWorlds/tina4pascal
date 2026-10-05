program main;
{ <recorder> mic-capture test (issue #1 E3). Tap to record → an .m4a; the engine
  stamps the filename on the control and routes the clip to <audio id="recaudio">. }
{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}
uses SysUtils, Tina4App;
var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  if FileExists('app.html') then
    RunApp('Recorder', GetCurrentDir, 'app.html', '{}', '', 480, 720)
  else if FileExists(here + 'app.html') then
    RunApp('Recorder', here, 'app.html', '{}', '', 480, 720)
  else
    RunApp('Recorder', '', '<body>app.html not found</body>', '{}', '', 480, 720);
end.
