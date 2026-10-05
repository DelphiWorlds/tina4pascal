unit Tina4CodeFold;

{ Indentation-based code folding for <codearea>. Pure logic — no OS, no canvas,
  no DOM — so the renderer (Tina4HTMLLayout) and the click handler (Tina4Interact)
  fold IDENTICALLY from one definition, and the rules are unit-testable on their
  own. A "fold header" is a line whose block (the following, more-indented lines)
  can be hidden. Language-aware brackets can layer on later behind the same view. }

{$mode delphi}{$H+}

interface

uses SysUtils, Classes;

type
  TFoldLine = record
    SrcIdx:    Integer;   // 0-based index into the original source lines
    Foldable:  Boolean;   // this line starts a foldable (deeper-indented) block
    Collapsed: Boolean;   // Foldable AND currently collapsed (shows the ⋯ marker)
  end;
  TFoldView = array of TFoldLine;
  TFoldIndices = array of Integer;   // a set of collapsed header line indices

{ Leading-whitespace width in columns; a tab advances to the next TabW multiple. }
function LeadingIndent(const S: string; TabW: Integer = 4): Integer;

{ A blank line is empty or all whitespace — it never defines block structure. }
function IsBlankLine(const S: string): Boolean;

{ True when line Header (0-based) opens a foldable block: the next non-blank line
  is indented deeper than it. }
function IsFoldHeader(Lines: TStrings; Header, TabW: Integer): Boolean;

{ Last source line belonging to Header's block, with trailing blank lines trimmed
  off. Returns Header itself when Header is not a foldable header. }
function FoldRangeEnd(Lines: TStrings; Header, TabW: Integer): Integer;

{ The visible lines in order: every line inside a collapsed header's range is
  omitted (the header line stays, flagged Collapsed). A collapsed entry in the set
  that is no longer a real header is ignored, so the view self-heals after edits. }
function ComputeFoldView(Lines: TStrings; const Collapsed: array of Integer;
  TabW: Integer = 4): TFoldView;

{ Parse the tag's `_folds` attribute (comma-separated header indices) into a set. }
function ParseFolds(const S: string): TFoldIndices;

{ Format a set back to the `_folds` attribute string, e.g. "3,10,25". }
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

{ Index of the next non-blank line after Header, or -1 if none. }
function NextNonBlank(Lines: TStrings; Header: Integer): Integer;
var j: Integer;
begin
  Result := -1;
  for j := Header + 1 to Lines.Count - 1 do
    if not IsBlankLine(Lines[j]) then Exit(j);
end;

function IsFoldHeader(Lines: TStrings; Header, TabW: Integer): Boolean;
var nxt: Integer;
begin
  Result := False;
  if (Header < 0) or (Header >= Lines.Count) then Exit;
  if IsBlankLine(Lines[Header]) then Exit;
  nxt := NextNonBlank(Lines, Header);
  if nxt < 0 then Exit;
  Result := LeadingIndent(Lines[nxt], TabW) > LeadingIndent(Lines[Header], TabW);
end;

function FoldRangeEnd(Lines: TStrings; Header, TabW: Integer): Integer;
var base, j, last: Integer;
begin
  Result := Header;
  if not IsFoldHeader(Lines, Header, TabW) then Exit;
  base := LeadingIndent(Lines[Header], TabW);
  last := Header;
  j := Header + 1;
  while j < Lines.Count do
  begin
    if IsBlankLine(Lines[j]) then
    begin
      Inc(j);                       // blanks belong to the block but don't end it
      Continue;
    end;
    if LeadingIndent(Lines[j], TabW) <= base then Break;   // indent returned
    last := j;                      // deepest confirmed member (trims trailing blanks)
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
  TabW: Integer = 4): TFoldView;
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
    if InSet(Collapsed, i) and IsFoldHeader(Lines, i, TabW) then
    begin
      e := FoldRangeEnd(Lines, i, TabW);
      for j := i + 1 to e do hidden[j] := True;
    end;

  SetLength(Result, n);
  vis := 0;
  for i := 0 to n - 1 do
    if not hidden[i] then
    begin
      Result[vis].SrcIdx    := i;
      Result[vis].Foldable  := IsFoldHeader(Lines, i, TabW);
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
