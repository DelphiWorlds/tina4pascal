unit Tina4Highlight;

{ Multi-language syntax highlighter — a portable engine utility, no OS dependencies.

  A single generic lexer is driven by a THLLanguage definition (keywords, types,
  comment and string syntax). Languages live in a registry: two are built in
  (pascal, php) and more can be added at runtime from memory (RegisterLanguage /
  LoadLanguageFromString) or from disk (LoadLanguageFromFile). The <codearea lang="…">
  control resolves its highlighter by name through GetLanguage.

  Three outputs share the one lexer:
    HighlightTokens(src, lang) -> an array of (text, kind) runs — what the layout
                                  paints for <codearea>, and the lowest-level API.
    HighlightToHTML(src, lang) -> an HTML fragment of coloured <span> runs.
    HighlightInto(pre,src,lang)-> rebuilds a live <pre>'s children as span nodes.

  It lives in src/ because it is pure, reusable renderer-support code with no
  app-specific behaviour (ADR-0001). Colours are the DefaultColors table (as
  TAlphaColor for the canvas) / DefaultTheme (as CSS hex for HTML); both are the
  VS-Code-ish dark palette.

  Disk/memory language format: one "key = value" per line, lines beginning with
  the hash sign are ignored. Keys:
    name      - language name (what lang="…" matches)
    case      - "sensitive" or "insensitive" (default)
    line      - line-comment markers, space separated (e.g. the slash-slash)
    block     - one block-comment pair "start end"; repeat the key for more pairs
    strings   - the string-delimiter characters, e.g. a double and single quote
    varsigil  - optional: a sigil char so sigil+ident is a variable (PHP's dollar)
    directive - optional: a block comment starting with this prefix is a directive
    keywords  - space-separated keyword list
    types     - space-separated type-name list
  See RegisterBuiltins (bottom of this unit) for the pascal and php definitions.
}

{$mode delphi}{$H+}

interface

uses
  SysUtils, Classes, Generics.Collections, Tina4HTMLDom;

type
  { One lexical class. The lexer emits a run per contiguous span of the same kind. }
  THLKind = (hlDefault, hlKeyword, hlType, hlString, hlComment, hlNumber,
             hlDirective, hlVariable);

  THLToken = record
    Text: string;
    Kind: THLKind;
  end;

  THLTheme = array[THLKind] of string;        // CSS hex, for HTML output

  { A language definition. Build one and RegisterLanguage it, or load from text/file. }
  THLLanguage = class
  public
    Name: string;
    CaseSensitive: Boolean;
    Keywords: TStringList;      // lowercased when not case-sensitive
    Types: TStringList;
    LineComments: TStringList;  // e.g. '//', '#'
    BlockStarts: TStringList;   // paired by index with BlockEnds
    BlockEnds: TStringList;
    StringDelims: string;       // each char is a string delimiter
    VarSigil: Char;             // #0 = none; else sigil+ident is a variable ($foo)
    Directive: string;          // '' = none; a block starting with this is a directive
    constructor Create(const AName: string);
    destructor Destroy; override;
  end;

{ --- registry --- }
procedure RegisterLanguage(Lang: THLLanguage);
function  GetLanguage(const Name: string): THLLanguage;   // nil if unknown
function  LoadLanguageFromString(const Text: string): THLLanguage;  // registers + returns
function  LoadLanguageFromFile(const Path: string): THLLanguage;    // registers + returns

{ --- colours --- }
function DefaultTheme: THLTheme;                 // CSS hex per kind (HTML)
function DefaultColor(K: THLKind): TAlphaColor;  // AARRGGBB per kind (canvas)

{ --- the lexer --- }
function HighlightTokens(const Src: string; const Lang: string = 'pascal'): TArray<THLToken>;

{ --- HTML + DOM convenience built on the lexer --- }
function HighlightToHTML(const Src: string; const Lang: string = 'pascal'): string;
procedure HighlightInto(Pre: THTMLTag; const Src: string; const Lang: string = 'pascal');

implementation

var
  GRegistry: TObjectDictionary<string, THLLanguage>;

{ ---- THLLanguage ---- }

constructor THLLanguage.Create(const AName: string);
begin
  Name := AName;
  CaseSensitive := False;
  Keywords := TStringList.Create; Keywords.Sorted := True; Keywords.Duplicates := dupIgnore;
  Types := TStringList.Create; Types.Sorted := True; Types.Duplicates := dupIgnore;
  LineComments := TStringList.Create;
  BlockStarts := TStringList.Create;
  BlockEnds := TStringList.Create;
  StringDelims := '';
  VarSigil := #0;
  Directive := '';
end;

destructor THLLanguage.Destroy;
begin
  Keywords.Free; Types.Free; LineComments.Free; BlockStarts.Free; BlockEnds.Free;
  inherited;
end;

{ ---- registry ---- }

procedure RegisterLanguage(Lang: THLLanguage);
begin
  if Lang = nil then Exit;
  GRegistry.AddOrSetValue(LowerCase(Lang.Name), Lang);  // owns + frees the old one
end;

function GetLanguage(const Name: string): THLLanguage;
begin
  if not GRegistry.TryGetValue(LowerCase(Name), Result) then Result := nil;
end;

{ Split a space/tab-separated list into a stringlist (optionally lowercased). }
procedure AddWords(SL: TStringList; const S: string; Lower: Boolean);
var parts: TStringArray; w: string;
begin
  parts := S.Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
  for w in parts do
    if Lower then SL.Add(LowerCase(w)) else SL.Add(w);
end;

function LoadLanguageFromString(const Text: string): THLLanguage;
var sl: TStringList; i, ep: Integer; line, key, val: string; lang: THLLanguage;
  parts: TStringArray;
begin
  lang := THLLanguage.Create('');
  sl := TStringList.Create;
  try
    sl.Text := Text;
    for i := 0 to sl.Count - 1 do
    begin
      line := Trim(sl[i]);
      if (line = '') or (line[1] = '#') then Continue;
      ep := Pos('=', line);
      if ep = 0 then Continue;
      key := LowerCase(Trim(Copy(line, 1, ep - 1)));
      val := Trim(Copy(line, ep + 1, MaxInt));
      if key = 'name' then lang.Name := val
      else if key = 'case' then lang.CaseSensitive := SameText(val, 'sensitive')
      else if key = 'line' then AddWords(lang.LineComments, val, False)
      else if key = 'block' then
      begin
        parts := val.Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
        if Length(parts) >= 2 then
        begin lang.BlockStarts.Add(parts[0]); lang.BlockEnds.Add(parts[1]); end;
      end
      else if key = 'strings' then
        lang.StringDelims := StringReplace(val, ' ', '', [rfReplaceAll])
      else if key = 'varsigil' then begin if val <> '' then lang.VarSigil := val[1]; end
      else if key = 'directive' then lang.Directive := val
      else if key = 'keywords' then AddWords(lang.Keywords, val, not lang.CaseSensitive)
      else if key = 'types' then AddWords(lang.Types, val, not lang.CaseSensitive);
    end;
  finally
    sl.Free;
  end;
  RegisterLanguage(lang);
  Result := lang;
end;

function LoadLanguageFromFile(const Path: string): THLLanguage;
var sl: TStringList;
begin
  sl := TStringList.Create;
  try
    sl.LoadFromFile(Path);
    Result := LoadLanguageFromString(sl.Text);
  finally
    sl.Free;
  end;
end;

{ ---- colours (VS-Code-ish dark) ---- }

function DefaultTheme: THLTheme;
begin
  Result[hlDefault]   := '#d4d4d4';
  Result[hlKeyword]   := '#569cd6';
  Result[hlType]      := '#4ec9b0';
  Result[hlString]    := '#ce9178';
  Result[hlComment]   := '#6a9955';
  Result[hlNumber]    := '#b5cea8';
  Result[hlDirective] := '#dcdcaa';
  Result[hlVariable]  := '#9cdcfe';
end;

function DefaultColor(K: THLKind): TAlphaColor;
const C: array[THLKind] of TAlphaColor = (
  $FFD4D4D4, $FF569CD6, $FF4EC9B0, $FFCE9178, $FF6A9955, $FFB5CEA8, $FFDCDCAA, $FF9CDCFE);
begin
  Result := C[K];
end;

{ ---- the generic lexer ---- }

function IsIdentStart(c: Char): Boolean;
begin Result := c in ['A'..'Z','a'..'z','_']; end;
function IsIdentChar(c: Char): Boolean;
begin Result := c in ['A'..'Z','a'..'z','0'..'9','_']; end;

{ Does Src match Needle at position i (1-based)? }
function MatchAt(const Src, Needle: string; i: Integer): Boolean;
var k: Integer;
begin
  Result := False;
  if Needle = '' then Exit;
  if i + Length(Needle) - 1 > Length(Src) then Exit;
  for k := 1 to Length(Needle) do
    if Src[i + k - 1] <> Needle[k] then Exit;
  Result := True;
end;

function HighlightTokens(const Src: string; const Lang: string): TArray<THLToken>;
var
  L: THLLanguage;
  toks: TList<THLToken>;
  i, n, start, bi, matchedBlock: Integer;
  word, lw: string;
  tok: THLToken;

  procedure Emit(K: THLKind; const Text: string);
  begin
    if Text = '' then Exit;
    tok.Text := Text; tok.Kind := K; toks.Add(tok);
  end;

  function LineCommentHere: string;
  var c: Integer;
  begin
    Result := '';
    for c := 0 to L.LineComments.Count - 1 do
      if MatchAt(Src, L.LineComments[c], i) then Exit(L.LineComments[c]);
  end;

begin
  L := GetLanguage(Lang);
  if L = nil then L := GetLanguage('pascal');
  toks := TList<THLToken>.Create;
  try
    i := 1; n := Length(Src);
    while i <= n do
    begin
      // line comment
      word := LineCommentHere;
      if word <> '' then
      begin
        start := i; while (i <= n) and (Src[i] <> #10) do Inc(i);
        Emit(hlComment, Copy(Src, start, i - start));
        Continue;
      end;
      // block comment / directive
      matchedBlock := -1;
      for bi := 0 to L.BlockStarts.Count - 1 do
        if MatchAt(Src, L.BlockStarts[bi], i) then begin matchedBlock := bi; Break; end;
      if matchedBlock >= 0 then
      begin
        start := i;
        i := i + Length(L.BlockStarts[matchedBlock]);
        while (i <= n) and not MatchAt(Src, L.BlockEnds[matchedBlock], i) do Inc(i);
        if i <= n then Inc(i, Length(L.BlockEnds[matchedBlock])) else i := n + 1;
        word := Copy(Src, start, i - start);
        if (L.Directive <> '') and MatchAt(word, L.Directive, 1) then
          Emit(hlDirective, word)
        else
          Emit(hlComment, word);
        Continue;
      end;
      // string
      if (Length(L.StringDelims) > 0) and (Pos(Src[i], L.StringDelims) > 0) then
      begin
        start := i; word := Src[i]; Inc(i);
        while (i <= n) and (Src[i] <> word[1]) do
        begin
          if (Src[i] = '\') and (i < n) then Inc(i);  // skip escaped char
          Inc(i);
        end;
        if i <= n then Inc(i);
        Emit(hlString, Copy(Src, start, i - start));
        Continue;
      end;
      // variable ($foo) — a language sigil
      if (L.VarSigil <> #0) and (Src[i] = L.VarSigil) and (i < n) and IsIdentStart(Src[i+1]) then
      begin
        start := i; Inc(i);
        while (i <= n) and IsIdentChar(Src[i]) do Inc(i);
        Emit(hlVariable, Copy(Src, start, i - start));
        Continue;
      end;
      // number (incl. $-hex when $ is NOT a variable sigil)
      if (Src[i] in ['0'..'9']) or ((Src[i] = '$') and (L.VarSigil <> '$')) then
      begin
        start := i; Inc(i);
        while (i <= n) and (Src[i] in ['0'..'9','.','A'..'F','a'..'f','x','X']) do Inc(i);
        Emit(hlNumber, Copy(Src, start, i - start));
        Continue;
      end;
      // identifier / keyword / type
      if IsIdentStart(Src[i]) then
      begin
        start := i; while (i <= n) and IsIdentChar(Src[i]) do Inc(i);
        word := Copy(Src, start, i - start);
        if L.CaseSensitive then lw := word else lw := LowerCase(word);
        if L.Keywords.IndexOf(lw) >= 0 then Emit(hlKeyword, word)
        else if L.Types.IndexOf(lw) >= 0 then Emit(hlType, word)
        else Emit(hlDefault, word);
        Continue;
      end;
      // anything else — default (merge runs of default chars)
      start := i;
      while (i <= n) and not IsIdentStart(Src[i]) and not (Src[i] in ['0'..'9'])
            and (LineCommentHere = '') and (Pos(Src[i], L.StringDelims) = 0) do
      begin
        matchedBlock := -1;
        for bi := 0 to L.BlockStarts.Count - 1 do
          if MatchAt(Src, L.BlockStarts[bi], i) then begin matchedBlock := bi; Break; end;
        if matchedBlock >= 0 then Break;
        if (L.VarSigil <> #0) and (Src[i] = L.VarSigil) then Break;
        Inc(i);
      end;
      if i > start then Emit(hlDefault, Copy(Src, start, i - start))
      else begin Emit(hlDefault, Src[i]); Inc(i); end;
    end;
    Result := toks.ToArray;
  finally
    toks.Free;
  end;
end;

{ ---- HTML + DOM convenience ---- }

function Esc(const S: string): string;
var i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
    case S[i] of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
    else  Result := Result + S[i];
    end;
end;

function HighlightToHTML(const Src: string; const Lang: string): string;
var toks: TArray<THLToken>; t: THLToken; th: THLTheme;
begin
  th := DefaultTheme;
  Result := '';
  toks := HighlightTokens(Src, Lang);
  for t in toks do
    if t.Kind = hlDefault then Result := Result + Esc(t.Text)
    else Result := Result + '<span style="color:' + th[t.Kind] + '">' + Esc(t.Text) + '</span>';
end;

procedure HighlightInto(Pre: THTMLTag; const Src: string; const Lang: string);
var i: Integer; toks: TArray<THLToken>; t: THLToken; th: THLTheme; span, tn: THTMLTag;
begin
  if Pre = nil then Exit;
  for i := Pre.Children.Count - 1 downto 0 do
    Pre.Children[i].Free;
  th := DefaultTheme;
  toks := HighlightTokens(Src, Lang);
  for t in toks do
  begin
    if t.Text = '' then Continue;
    if t.Kind = hlDefault then
    begin
      tn := THTMLTag.Create; tn.TagName := '#text'; tn.Text := t.Text; tn.Parent := Pre;
      Pre.Children.Add(tn);
    end
    else
    begin
      span := THTMLTag.Create; span.TagName := 'span'; span.Parent := Pre;
      span.Style.AddOrSetValue('color', th[t.Kind]);
      tn := THTMLTag.Create; tn.TagName := '#text'; tn.Text := t.Text; tn.Parent := span;
      span.Children.Add(tn);
      Pre.Children.Add(span);
    end;
  end;
end;

{ ---- built-in languages ---- }

procedure RegisterBuiltins;
var pas, php: THLLanguage;
begin
  pas := THLLanguage.Create('pascal');
  pas.CaseSensitive := False;
  AddWords(pas.Keywords,
    'program unit uses begin end var const type procedure function if then else ' +
    'while do for to downto repeat until case of with record object interface ' +
    'implementation initialization finalization try finally except raise nil ' +
    'inherited override virtual abstract constructor destructor and or not xor ' +
    'div mod in is as out shl shr set packed property private public protected ' +
    'published forward external goto label exit', True);
  AddWords(pas.Types,
    'string integer boolean char double single real cardinal byte word longint ' +
    'int64 qword pointer variant ansistring widestring shortstring array class ' +
    'file text', True);
  pas.LineComments.Add('//');
  pas.BlockStarts.Add('{');  pas.BlockEnds.Add('}');
  pas.BlockStarts.Add('(*'); pas.BlockEnds.Add('*)');
  pas.StringDelims := '''';
  pas.Directive := '{$';
  RegisterLanguage(pas);

  php := THLLanguage.Create('php');
  php.CaseSensitive := False;
  AddWords(php.Keywords,
    'echo print if else elseif endif while endwhile do for endfor foreach ' +
    'endforeach as function return class new extends implements interface trait ' +
    'public private protected static const namespace use try catch finally throw ' +
    'switch case break continue default global isset unset empty die exit ' +
    'instanceof abstract final yield fn match readonly enum require require_once ' +
    'include include_once and or xor not clone list array', True);
  AddWords(php.Types,
    'int integer float double string bool boolean array object void mixed ' +
    'callable iterable null true false self parent static never', True);
  php.LineComments.Add('//');
  php.LineComments.Add('#');
  php.BlockStarts.Add('/*'); php.BlockEnds.Add('*/');
  php.StringDelims := '"''';
  php.VarSigil := '$';
  RegisterLanguage(php);
end;

initialization
  GRegistry := TObjectDictionary<string, THLLanguage>.Create([doOwnsValues]);
  RegisterBuiltins;
finalization
  GRegistry.Free;
end.
