program test_includes;
{ REAL test for the LOCAL <include src> path — the live, parse-time splice of an
  on-disk HTML partial into the render tree (no network). Drives the actual
  Tina4Interact pipeline: TinaSetHtml -> ParseDoc -> LoadIncludes -> ProcessInclude
  reads the file off disk via the canvas's ReadLocalFile and InjectInclude swaps
  the <include> node for the partial's nodes, then layout runs.

  Assertions read the LIVE (mutated) DOM back via TinaDumpDom:
    - the partial's content is spliced in (its marker id is present)
    - the <include> placeholder is gone (replaced, not left in the tree)
    - a missing local file degrades to a visible "not found" note, never a crash
    - the partial's own inline text survives the splice
  Each would flip to FAIL if the local-include path regressed. }
{$mode delphi}{$H+}

uses SysUtils, Classes, StrUtils,
     Tina4RenderBackend, Tina4RasterCanvas, Tina4Interact, Tina4Events, Tina4Pages;

const VW = 320; VH = 420;

var
  Canvas: TTina4RasterCanvas;
  Fails: Integer = 0; Total: Integer = 0;
  PartPath, MissPage, OkPage, Dom: string;

procedure Check(Cond: Boolean; const Msg: string);
begin
  Inc(Total);
  if Cond then WriteLn('  ok   ', Msg)
  else begin WriteLn('  FAIL ', Msg); Inc(Fails); end;
end;

{ Count non-overlapping occurrences of Sub in S (an inline <template> keeps its
  own copy of a screen in the DOM dump, so a cloned screen shows up as 2). }
function CountOccur(const S, Sub: string): Integer;
var p, from: Integer;
begin
  Result := 0; from := 1;
  repeat
    p := PosEx(Sub, S, from);
    if p > 0 then begin Inc(Result); from := p + Length(Sub); end;
  until p = 0;
end;

procedure WritePartial(const Path, Body: string);
var sl: TStringList;
begin
  sl := TStringList.Create;
  try sl.Text := Body; sl.SaveToFile(Path);
  finally sl.Free; end;
end;

