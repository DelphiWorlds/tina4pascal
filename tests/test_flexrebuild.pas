program test_flexrebuild;
{ Regression: an anonymous flex-item wrapper (MakeAnonTextItem, tracked in
  FSynthTags) sets its Parent to the REAL flex-item tag but is never added to that
  tag's Children. If app code frees that flex item and rebuilds the container's
  children between layouts (e.g. a chart's Randomize), the synth's Parent dangles,
  and the NEXT Build's FreeSynthTags -> THTMLTag.Destroy dereferenced the freed
  Parent.Children to self-detach -> EBusError/use-after-free crash in paint.

  This reproduces it headlessly: a flex container whose items are themselves flex
  containers with text (so each spawns a synth), laid out, then its children freed
  and rebuilt, then laid out again. Must not crash. }
{$mode delphi}{$H+}

uses SysUtils, Tina4HTMLDom, Tina4RenderBackend, Tina4RasterCanvas, Tina4HTMLLayout;

var Fails: Integer = 0; Total: Integer = 0;
procedure Check(Cond: Boolean; const Msg: string);
begin
  Inc(Total);
  if Cond then WriteLn('  ok   ', Msg) else begin WriteLn('  FAIL ', Msg); Inc(Fails); end;
end;

{ First element (non-#text) descendant whose id = Id, else nil. }
function FindBox(T: THTMLTag; const Id: string): THTMLTag;
var c, r: THTMLTag;
begin
  Result := nil;
  if T = nil then Exit;
  if T.GetAttribute('id') = Id then Exit(T);
  for c in T.Children do begin r := FindBox(c, Id); if r <> nil then Exit(r); end;
end;

{ Rebuild #box's children: free all, add N flex items that each contain text
  (so each spawns an anonymous synth flex item during the next layout). }
procedure Rebuild(Box: THTMLTag; N: Integer);
var i: Integer; d, tn: THTMLTag;
begin
  for i := Box.Children.Count - 1 downto 0 do Box.Children[i].Free;
  for i := 0 to N - 1 do
  begin
    d := THTMLTag.Create; d.TagName := 'div'; d.Parent := Box;
    d.Style.AddOrSetValue('display', 'flex');
    d.Style.AddOrSetValue('justify-content', 'center');
    d.Style.AddOrSetValue('width', '40px');
    d.Style.AddOrSetValue('height', IntToStr(30 + i * 20) + 'px');
    tn := THTMLTag.Create; tn.TagName := '#text'; tn.Text := IntToStr(i); tn.Parent := d;
    d.Children.Add(tn);
    Box.Children.Add(d);
  end;
end;

const HTML =
  '<body><div id="box" style="display:flex;align-items:flex-end;height:200px">' +
  '<div style="display:flex;justify-content:center;width:40px;height:60px">a</div>' +
  '<div style="display:flex;justify-content:center;width:40px;height:120px">b</div>' +
  '<div style="display:flex;justify-content:center;width:40px;height:90px">c</div>' +
  '</div></body>';

var
  Parser: THTMLParser;
  Sheet: TCSSStyleSheet;
  Canvas: TTina4RasterCanvas;
  Engine: TLayoutEngine;
  Root: TLayoutBox;
  Box: THTMLTag;
begin
  WriteLn('=== flex free+rebuild regression ===');
  Parser := THTMLParser.Create;
  Sheet := TCSSStyleSheet.Create;
  Canvas := TTina4RasterCanvas.Create(400, 300);
  try
    Parser.Parse(HTML);
    Engine := TLayoutEngine.Create(Canvas, Sheet);

    Root := Engine.Build(Parser.Root, 400, 300);   // 1st build: spawns synth per text item
    Root.Free;
    Check(True, 'first build ok');

    Box := FindBox(Parser.Root, 'box');
    Check(Box <> nil, 'found #box');
    Rebuild(Box, 5);                                // free the 3 flex items, add 5 new

    Root := Engine.Build(Parser.Root, 400, 300);   // 2nd build: FreeSynthTags on dangling parents (was the crash)
    Root.Free;
    Check(True, 'second build after free+rebuild did not crash');

    Rebuild(Box, 2);
    Root := Engine.Build(Parser.Root, 400, 300);   // 3rd for good measure
    Root.Free;
    Check(True, 'third build stable');

    Engine.Free;
  finally
    Canvas.Free; Sheet.Free; Parser.Free;
  end;

  WriteLn(Total - Fails, '/', Total, ' assertions passed.');
  if Fails = 0 then WriteLn('ALL TESTS PASS') else begin WriteLn('FAILURES: ', Fails); Halt(1); end;
end.
