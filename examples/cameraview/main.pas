program main;
{ <camera-view> live-preview test. The element lays out a placeholder box; the
  shell overlays a native camera preview (iOS: AVCaptureSession in Tina4View.m). }
{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}
uses SysUtils, Tina4App;
var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  if FileExists('app.html') then
    RunApp('Camera View', GetCurrentDir, 'app.html', '{}', '', 480, 800)
  else if FileExists(here + 'app.html') then
    RunApp('Camera View', here, 'app.html', '{}', '', 480, 800)
  else
    RunApp('Camera View', '', '<body style="background:#000"></body>', '{}', '', 480, 800);
end.
