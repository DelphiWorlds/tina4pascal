program test_highlight;

{
  Real (no-mock) console test for Tina4Highlight — the multi-language syntax
  highlighter behind <codearea>. Covers the token lexer, per-language rules
  (pascal + php built in), the registry + loading a language from a string, and
  the HTML / DOM outputs. Exits 0 with 'ALL TESTS PASS'; halts 1 on first failure.
}

{$mode delphi}{$H+}

uses
  SysUtils, Tina4HTMLDom, Tina4Highlight;

var
  PassCount: Integer = 0;

procedure Check(Cond: Boolean; const Msg: string);
begin
  if Cond then Inc(PassCount)
  else begin Writeln('FAIL: ', Msg); Halt(1); end;
end;

{ Find the first token whose text = Needle; return its kind (hlDefault if absent). }
function KindOf(const Src, Lang, Needle: string): THLKind;
var t: THLToken;
begin
  Result := hlDefault;
  for t in HighlightTokens(Src, Lang) do
    if t.Text = Needle then Exit(t.Kind);
end;

function Coloured(const Html, Needle: string; Kind: THLKind): Boolean;
var th: THLTheme;
begin
  th := DefaultTheme;
  Result := Pos('<span style="color:' + th[Kind] + '">' + Needle + '</span>', Html) > 0;
end;

var
  html: string;
  th: THLTheme;
  pre: THTMLTag;
  i, spans: Integer;
  lang: THLLanguage;
begin
  { --- pascal tokens --- }
  Check(KindOf('procedure Up;', 'pascal', 'procedure') = hlKeyword, 'pascal keyword');
  Check(KindOf('var t: Integer;', 'pascal', 'Integer') = hlType, 'pascal type');
  Check(KindOf('x := ''hi'';', 'pascal', '''hi''') = hlString, 'pascal string');
  Check(KindOf('n := 42;', 'pascal', '42') = hlNumber, 'pascal number');
  Check(KindOf('// hey', 'pascal', '// hey') = hlComment, 'pascal line comment');
  Check(KindOf('{ note }', 'pascal', '{ note }') = hlComment, 'pascal brace comment');
  Check(KindOf('{$IFDEF X}', 'pascal', '{$IFDEF X}') = hlDirective, 'pascal directive');
  Check(KindOf('MyIdent', 'pascal', 'MyIdent') = hlDefault, 'pascal plain identifier');

  { --- php tokens: keyword, variable ($), hash comment, double-quoted string --- }
  Check(KindOf('function greet($n)', 'php', 'function') = hlKeyword, 'php keyword');
  Check(KindOf('$msg = 1;', 'php', '$msg') = hlVariable, 'php $variable');
  Check(KindOf('# shell style', 'php', '# shell style') = hlComment, 'php hash comment');
  Check(KindOf('$x = "hi";', 'php', '"hi"') = hlString, 'php double-quoted string');
  Check(KindOf('return int;', 'php', 'int') = hlType, 'php type');
  { case-insensitive keywords: FUNCTION == function }
  Check(KindOf('FUNCTION f()', 'php', 'FUNCTION') = hlKeyword, 'php keyword case-insensitive');

  { --- registry + unknown lang falls back to pascal --- }
  Check(GetLanguage('pascal') <> nil, 'registry has pascal');
  Check(GetLanguage('php') <> nil, 'registry has php');
  Check(GetLanguage('no-such-lang') = nil, 'registry misses unknown');
  Check(KindOf('begin', 'no-such-lang', 'begin') = hlKeyword, 'unknown lang falls back to pascal');

  { --- load a language from a string (memory) and use it --- }
  lang := LoadLanguageFromString(
    'name = toy'#10 +
    'line = //'#10 +
    'strings = "'#10 +
    'keywords = let fn'#10 +
    'types = num');
  Check(lang <> nil, 'LoadLanguageFromString returns a language');
  Check(GetLanguage('toy') <> nil, 'loaded language is registered');
  Check(KindOf('let x', 'toy', 'let') = hlKeyword, 'toy keyword from loaded def');
  Check(KindOf('x: num', 'toy', 'num') = hlType, 'toy type from loaded def');
  Check(KindOf('x "s"', 'toy', '"s"') = hlString, 'toy string from loaded def');

  { --- HTML output --- }
  html := HighlightToHTML('var t: Integer;', 'pascal');
  Check(Coloured(html, 'var', hlKeyword), 'HTML: keyword span');
  Check(Coloured(html, 'Integer', hlType), 'HTML: type span');
  html := HighlightToHTML('if a < b then', 'pascal');
  Check(Pos('&lt;', html) > 0, 'HTML: < escaped');

  { --- DOM output: HighlightInto rebuilds span nodes, replacing old ones --- }
  pre := THTMLTag.Create;
  try
    pre.TagName := 'pre';
    HighlightInto(pre, 'begin', 'pascal');
    th := DefaultTheme;
    Check(SameText(pre.Children[0].TagName, 'span'), 'DOM: keyword is a span');
    Check(pre.Children[0].Style['color'] = th[hlKeyword], 'DOM: span keyword colour');
    HighlightInto(pre, 'end;', 'pascal');
    spans := 0;
    for i := 0 to pre.Children.Count - 1 do
      if SameText(pre.Children[i].TagName, 'span') then Inc(spans);
    Check(spans = 1, 'DOM: re-highlight replaces old children (1 span for "end")');
  finally
    pre.Free;
  end;

  Writeln;
  Writeln(PassCount, ' assertions passed.');
  Writeln('ALL TESTS PASS');
end.