begin
  WriteLn('test_includes — local <include src> live splice');

  // A partial on disk, addressed by an absolute path (the base ReadLocalFile
  // resolves absolute paths directly; mobile shells prepend their asset base).
  PartPath := GetTempDir + 'tina4-inc-partial.html';
  WritePartial(PartPath,
    '<section id="injected" style="padding:8px">' +
    '<h2 id="parttitle">Partial loaded</h2>' +
    '<p>hello from a local file</p></section>');

  OkPage :=
    '<body><div id="host">' +
    '<include src="' + PartPath + '"></include>' +
    '</div></body>';

  MissPage :=
    '<body><div id="host2">' +
    '<include src="' + GetTempDir + 'tina4-inc-does-not-exist.html"></include>' +
    '</div></body>';

  Canvas := TTina4RasterCanvas.Create(VW, VH);
  try
    TinaInit(Canvas);

    // ---- happy path: local file splices in, <include> disappears ----
    TinaSetHtml(OkPage);
    TinaFrame(VW, VH, 1);                 // ParseDoc -> LoadIncludes (synchronous for local)
    Dom := TinaDumpDom;
    Check(Pos('"injected"', Dom) > 0, 'partial element spliced into the live DOM');
    Check(Pos('"parttitle"', Dom) > 0, 'partial child nodes present');
    Check(Pos('hello from a local file', Dom) > 0, 'partial text content survives the splice');
    Check(Pos('"include"', Dom) = 0, '<include> placeholder replaced (not left in tree)');

    // ---- missing file: degrades to a note, no crash, no stray <include> ----
    TinaSetHtml(MissPage);
    TinaFrame(VW, VH, 1);
    Dom := TinaDumpDom;
    Check(Pos('"include"', Dom) = 0, 'missing include is replaced, not left pending');
    Check(Pos('not found', Dom) > 0, 'missing local include shows a visible note');

    // ---- multi-screen: swap a container's contents live, twice ----
    TinaSetHtml('<body><main id="screen"><p id="home">home screen</p></main></body>');
    TinaFrame(VW, VH, 1);
    Dom := TinaDumpDom;
    Check(Pos('"home"', Dom) > 0, 'initial screen present before navigation');

    // in-memory fragment → replaces the container's children
    TinaSetViewHtml('screen', '<section id="settings"><h2>Settings</h2></section>');
    TinaFrame(VW, VH, 1);
    Dom := TinaDumpDom;
    Check(Pos('"settings"', Dom) > 0, 'TinaSetViewHtml swapped in the new screen');
    Check(Pos('"home"', Dom) = 0, 'previous screen nodes removed on swap');

    // load the next screen from a local file via TinaLoadView
    TinaLoadView('screen', PartPath);
    TinaFrame(VW, VH, 1);
    Dom := TinaDumpDom;
    Check(Pos('"injected"', Dom) > 0, 'TinaLoadView loaded a screen from a local file');
    Check(Pos('"settings"', Dom) = 0, 'prior screen cleared when loading the next');

    // navigating to a missing view degrades to a note, no crash
    TinaLoadView('screen', GetTempDir + 'tina4-no-such-view.html');
    TinaFrame(VW, VH, 1);
    Dom := TinaDumpDom;
    Check(Pos('view not found', Dom) > 0, 'missing view shows a visible note, no crash');

    // swapping into an unknown container is a safe no-op
    TinaLoadView('ghost-container', PartPath);
    TinaFrame(VW, VH, 1);
    Check(True, 'load into unknown container did not crash');

    // ---- self-contained multi-screen: inline <template> screens, no files ----
    TinaSetHtml(
      '<body>' +
      '<main id="stage"><p id="start">pick a screen</p></main>' +
      '<template id="scr-a"><section id="viewA"><h2>Screen A</h2></section></template>' +
      '<template id="scr-b"><section id="viewB"><h2>Screen B</h2></section></template>' +
      '</body>');
    TinaFrame(VW, VH, 1);

    // A screen in an inline <template> appears once (the template). Cloned into
    // the stage it appears twice; cleared, back to once. That 2-vs-1 count is how
    // we tell "showing" from merely "defined".
    TinaShowView('stage', 'scr-a');          // clone template A into the stage
    TinaFrame(VW, VH, 1);
    Dom := TinaDumpDom;
    Check(CountOccur(Dom, '"viewA"') = 2, 'TinaShowView cloned an inline <template> into the stage');
    Check(Pos('"start"', Dom) = 0, 'placeholder screen removed on first navigation');

    TinaShowView('stage', 'scr-b');          // navigate to B; A clone gone, template kept
    TinaFrame(VW, VH, 1);
    Dom := TinaDumpDom;
    Check(CountOccur(Dom, '"viewB"') = 2, 'navigated to the second inline screen');
    Check(CountOccur(Dom, '"viewA"') = 1, 'previous inline screen cleared (only its template remains)');

    // the source <template> is cloned, not consumed — navigate back to A
    TinaShowView('stage', 'scr-a');
    TinaFrame(VW, VH, 1);
    Dom := TinaDumpDom;
    Check(CountOccur(Dom, '"viewA"') = 2, 'template is reusable — navigated back to A');

    // ---- pure-HTML path: the built-in view.show action, no app code ----
    Check(DispatchAction('view.show(''stage'',''scr-b'')'), 'built-in view.show action is registered');
    TinaFrame(VW, VH, 1);
    Dom := TinaDumpDom;
    Check(CountOccur(Dom, '"viewB"') = 2, 'built-in view.show swapped the screen from HTML alone');

    // ---- embedded page store: a page compiled in, loaded with NO file on disk ----
    RegisterEmbeddedPage('views/embedded.html', '<section id="baked"><h2>Baked in</h2></section>');
    Check(EmbeddedPageCount >= 1, 'embedded page registered into the store');
    TinaSetHtml('<body><main id="stage2"><p id="ph">x</p></main></body>');
    TinaFrame(VW, VH, 1);
    TinaLoadView('stage2', 'views/embedded.html');   // no such file exists anywhere
    TinaFrame(VW, VH, 1);
    Dom := TinaDumpDom;
    Check(Pos('"baked"', Dom) > 0, 'TinaLoadView served a page from the embedded store (no file)');
    Check(Pos('view not found', Dom) = 0, 'embedded page resolved, not reported missing');

    // an embedded page also satisfies <include src> at parse time
    TinaSetHtml('<body><div id="wrap"><include src="views/embedded.html"></include></div></body>');
    TinaFrame(VW, VH, 1);
    Dom := TinaDumpDom;
    Check(Pos('"baked"', Dom) > 0, '<include src> resolved from the embedded store');
  finally
    Canvas.Free;
    if FileExists(PartPath) then DeleteFile(PartPath);
  end;

  WriteLn;
  if Fails = 0 then WriteLn('ALL TESTS PASS (', Total, ')')
  else begin WriteLn(Fails, '/', Total, ' FAILED'); Halt(1); end;
end.
