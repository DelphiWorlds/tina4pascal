program main;
{ Multi-screen app — ONE html file, many screens. The UI is app.html; navigation
  is the engine's BUILT-IN view.show action (clone an inline <template> into the
  #stage container), so there is no app logic unit at all. The same mechanism
  also loads screens from separate files or a URL: view.load('stage','next.html').

  A screen that needs behaviour (buttons that mutate state) would add a
  src/AppLogic.pas like the other examples; this one stays pure HTML on purpose. }
{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}
{ Tina4EmbeddedPages is GENERATED from pages/ at build (`tina4pascal pages`, run
  automatically by dev/build/deploy); its initialization welds each page into the
  binary. On mobile it is auto-added to the host uses, so this line is desktop's
  opt-in. The Stats screen loads from it with no file on disk. }
uses SysUtils, Tina4EmbeddedPages, Tina4App;
var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  if FileExists('app.html') then
    RunApp('Screens', GetCurrentDir, 'app.html', '{}', '', 390, 760)
  else if FileExists(here + 'app.html') then
    RunApp('Screens', here, 'app.html', '{}', '', 390, 760)
  else
    RunApp('Screens', '', '<body style="padding:36px;font-family:sans-serif">app.html not found</body>', '{}', '', 390, 760);
end.
