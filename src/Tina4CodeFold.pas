unit Tina4CodeFold;

{ Code folding for <codearea>. Pure logic — no OS, no canvas, no DOM — so the
  renderer (Tina4HTMLLayout) and the click handler (Tina4Interact) fold IDENTICALLY
  from one definition, and the rules are unit-testable on their own (ADR-0010).

  Two fold shapes, chosen per language by TFoldRules:
  - Indentation (the universal default): a "header" is a line whose following
    lines are indented deeper; its block hides until the indent returns.
  - Routine (Pascal etc.): a `procedure`/`function`/… declaration is the header and
    the WHOLE body folds into the signature — the begin/end is hidden, not a fold
    of its own. Inner indented blocks (an `if` with a deeper body) still fold. }

{$mode delphi}{$H+}

interface

uses SysUtils, Classes;

type
  TFoldLine = record
    SrcIdx:    Integer;   // 0-based index into the original source lines
    Foldable:  Boolean;   // this line opens a foldable block
    Collapsed: Boolean;   // Foldable AND currently collapsed (shows the ⋯ marker)
  end;
  TFoldView = array of TFoldLine;
  TFoldIndices = array of Integer;   // a set of collapsed header line indices

  { Per-language fold behaviour. With Active=False it is pure indentation folding. }
  TFoldRules = record
    Active:      Boolean;          // language-aware (routine) folding on top of indent
    Routines:   array of string;  // lowercase keywords that OPEN a routine (fold to Terminator)
    Terminator: string;           // lowercase word that CLOSES a routine (e.g. 'end')
    Suppress:   array of string;  // lowercase keywords that never get their own indent arrow ('begin')
  end;

{ Leading-whitespace width in columns; a tab advances to the next TabW multiple. }
function LeadingIndent(const S: string; TabW: Integer = 4): Integer;

{ A blank line is empty or all whitespace — it never defines block structure. }
function IsBlankLine(const S: string): Boolean;

{ Fold rules for a <codearea lang="…">. Pascal folds routines into their signature;
  everything else folds by indentation. }
function FoldRulesForLang(const Lang: string): TFoldRules;

{ True when line Header (0-based) opens a foldable block under the given rules. }
function IsFoldHeader(Lines: TStrings; Header: Integer; const Rules: TFoldRules;
  TabW: Integer = 4): Boolean;

{ Last source line belonging to Header's block (trailing blanks trimmed). Returns
  Header itself when it is not a foldable header. }
function FoldRangeEnd(Lines: TStrings; Header: Integer; const Rules: TFoldRules;
  TabW: Integer = 4): Integer;

{ The visible lines in order: every line inside a collapsed header's range is
  omitted (the header stays, flagged Collapsed). A collapsed entry that is no longer
  a real header is ignored, so the view self-heals after edits. }
function ComputeFoldView(Lines: TStrings; const Collapsed: array of Integer;
  const Rules: TFoldRules; TabW: Integer = 4): TFoldView;

