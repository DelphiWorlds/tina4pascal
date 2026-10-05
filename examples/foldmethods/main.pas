program main;
{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}
uses SysUtils, Tina4App;
begin
  RunApp('Fold Methods', GetCurrentDir, 'app.html', '{}', '', 700, 640);
end.
