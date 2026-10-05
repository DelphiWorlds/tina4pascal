program test_codefold;

{
  Real (no-mock) console test for Tina4CodeFold — the indentation fold model the
  <codearea> renderer and click handler both use. Asserts header detection, range
  end (with trailing-blank trimming), the collapsed visible-view, nesting, and the
  _folds attribute round-trip + toggle. Exits 0 with 'ALL TESTS PASS'.
}

{$mode delphi}{$H+}

uses SysUtils, Classes, Tina4CodeFold;

var PassCount: Integer = 0;

procedure Check(Cond: Boolean; const Msg: string);
begin
  if Cond then Inc(PassCount)
  else begin Writeln('FAIL: ', Msg); Halt(1); end;
end;

function L(const Items: array of string): TStringList;
var i: Integer;
begin
  Result := TStringList.Create;
  for i := 0 to High(Items) do Result.Add(Items[i]);
end;

var
  src: TStringList;
  v: TFoldView;
  f: TFoldIndices;
begin
  { indent: a header is a line whose next non-blank line is deeper }
  src := L(['procedure Up;', 'begin', '  DoA;', '  DoB;', 'end;']);
  try
    Check(LeadingIndent('  x') = 2, 'leading spaces counted');
    Check(LeadingIndent(#9'x', 4) = 4, 'tab expands to TabW');
    Check(IsFoldHeader(src, 1, 4), 'begin is a fold header (body indented)');
    Check(not IsFoldHeader(src, 2, 4), 'a leaf line is not a header');
    Check(not IsFoldHeader(src, 4, 4), 'end is not a header');
    Check(FoldRangeEnd(src, 1, 4) = 3, 'range covers the two indented body lines');
  finally src.Free; end;

  { trailing blank lines are trimmed from a fold range }
  src := L(['root', '  a', '  b', '', 'tail']);
  try
    Check(FoldRangeEnd(src, 0, 4) = 2, 'trailing blank not swallowed into range');
  finally src.Free; end;

  { collapsing a header hides its body but keeps the header line }
  src := L(['header', '  a', '  b', 'after']);
  try
    f := ParseFolds('0');
    v := ComputeFoldView(src, f, 4);
    Check(Length(v) = 2, 'collapsed: only header + after remain visible');
    Check((v[0].SrcIdx = 0) and v[0].Foldable and v[0].Collapsed, 'header flagged collapsed');
    Check(v[1].SrcIdx = 3, 'line after the block stays visible');
    { expanded view shows every line }
    v := ComputeFoldView(src, [], 4);
    Check(Length(v) = 4, 'expanded: all four lines visible');
    Check(v[0].Foldable and not v[0].Collapsed, 'header foldable but not collapsed');
  finally src.Free; end;

  { nested folds: collapsing the outer hides inner header too }
  src := L(['outer', '  inner', '    deep', '  tail', 'done']);
  try
    v := ComputeFoldView(src, ParseFolds('0'), 4);
    Check(Length(v) = 2, 'outer collapsed hides inner + deep + tail');
    Check((v[0].SrcIdx = 0) and (v[1].SrcIdx = 4), 'only outer header and done remain');
    { collapse only the inner header }
    v := ComputeFoldView(src, ParseFolds('1'), 4);
    Check(Length(v) = 4, 'inner collapsed hides only deep');
    Check(v[2].SrcIdx = 3, 'tail still visible when only inner folded');
  finally src.Free; end;

  { stale collapsed index self-heals (line is no longer a header) }
  src := L(['a', 'b', 'c']);
  try
    v := ComputeFoldView(src, ParseFolds('0'), 4);
    Check(Length(v) = 3, 'collapsed index on a non-header is ignored');
  finally src.Free; end;

  { _folds round-trip + toggle }
  Check(FoldsToStr(ParseFolds('3,10,10,x,-2')) = '3,10', 'parse dedupes + drops junk/neg');
  Check(FoldsToStr(ToggleFold(ParseFolds('3,10'), 5)) = '3,10,5', 'toggle adds a new index');
  Check(FoldsToStr(ToggleFold(ParseFolds('3,10'), 10)) = '3', 'toggle removes an existing index');

  Writeln;
  Writeln(PassCount, ' assertions passed.');
  Writeln('ALL TESTS PASS');
end.
