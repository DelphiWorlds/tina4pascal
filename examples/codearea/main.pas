program main;

{ <codearea> showcase — the native syntax-highlighting code editor element.

  Three editable code boxes in plain HTML:
    <codearea lang="php" line-numbers>   — built-in highlighter + line gutter
    <codearea lang="pascal">             — built-in highlighter
    <codearea lang="sql" line-numbers>   — highlighter LOADED AT RUNTIME

  The SQL highlighter is not built in: this program registers it before the UI
  opens, from languages/sql.lang on disk (LoadLanguageFromFile) or, if that file
  isn't beside the binary, from an embedded copy in memory (LoadLanguageFromString).
  Either way <codearea lang="sql"> then just works — highlighters are pluggable.

  Run it:   tina4pascal run .
  Mobile:   tina4pascal build ios   (bundle languages/ as an asset, or rely on the
            in-memory fallback below — no disk needed). }

{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}

uses
  SysUtils,
  Tina4Highlight,      // the highlighter registry (src/Tina4Highlight.pas)
  Tina4App;            // RunApp — the shared cross-platform host

const
  { Memory fallback for the SQL highlighter (same format as the .lang file). }
  SQL_DEF =
    'name = sql'#10 +
    'case = insensitive'#10 +
    'line = --'#10 +
    'block = /* */'#10 +
    'strings = '' "'#10 +
    'keywords = select from where insert into values update set delete create table'#10 +
    'keywords = drop alter join inner left right on group by order having limit as'#10 +
    'keywords = distinct and or not null is in like between union all exists'#10 +
    'types = int integer bigint varchar char text date datetime timestamp boolean';

{ Register the SQL highlighter from disk if present, else from the embedded copy. }
procedure InstallSql(const BinDir: string);
begin
  if FileExists('languages/sql.lang') then
    LoadLanguageFromFile('languages/sql.lang')
  else if FileExists(BinDir + 'languages/sql.lang') then
    LoadLanguageFromFile(BinDir + 'languages/sql.lang')
  else
    LoadLanguageFromString(SQL_DEF);
end;

var here: string;
begin
  here := ExtractFilePath(ParamStr(0));
  InstallSql(here);
  if FileExists('app.html') then
    RunApp('Tina4 codearea', GetCurrentDir, 'app.html', '{}', '', 900, 760)
  else if FileExists(here + 'app.html') then
    RunApp('Tina4 codearea', here, 'app.html', '{}', '', 900, 760)
  else
    RunApp('Tina4 codearea', '',
      '<body style="font-family:sans-serif;padding:36px">app.html was not found</body>',
      '{}', '', 900, 760);
end.
