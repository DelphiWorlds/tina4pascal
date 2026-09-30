program main;

{$mode delphi}{$H+}

uses
  SysUtils, Tina4App, LocationDemo
  {$IFDEF DARWIN}, Tina4LocationMacOS{$ENDIF};

begin
  if FileExists(ExtractFilePath(ParamStr(0)) + '../Resources/app.html') then
    RunApp('Tina4 Location Demo', ExpandFileName(ExtractFilePath(ParamStr(0)) + '../Resources'),
      'app.html', '{}', '', 440, 720)
  else if FileExists('app.html') then
    RunApp('Tina4 Location Demo', GetCurrentDir, 'app.html', '{}', '', 440, 720)
  else
    RunApp('Tina4 Location Demo', '', '<body><h1>Location demo</h1></body>', '{}', '', 440, 720);
end.
