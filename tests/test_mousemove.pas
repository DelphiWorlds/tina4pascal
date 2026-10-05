program test_mousemove;
{ REAL test for the onmousemove DOM event (ADR-0012). Drives the actual
  TinaHover path that the Win/Linux/macOS hosts use: a page carrying
  <body onmousemove="hero.move()"> must dispatch to the registered Pascal action
  with the cursor as "x,y" (CSS px), and TinaTakeMoveRepaint must report that the
  host should repaint. A page WITHOUT onmousemove must not fire and must leave
  hover repaint-free. Each assertion flips to FAIL if the behaviour regresses. }
{$mode delphi}{$H+}

uses SysUtils,
     Tina4RenderBackend, Tina4RasterCanvas, Tina4Interact, Tina4Events;

const
  VW = 320; VH = 240;   // viewport, physical px (density 1 → CSS px == physical)

var
  Canvas: TTina4RasterCanvas;
  Fails: Integer = 0; Total: Integer = 0;
  LastMove: string = '';
  MoveCount: Integer = 0;

procedure Check(Cond: Boolean; const Msg: string);
begin
  Inc(Total);
  if Cond then WriteLn('  ok   ', Msg)
  else begin WriteLn('  FAIL ', Msg); Inc(Fails); end;
end;

{ The app's onmousemove handler: records the "x,y" it was handed. }
procedure OnMove(const Args: string);
begin LastMove := Args; Inc(MoveCount); end;

procedure Frame; begin TinaFrame(VW, VH, 1); end;

const
  PAGE_MOVE =
    '<body style="margin:0" onmousemove="hero.move()">' +
    '<div style="width:100px;height:100px"></div></body>';
  PAGE_PLAIN =
    '<body style="margin:0">' +
    '<div style="width:100px;height:100px"></div></body>';

begin
  WriteLn('=== onmousemove event test ===');
  Canvas := TTina4RasterCanvas.Create(VW, VH);
  try
    TinaInit(Canvas);
    RegisterAction('hero.move', @OnMove);

    { --- page WITH onmousemove ------------------------------------------- }
    TinaSetHtml(PAGE_MOVE);
    Frame;

    LastMove := ''; MoveCount := 0;
    TinaHover(120, 80);
    Check(MoveCount = 1, 'onmousemove fires the registered action on a cursor move');
    Check(LastMove = '120,80', 'handler receives the cursor as "x,y" CSS px (got "' + LastMove + '")');
    Check(TinaTakeMoveRepaint, 'host is told to repaint after an onmousemove dispatch');
    Check(not TinaTakeMoveRepaint, 'the repaint flag is one-shot (cleared on read)');

    TinaHover(10, 200);
    Check((MoveCount = 2) and (LastMove = '10,200'), 'a second move dispatches fresh coords');

    { --- page WITHOUT onmousemove ---------------------------------------- }
    TinaSetHtml(PAGE_PLAIN);
    Frame;
    LastMove := 'untouched'; MoveCount := 0;
    TinaHover(50, 50);
    Check(MoveCount = 0, 'no onmousemove handler → nothing fires');
    Check(not TinaTakeMoveRepaint, 'no handler → plain hover stays repaint-free');

    WriteLn;
    if Fails = 0 then WriteLn('ALL TESTS PASS')
    else WriteLn(Fails, ' of ', Total, ' FAILED');
  finally
    Canvas.Free;
  end;
  if Fails <> 0 then Halt(1);
end.