{ Parse / format the tag's `_folds` attribute (comma-separated header indices). }
function ParseFolds(const S: string): TFoldIndices;
function FoldsToStr(const A: array of Integer): string;

{ Add V if absent, remove it if present — the click-to-toggle primitive. }
function ToggleFold(const A: array of Integer; V: Integer): TFoldIndices;

implementation

function LeadingIndent(const S: string; TabW: Integer = 4): Integer;
var i: Integer;
begin
  Result := 0;
  for i := 1 to Length(S) do
    case S[i] of
      ' ':  Inc(Result);
      #9:   Result := ((Result div TabW) + 1) * TabW;
    else
      Exit;   // first non-whitespace: indent settled
    end;
end;

function IsBlankLine(const S: string): Boolean;
begin
  Result := Trim(S) = '';
end;

{ Does the lower-cased, left-trimmed line begin with one of Words as a whole word
  (the next char is not an identifier char)? }
function StartsWithKeyword(const LowerTrimmed: string; const Words: array of string): Boolean;
var i, n: Integer; w: string; c: Char;
begin
  Result := False;
  for i := 0 to High(Words) do
  begin
    w := Words[i]; n := Length(w);
    if (n > 0) and (Length(LowerTrimmed) >= n) and (Copy(LowerTrimmed, 1, n) = w) then
    begin
      if Length(LowerTrimmed) = n then Exit(True);
      c := LowerTrimmed[n + 1];
      if not (((c >= 'a') and (c <= 'z')) or ((c >= '0') and (c <= '9')) or (c = '_')) then
        Exit(True);
    end;
  end;
end;

function LowerLeft(const S: string): string;   // lower-cased, left-trimmed line
begin
  Result := LowerCase(TrimLeft(S));
end;

function FoldRulesForLang(const Lang: string): TFoldRules;
var l: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Active := False;
  l := LowerCase(Trim(Lang));
  if (l = 'pascal') or (l = 'pas') or (l = 'delphi') or (l = 'objectpascal')
     or (l = 'fpc') or (l = 'lazarus') then
  begin
    Result.Active := True;
    Result.Routines := ['procedure', 'function', 'constructor', 'destructor', 'operator'];
    Result.Terminator := 'end';
    Result.Suppress := ['begin'];
  end;
end;

{ Index of the next non-blank line after Header, or -1 if none. }
function NextNonBlank(Lines: TStrings; Header: Integer): Integer;
var j: Integer;
begin
  Result := -1;
  for j := Header + 1 to Lines.Count - 1 do
    if not IsBlankLine(Lines[j]) then Exit(j);
end;

{ A routine header's range: from the line after Header to the routine's closing
  terminator (the first line at indent <= the header's, starting with Terminator —
  that line is INCLUDED so begin/end both hide). If the next routine at the same or
  lower indent is reached first, the range ends at the previous non-blank line. }
function RoutineRangeEnd(Lines: TStrings; Header: Integer; const Rules: TFoldRules;
  TabW: Integer): Integer;
var base, j, last, ind: Integer; tl: string;
begin
  base := LeadingIndent(Lines[Header], TabW);
  last := Header;
  j := Header + 1;
  while j < Lines.Count do
  begin
    if not IsBlankLine(Lines[j]) then
    begin
      ind := LeadingIndent(Lines[j], TabW);
      tl := LowerLeft(Lines[j]);
      if ind <= base then
      begin
        if StartsWithKeyword(tl, [Rules.Terminator]) then Exit(j);  // routine close — include it
        if StartsWithKeyword(tl, Rules.Routines) then Break;         // next routine starts
      end;
      last := j;
    end;
    Inc(j);
  end;
  Result := last;
end;

function IsRoutineHeader(Lines: TStrings; Header: Integer; const Rules: TFoldRules): Boolean;
begin
  Result := Rules.Active and (Header >= 0) and (Header < Lines.Count)
            and not IsBlankLine(Lines[Header])
            and StartsWithKeyword(LowerLeft(Lines[Header]), Rules.Routines);
end;

function IsFoldHeader(Lines: TStrings; Header: Integer; const Rules: TFoldRules;
  TabW: Integer = 4): Boolean;
var nxt: Integer;
begin
  Result := False;
  if (Header < 0) or (Header >= Lines.Count) or IsBlankLine(Lines[Header]) then Exit;
  if IsRoutineHeader(Lines, Header, Rules) then
    Exit(RoutineRangeEnd(Lines, Header, Rules, TabW) > Header);   // foldable only if it has a body
  // a suppressed keyword (begin) never gets its own indentation arrow
  if Rules.Active and StartsWithKeyword(LowerLeft(Lines[Header]), Rules.Suppress) then Exit;
  nxt := NextNonBlank(Lines, Header);
  if nxt < 0 then Exit;
  Result := LeadingIndent(Lines[nxt], TabW) > LeadingIndent(Lines[Header], TabW);
end;

function FoldRangeEnd(Lines: TStrings; Header: Integer; const Rules: TFoldRules;
  TabW: Integer = 4): Integer;
var base, j, last: Integer;
begin
  Result := Header;
  if not IsFoldHeader(Lines, Header, Rules, TabW) then Exit;
  if IsRoutineHeader(Lines, Header, Rules) then Exit(RoutineRangeEnd(Lines, Header, Rules, TabW));
  // indentation block: extend while deeper-or-blank, trimming trailing blanks
  base := LeadingIndent(Lines[Header], TabW);
  last := Header;
  j := Header + 1;
  while j < Lines.Count do
  begin
    if IsBlankLine(Lines[j]) then begin Inc(j); Continue; end;
    if LeadingIndent(Lines[j], TabW) <= base then Break;
    last := j;
    Inc(j);
  end;
  Result := last;
end;

function InSet(const A: array of Integer; V: Integer): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to High(A) do
    if A[i] = V then Exit(True);
end;

function ComputeFoldView(Lines: TStrings; const Collapsed: array of Integer;
  const Rules: TFoldRules; TabW: Integer = 4): TFoldView;
var
  hidden: array of Boolean;
  i, j, e, n, vis: Integer;
begin
  n := Lines.Count;
  SetLength(hidden, n);
  for i := 0 to n - 1 do hidden[i] := False;

  { Hide the body of every collapsed header that is still a real header. Nested
    collapses just re-mark already-hidden lines, so order does not matter. }
  for i := 0 to n - 1 do
    if InSet(Collapsed, i) and IsFoldHeader(Lines, i, Rules, TabW) then
    begin
      e := FoldRangeEnd(Lines, i, Rules, TabW);
      for j := i + 1 to e do hidden[j] := True;
    end;

  SetLength(Result, n);
  vis := 0;
  for i := 0 to n - 1 do
    if not hidden[i] then
    begin
      Result[vis].SrcIdx    := i;
      Result[vis].Foldable  := IsFoldHeader(Lines, i, Rules, TabW);
      Result[vis].Collapsed := Result[vis].Foldable and InSet(Collapsed, i);
      Inc(vis);
    end;
  SetLength(Result, vis);
end;

function ParseFolds(const S: string): TFoldIndices;
var parts: TStringArray; i, k, v, n: Integer; dup: Boolean;
begin
  Result := nil;
  n := 0;
  if Trim(S) = '' then Exit;
  parts := S.Split([',']);
  SetLength(Result, Length(parts));
  for i := 0 to High(parts) do
    if TryStrToInt(Trim(parts[i]), v) and (v >= 0) then
    begin
      dup := False;                        // dedupe against the FILLED prefix only
      for k := 0 to n - 1 do if Result[k] = v then begin dup := True; Break; end;
      if not dup then begin Result[n] := v; Inc(n); end;
    end;
  SetLength(Result, n);
end;

function FoldsToStr(const A: array of Integer): string;
var i: Integer;
begin
  Result := '';
  for i := 0 to High(A) do
  begin
    if Result <> '' then Result := Result + ',';
    Result := Result + IntToStr(A[i]);
  end;
end;

function ToggleFold(const A: array of Integer; V: Integer): TFoldIndices;
var i, n: Integer;
begin
  Result := nil;
  if InSet(A, V) then
  begin
    SetLength(Result, 0);
    for i := 0 to High(A) do
      if A[i] <> V then
      begin
        n := Length(Result); SetLength(Result, n + 1); Result[n] := A[i];
      end;
  end
  else
  begin
    SetLength(Result, Length(A) + 1);
    for i := 0 to High(A) do Result[i] := A[i];
    Result[High(Result)] := V;
  end;
end;

end.
