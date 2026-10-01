unit AppLogic;

{ Animated parallax mountains — three 2D-canvas ranges that drift behind the
  flamingo + cheetah. Silhouettes are drawn in pure Pascal (Canvas-2D); the MOTION
  is a CSS @keyframes translateX loop per layer (back slow, front fast), so the
  engine's animation clock drives it with no per-frame app code.

  Seamless loop: each range is drawn as TWO identical tiles (period = TILEW px) in a
  2*TILEW-wide canvas; the CSS animates translateX 0 -> -TILEW, so when it snaps back
  the second tile sits exactly where the first was. Each range is a run of sharp,
  varied peaks (explicit x/y points) so it reads as a mountain ridge, not a sawtooth. }

{$mode delphi}{$H+}

interface

procedure RegisterAppActions;

implementation

uses
  SysUtils, Tina4RenderBackend, Tina4Canvas2D;

const
  TILEW = 480;       // one seamless repeat; canvas is 2*TILEW wide
  H     = 300;       // canvas height (drawing space)

{ Draw one ridge tile at xoff from parallel x/y point arrays (xs in 0..TILEW,
  ys[0] must equal ys[high] so adjacent tiles meet). Filled down to the base. }
procedure Tile(ctx: TTina4Canvas2D; color: TTina4Color; xoff: Single;
  const xs, ys: array of Single);
var i: Integer;
begin
  ctx.SetFillColor(color);
  ctx.BeginPath;
  ctx.MoveTo(xoff + xs[0], ys[0]);
  for i := 1 to High(xs) do ctx.LineTo(xoff + xs[i], ys[i]);
  ctx.LineTo(xoff + xs[High(xs)], H);
  ctx.LineTo(xoff + xs[0], H);
  ctx.ClosePath;
  ctx.Fill;
end;

procedure Range(ctx: TTina4Canvas2D; color: TTina4Color; const xs, ys: array of Single);
begin
  Tile(ctx, color, 0, xs, ys);
  Tile(ctx, color, TILEW, xs, ys);
end;

{ far range — hazy, lighter, tallest sharp peaks }
procedure DrawBack(ctx: TTina4Canvas2D);
const
  xs: array[0..6] of Single = (0,  70, 150, 240, 330, 410, 480);
  ys: array[0..6] of Single = (165, 72, 150,  60, 140,  95, 165);
begin Range(ctx, $FF7A5E90, xs, ys); end;

{ middle range }
procedure DrawMid(ctx: TTina4Canvas2D);
const
  xs: array[0..6] of Single = (0,  60, 150, 250, 340, 430, 480);
  ys: array[0..6] of Single = (205, 150, 200, 135, 195, 158, 205);
begin Range(ctx, $FF523E6E, xs, ys); end;

{ near range — darkest, closest }
procedure DrawFront(ctx: TTina4Canvas2D);
const
  xs: array[0..6] of Single = (0,  90, 190, 280, 380, 440, 480);
  ys: array[0..6] of Single = (258, 206, 255, 200, 250, 214, 258);
begin Range(ctx, $FF2C1F44, xs, ys); end;

procedure RegisterAppActions;
begin
  RegisterCanvasPainter('back',  @DrawBack);
  RegisterCanvasPainter('mid',   @DrawMid);
  RegisterCanvasPainter('front', @DrawFront);
end;

initialization
  RegisterAppActions;
end.
