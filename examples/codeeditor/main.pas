program main;

{ Live syntax-highlighting code editor — one native <codearea> element.

  <codearea lang="pascal" line-numbers> is a first-class control: editable like a
  textarea, but painted as coloured tokens by the engine's Tina4Highlight registry.
  No app code, no overlay — the highlighting is the element. Change lang="…" to any
  registered language (php is built in; load more from disk with LoadLanguageFromFile).

  Run it:   tina4pascal dev .          (desktop, live-edit app.html)
  Mobile:   tina4pascal build ios      (or: build android) }

{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}

uses SysUtils, Tina4App;

var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  if FileExists('app.html') then
    RunApp('Tina4 Code Editor', GetCurrentDir, 'app.html', '{}', '', 900, 560)
  else if FileExists(here + 'app.html') then
    RunApp('Tina4 Code Editor', here, 'app.html', '{}', '', 900, 560)
  else
    RunApp('Tina4 Code Editor', '',
      '<body style="font-family:sans-serif;padding:36px">app.html was not found</body>',
      '{}', '', 900, 560);
end.
