program main;

{ Code viewer — syntax-highlighted Pascal, rendered natively by tina4pascal.

  The whole trick is one reusable engine unit: Tina4Highlight tokenizes source
  into coloured <span> runs; the engine renders them in a <pre> with a monospace
  font. No WebView, no JavaScript — just HTML the engine already draws.

  Run it:   tina4pascal run .                 (shows the embedded sample)
            ./main path/to/File.pas           (view any Pascal file)
  Mobile:   tina4pascal build ios|android     (--dump-html bakes the highlighted
            page at build time — no highlighter needed on the device). }

{$mode delphi}{$H+}
{$IFDEF WINDOWS}{$apptype gui}{$ENDIF}

uses
  SysUtils, Classes,
  Tina4Highlight,      // the reusable lexer: src/Tina4Highlight.pas
  Tina4App;            // RunApp — the shared cross-platform host

const
  SAMPLE =
    '{ A tiny Tina4Pascal action — state in, DOM out. }'#10 +
    'procedure Up(const Args: string);'#10 +
    'var t: THTMLTag;'#10 +
    'begin'#10 +
    '  Inc(Count);              // bump the counter'#10 +
    '  t := FindById(BuiltinsRoot, ''count'');'#10 +
    '  if t <> nil then'#10 +
    '    SetElementText(t, IntToStr(Count));'#10 +
    '  BuiltinsDirty := True;   {$IFDEF DEBUG} WriteLn(Count); {$ENDIF}'#10 +
    'end;'#10;

{ Read a whole text file into a string (for the optional file argument). }
function LoadFile(const Path: string): string;
var sl: TStringList;
begin
  sl := TStringList.Create;
  try
    sl.LoadFromFile(Path);
    Result := sl.Text;
  finally
    sl.Free;
  end;
end;

{ Wrap the highlighted fragment in a dark editor-style page. }
function BuildPage(const Title, Src: string): string;
begin
  Result :=
    '<body style="margin:0;background:#1e1e1e;font-family:sans-serif">' +
    '<div style="max-width:760px;margin:0 auto;padding:28px">' +
    '<div style="color:#808080;font-size:13px;font-weight:bold;letter-spacing:2px;' +
       'text-transform:uppercase;margin-bottom:14px">' + Title + '</div>' +
    '<pre style="background:#252526;border:1px solid #333;border-radius:10px;' +
       'padding:20px;margin:0;font-family:monospace;font-size:15px;line-height:1.55;' +
       'white-space:pre;color:#d4d4d4;overflow:auto">' +
       HighlightToHTML(Src) + '</pre>' +
    '</div></body>';
end;

var src, title: string;
begin
  if (ParamCount >= 1) and FileExists(ParamStr(1)) then
  begin
    src := LoadFile(ParamStr(1));
    title := 'Tina4 Code Viewer · ' + ExtractFileName(ParamStr(1));
  end
  else
  begin
    src := SAMPLE;
    title := 'Tina4 Code Viewer';
  end;
  RunApp('Tina4 Code Viewer', '', BuildPage(title, src), '{}', '', 820, 560);
end.
