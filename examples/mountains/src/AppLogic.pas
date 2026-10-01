unit AppLogic;

{ Animated parallax mountains — three 2D-canvas ranges that drift behind the
  flamingo + cheetah. The silhouettes are drawn in pure Pascal (Canvas-2D); the
  MOTION is a CSS @keyframes translateX loop per layer (back slow, front fast),
  so the engine's animation clock drives it with no per-frame app code.

  Seamless loop: each range is drawn as TWO identical tiles (period = TILEW px) in a
  2*TILEW-wide canvas, and the CSS animates translateX from 0 to -TILEW — when it
  snaps back, the second tile is exactly where the first was. }

{$mode delphi}{$H+}

interface

procedure RegisterAppActions;

implementation

uses
  SysUtils,
  Tina4Events,       // (kept for parity with the app convention)
  Tina4RenderBackend,
  Tina4Canvas2D;     // RegisterCanvasPainter, TTina4Canvas2D

const
  TILEW = 480;        // one seamless repeat; canvas is 2*TILEW wide
  H    = 300;        // canvas height (drawing space)

{ Draw one mountain tile at xoff. ys are ridge heights sampled across the tile;
  ys[0] must equal ys[high] so adjacent tiles meet seamlessly. }
procedure Tile(ctx: TTina4Canvas2D; color: TTina4Color; xoff: Single; const ys: array of Single);
var i, n: Integer; step: Single;
begin
  n := High(ys); step := TILEW / n;
  ctx.SetFillColor(color);
  ctx.BeginPath;
  ctx.MoveTo(xoff, H);
  for i := 0 to n do ctx.LineTo(xoff + i * step, ys[i]);
  ctx.LineTo(xoff + TILEW, H);
  ctx.ClosePath;
  ctx.Fill;
end;

procedure Range(ctx: TTina4Canvas2D; color: TTina4Color; const ys: array of Single);
begin
  Tile(ctx, color, 0, ys);
  Tile(ctx, color, TILEW, ys);
end;

{ far range — lightest, tallest, gentlest }
procedure DrawBack(ctx: TTina4Canvas2D);
const ys: array[0..6] of Single = (150, 110, 165, 120, 170, 125, 150);
begin Range(ctx, $FF6E5A86, ys); end;

{ middle range }
procedure DrawMid(ctx: TTina4Canvas2D);
const ys: array[0..8] of Single = (205, 165, 215, 160, 210, 170, 220, 175, 205);
begin Range(ctx, $FF493766, ys); end;

{ near range — darkest, closest }
procedure DrawFront(ctx: TTina4Canvas2D);
const ys: array[0..6] of Single = (250, 215, 255, 210, 250, 220, 250);
begin Range(ctx, $FF281B3C, ys); end;

procedure RegisterAppActions;
begin
  RegisterCanvasPainter('back',  @DrawBack);
  RegisterCanvasPainter('mid',   @DrawMid);
  RegisterCanvasPainter('front', @DrawFront);
end;

initialization
  RegisterAppActions;
end.
