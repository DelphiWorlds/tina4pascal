program test_codefold;

{
  Real (no-mock) console test for Tina4CodeFold — the fold model the <codearea>
  renderer and click handler both use. Covers indentation folding (header detection,
  range end with trailing-blank trimming, nesting, self-heal) AND Pascal routine
  folding (a procedure/function folds its whole begin..end body into the signature,
  begin gets no arrow, inner blocks still fold). Exits 0 with 'ALL TESTS PASS'.
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
  IND, PAS: TFoldRules;
begin
  FillChar(IND, SizeOf(IND), 0); IND.Active := False;   // pure indentation rules
  PAS := FoldRulesForLang('pascal');

  { ---- indentation folding ---- }
  src := L(['root', 'begin', '  a', '  b', 'end']);
  try
    Check(LeadingIndent('  x') = 2, 'leading spaces counted');
    Check(LeadingIndent(#9'x', 4) = 4, 'tab expands to TabW');
    Check(IsFoldHeader(src, 1, IND, 4), 'indent: begin is a header (body deeper)');
    Check(not IsFoldHeader(src, 2, IND, 4), 'indent: a leaf line is not a header');
    Check(FoldRangeEnd(src, 1, IND, 4) = 3, 'indent: range covers the two body lines');
  finally src.Free; end;

  src := L(['header', '  a', '  b', 'after']);
  try
    v := ComputeFoldView(src, ParseFolds('0'), IND, 4);
    Check(Length(v) = 2, 'indent collapsed: header + after visible');
    Check(v[0].Foldable and v[0].Collapsed, 'indent header flagged collapsed');
    v := ComputeFoldView(src, [], IND, 4);
    Check(Length(v) = 4, 'indent expanded: all four lines visible');
  finally src.Free; end;

  { ---- Pascal routine folding: the procedure NAME is the header ---- }
  src := L(['procedure Alpha(const Args: string);',  // 0 header
            'begin',                                   // 1
            '  DoAlphaOne;',                           // 2
            '  DoAlphaTwo;',                           // 3
            'end;',                                    // 4  routine close
            '',                                        // 5
            'procedure Beta;',                         // 6 header
            'begin',                                   // 7
            '  if Ready then',                         // 8 inner indent header
            '    DoBeta;',                             // 9
            'end;']);                                  // 10
  try
    Check(IsFoldHeader(src, 0, PAS, 4), 'pascal: procedure line is a fold header');
    Check(not IsFoldHeader(src, 1, PAS, 4), 'pascal: begin gets NO arrow (suppressed)');
    Check(FoldRangeEnd(src, 0, PAS, 4) = 4, 'pascal: routine folds through its end;');
    Check(IsFoldHeader(src, 8, PAS, 4), 'pascal: inner if-block still folds by indent');
    { collapse Alpha (header 0): begin/body/end all hide, only signature remains }
    v := ComputeFoldView(src, ParseFolds('0'), PAS, 4);
    Check(v[0].SrcIdx = 0, 'pascal collapsed: Alpha signature stays');
    Check((v[1].SrcIdx = 5) or (v[1].SrcIdx = 6), 'pascal collapsed: jumps past begin..end to blank/Beta');
    Check(v[1].SrcIdx <> 1, 'pascal collapsed: begin is hidden');
    { expanded: Alpha(0) and Beta(6) are headers; begin lines are not }
    v := ComputeFoldView(src, [], PAS, 4);
    Check((v[0].SrcIdx = 0) and v[0].Foldable, 'pascal: Alpha foldable');
    Check((v[1].SrcIdx = 1) and not v[1].Foldable, 'pascal: begin visible, not foldable');
    Check((v[6].SrcIdx = 6) and v[6].Foldable, 'pascal: Beta foldable');
  finally src.Free; end;

  { the same source under INDENTATION rules would instead fold begin — proving the
    language actually changes the model }
  src := L(['procedure X;', 'begin', '  Y;', 'end;']);
  try
    Check(not IsFoldHeader(src, 0, IND, 4), 'indent rules: procedure line not a header');
    Check(IsFoldHeader(src, 1, IND, 4), 'indent rules: begin IS a header');
    Check(IsFoldHeader(src, 0, PAS, 4), 'pascal rules: procedure line IS a header');
  finally src.Free; end;

  { _folds round-trip + toggle }
  Check(FoldsToStr(ParseFolds('3,10,10,x,-2')) = '3,10', 'parse dedupes + drops junk/neg');
  Check(FoldsToStr(ToggleFold(ParseFolds('3,10'), 5)) = '3,10,5', 'toggle adds a new index');
  Check(FoldsToStr(ToggleFold(ParseFolds('3,10'), 10)) = '3', 'toggle removes an existing index');

  Writeln;
  Writeln(PassCount, ' assertions passed.');
  Writeln('ALL TESTS PASS');
end.
