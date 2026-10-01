unit AppLogic;

{ A lava lamp, drawn entirely by a Pascal <canvas> painter — no widgets, no JS.

  The painter is registered for <canvas id="lava"> in this unit's initialization,
  so EVERY shell that links this unit gets it: the desktop host (Tina4App.RunApp)
  and, because this unit is listed under "appUnits" in tina4.json, the iOS/Android
  engine libraries too.

  How the motion runs: the painter calls AnimMarkActive every frame, which keeps
  the engine's repaint loop alive (the shell's ~60fps tick advances the shared
  AnimClock and repaints while any canvas content is active). Each paint reads the
  clock, derives the real elapsed dt, steps a small buoyancy simulation, and draws
  the wax blobs as soft layered ellipses (a stand-in for a radial gradient). }

{$mode delphi}{$H+}

interface

procedure RegisterAppActions;   { exposed so a host can (re)install explicitly }

implementation

uses
  SysUtils, Math,
  Tina4RenderBackend,   // TTina4Color ($AARRGGBB)
  Tina4Canvas2D;        // TTina4Canvas2D, RegisterCanvasPainter, AnimMarkActive, AnimClock

const
  NBLOBS  = 7;
  G       = 90.0;    // buoyancy strength (px/s^2 before mass/temp scaling)
  HEATR   = 0.55;    // how fast wax heats in the bottom zone (per second)
  COOLR   = 0.42;    // how fast it cools in the top zone
  DAMPK   = 2.2;     // velocity damping — high damping gives the slow lava creep

type
  TBlob = record
    x, y, r : Single;   // centre + radius (canvas px)
    vy      : Single;   // vertical velocity (px/s), negative = rising
    temp    : Single;   // 0 = cool/dense (sinks), 1 = hot/buoyant (rises)
    phase   : Single;   // horizontal wobble phase
    wspeed  : Single;   // horizontal wobble speed (rad/s)
    wamp    : Single;   // horizontal wobble amplitude (fraction of free space)
  end;

var
  Blobs       : array[0..NBLOBS - 1] of TBlob;
  Ready       : Boolean = False;   // seeded yet?
  LastClock   : Double  = 0;

  { Lamp geometry, recomputed each paint from the live canvas size. }
  W, H, Cx            : Single;
  GyTop, GyBot        : Single;    // glass interior, top and bottom
  RTop, RBot          : Single;    // glass half-width at top / bottom (tapered)
  HeatY, CoolY        : Single;    // zone boundaries
  RefR                : Single;    // reference blob radius (for mass scaling)

{ ---- small helpers ------------------------------------------------------ }

function Col(A, R, Gr, B: Integer): TTina4Color;
begin
  Col := (TTina4Color(A and $FF) shl 24) or (TTina4Color(R and $FF) shl 16)
       or (TTina4Color(Gr and $FF) shl 8) or TTina4Color(B and $FF);
end;

function Mix(A, B, T: Single): Single;
begin
  Mix := A + (B - A) * T;
end;

function Clamp(V, Lo, Hi: Single): Single;
begin
  if V < Lo then Clamp := Lo
  else if V > Hi then Clamp := Hi
  else Clamp := V;
end;

{ Wax colour: hot -> bright orange, cool -> deep rose. }
function WaxColor(Temp: Single): TTina4Color;
begin
  Temp := Clamp(Temp, 0, 1);
  WaxColor := Col(255,
    Round(Mix(214, 255, Temp)),
    Round(Mix( 34, 156, Temp)),
    Round(Mix( 78,  44, Temp)));
end;

{ Glass half-width at a given y (linear taper, wider at the bottom). }
function HalfW(Y: Single): Single;
var T: Single;
begin
  T := (Y - GyTop) / (GyBot - GyTop);
  HalfW := Mix(RTop, RBot, Clamp(T, 0, 1));
end;

procedure EnsureGeom(AW, AH: Single);
begin
  W := AW; H := AH; Cx := W * 0.5;
  GyTop := H * 0.10;  GyBot := H * 0.86;
  RTop  := W * 0.17;  RBot  := W * 0.33;
  HeatY := GyBot - (GyBot - GyTop) * 0.18;
  CoolY := GyTop + (GyBot - GyTop) * 0.16;
  RefR  := W * 0.060;
end;

{ ---- seed + simulation -------------------------------------------------- }

procedure Seed;
var i: Integer; y: Single;
begin
  for i := 0 to NBLOBS - 1 do
  begin
    y := Mix(GyTop + RefR, GyBot - RefR, Random);
    Blobs[i].r      := RefR * (0.75 + Random * 0.9);
    Blobs[i].y      := y;
    Blobs[i].x      := Cx + (Random - 0.5) * (HalfW(y) - Blobs[i].r) * 1.2;
    Blobs[i].vy     := (Random - 0.5) * 6;
    Blobs[i].temp   := Random;
    Blobs[i].phase  := Random * 2 * Pi;
    Blobs[i].wspeed := 0.18 + Random * 0.45;
    Blobs[i].wamp   := 0.35 + Random * 0.55;
  end;
  Ready := True;
end;

procedure Step(dt: Single; Clock: Double);
var
  i: Integer;
  mass, accel, topLim, botLim, maxOff: Single;
begin
  if dt <= 0 then Exit;
  for i := 0 to NBLOBS - 1 do
    with Blobs[i] do
    begin
      { Heat near the base, cool near the top — proportional to depth in the zone. }
      if y > HeatY then
        temp := Min(1, temp + HEATR * dt * ((y - HeatY) / Max(1, GyBot - HeatY)));
      if y < CoolY then
        temp := Max(0, temp - COOLR * dt * ((CoolY - y) / Max(1, CoolY - GyTop)));

      { Buoyancy: hot (temp > 0.5) accelerates upward (negative y); big blobs are
        heavier, so they drift more slowly. Heavy damping = the slow lava creep. }
      mass  := r / RefR;
      accel := G * (0.5 - temp) / mass;
      vy := vy + accel * dt;
      vy := vy * (1 - Min(0.5, DAMPK * dt));
      y  := y + vy * dt;

      { Bounce gently off the rounded top/bottom of the glass. }
      topLim := GyTop + r * 0.6;
      botLim := GyBot - r * 0.6;
      if y < topLim then begin y := topLim; if vy < 0 then vy := -vy * 0.25; end;
      if y > botLim then begin y := botLim; if vy > 0 then vy := -vy * 0.25; end;

      { Horizontal drift is a slow wobble, bounded to stay inside the taper. }
      maxOff := HalfW(y) - r - 6;
      if maxOff < 0 then maxOff := 0;
      x := Cx + Sin(Clock * wspeed + phase) * maxOff * wamp;
    end;
end;

{ ---- drawing ------------------------------------------------------------ }

{ Scalar field: each blob contributes r^2 / (dist^2 + 1). The wax surface is the
  iso-contour where the summed field crosses ISO, so two blobs whose fields
  overlap fuse into ONE surface, and as they drift apart the bridge between them
  thins and pinches off — real merge and split, not just overlapping circles. A
  lone blob's iso radius is ~its r (at dist = r, r^2/r^2 = 1 = ISO). }
function FieldAt(px, py: Single): Single;
var i: Integer; dx, dy: Single;
begin
  Result := 0;
  for i := 0 to NBLOBS - 1 do
  begin
    dx := px - Blobs[i].x; dy := py - Blobs[i].y;
    Result := Result + (Blobs[i].r * Blobs[i].r) / (dx * dx + dy * dy + 1.0);
  end;
end;

{ Field-weighted mean temperature at a point, so colour travels with the wax:
  a hot blob stays orange as it rises, and the tint blends smoothly where two
  blobs merge. }
function TempAt(px, py: Single): Single;
var i: Integer; dx, dy, w, sw, st: Single;
begin
  sw := 0; st := 0;
  for i := 0 to NBLOBS - 1 do
  begin
    dx := px - Blobs[i].x; dy := py - Blobs[i].y;
    w := (Blobs[i].r * Blobs[i].r) / (dx * dx + dy * dy + 1.0);
    sw := sw + w; st := st + w * Blobs[i].temp;
  end;
  if sw > 0 then TempAt := st / sw else TempAt := 0.5;
end;

procedure EmitPoly(Ctx: TTina4Canvas2D; const Xs, Ys: array of Single; N: Integer);
var i: Integer;
begin
  if N < 3 then Exit;
  Ctx.BeginPath;
  Ctx.MoveTo(Xs[0], Ys[0]);
  for i := 1 to N - 1 do Ctx.LineTo(Xs[i], Ys[i]);
  Ctx.ClosePath;
  Ctx.Fill;
end;

{ Fill the part of one triangle that lies inside the iso. Marching TRIANGLES
  (a simplex) has no saddle ambiguity, so merges and splits stay artefact-free. }
procedure FillTri(Ctx: TTina4Canvas2D;
  ax, ay, av, bx, by, bv, cx, cy, cv, T: Single);
var Xs, Ys: array[0..3] of Single; N: Integer;
  procedure Edge(x1, y1, v1, x2, y2, v2: Single);
  var t: Single;
  begin
    if v1 >= T then begin Xs[N] := x1; Ys[N] := y1; Inc(N); end;
    if ((v1 >= T) <> (v2 >= T)) and (v2 <> v1) then
    begin
      t := (T - v1) / (v2 - v1);
      Xs[N] := x1 + t * (x2 - x1); Ys[N] := y1 + t * (y2 - y1); Inc(N);
    end;
  end;
begin
  N := 0;
  Edge(ax, ay, av, bx, by, bv);
  Edge(bx, by, bv, cx, cy, cv);
  Edge(cx, cy, cv, ax, ay, av);
  EmitPoly(Ctx, Xs, Ys, N);
end;

{ Rasterise the whole wax surface: march a grid over the blobs' bounding box.
  A cell fully inside fills fast as a rect; a boundary cell is split into four
  triangles about its centre and each is iso-clipped. }
procedure FillWax(Ctx: TTina4Canvas2D; T: Single);
const CELL = 5;   { marching-grid step — smaller = smoother wax surface }
var
  i, ccols, crows, cxi, cyi: Integer;
  minx, miny, maxx, maxy, k: Single;
  x0, y0, x1, y1, mx, my: Single;
  fTL, fTR, fBR, fBL, fC, fmax: Single;
begin
  minx := W; miny := H; maxx := 0; maxy := 0;
  for i := 0 to NBLOBS - 1 do
  begin
    k := Blobs[i].r * 2.2;
    if Blobs[i].x - k < minx then minx := Blobs[i].x - k;
    if Blobs[i].x + k > maxx then maxx := Blobs[i].x + k;
    if Blobs[i].y - k < miny then miny := Blobs[i].y - k;
    if Blobs[i].y + k > maxy then maxy := Blobs[i].y + k;
  end;
  if minx < 0 then minx := 0;
  if miny < 0 then miny := 0;
  if maxx > W then maxx := W;
  if maxy > H then maxy := H;
  if (maxx <= minx) or (maxy <= miny) then Exit;

  ccols := Ceil((maxx - minx) / CELL);
  crows := Ceil((maxy - miny) / CELL);
  for cyi := 0 to crows - 1 do
    for cxi := 0 to ccols - 1 do
    begin
      x0 := minx + cxi * CELL; x1 := x0 + CELL;
      y0 := miny + cyi * CELL; y1 := y0 + CELL;
      mx := (x0 + x1) * 0.5; my := (y0 + y1) * 0.5;
      fTL := FieldAt(x0, y0); fTR := FieldAt(x1, y0);
      fBR := FieldAt(x1, y1); fBL := FieldAt(x0, y1);
      fC  := FieldAt(mx, my);
      fmax := fTL;
      if fTR > fmax then fmax := fTR;
      if fBR > fmax then fmax := fBR;
      if fBL > fmax then fmax := fBL;
      if fC  > fmax then fmax := fC;
      if fmax < T then Continue;                 { cell entirely outside the wax }
      Ctx.SetFillColor(WaxColor(TempAt(mx, my)));
      if (fTL >= T) and (fTR >= T) and (fBR >= T) and (fBL >= T) then
        Ctx.FillRect(x0, y0, CELL, CELL)         { fast path: solid interior }
      else
      begin
        FillTri(Ctx, x0, y0, fTL, x1, y0, fTR, mx, my, fC, T);
        FillTri(Ctx, x1, y0, fTR, x1, y1, fBR, mx, my, fC, T);
        FillTri(Ctx, x1, y1, fBR, x0, y1, fBL, mx, my, fC, T);
        FillTri(Ctx, x0, y1, fBL, x0, y0, fTL, mx, my, fC, T);
      end;
    end;
end;

{ A cheap soft halo under the wax so the metaball edge glows. }
procedure GlowUnder(Ctx: TTina4Canvas2D);
var i: Integer;
begin
  Ctx.SetGlobalAlpha(0.16);
  for i := 0 to NBLOBS - 1 do
  begin
    Ctx.SetFillColor(WaxColor(Blobs[i].temp));
    Ctx.BeginPath;
    Ctx.Ellipse(Blobs[i].x, Blobs[i].y, Blobs[i].r * 1.7, Blobs[i].r * 1.6,
                0, 0, 2 * Pi);
    Ctx.Fill;
  end;
  Ctx.SetGlobalAlpha(1);
end;

{ A specular dab near each blob centre (its centre is always deep inside the
  iso, so the highlight never floats free of the wax). }
procedure Speculars(Ctx: TTina4Canvas2D);
var i: Integer;
begin
  Ctx.SetGlobalAlpha(0.30);
  Ctx.SetFillColor(Col(255, 255, 226, 190));
  for i := 0 to NBLOBS - 1 do
  begin
    Ctx.BeginPath;
    Ctx.Ellipse(Blobs[i].x - Blobs[i].r * 0.30, Blobs[i].y - Blobs[i].r * 0.34,
                Blobs[i].r * 0.20, Blobs[i].r * 0.14, 0, 0, 2 * Pi);
    Ctx.Fill;
  end;
  Ctx.SetGlobalAlpha(1);
end;

{ The tapered glass vessel outline as a closed path (rounded top and bottom). }
procedure VesselPath(Ctx: TTina4Canvas2D);
begin
  Ctx.BeginPath;
  Ctx.MoveTo(Cx - RTop, GyTop + 8);
  Ctx.QuadraticCurveTo(Cx, GyTop - 18, Cx + RTop, GyTop + 8);
  Ctx.LineTo(Cx + RBot, GyBot - 12);
  Ctx.QuadraticCurveTo(Cx, GyBot + 26, Cx - RBot, GyBot - 12);
  Ctx.ClosePath;
end;

procedure PaintLava(Ctx: TTina4Canvas2D);
var
  nowT, dt: Double;
  i: Integer;
  t: Single;
begin
  EnsureGeom(Ctx.Width, Ctx.Height);
  if not Ready then begin Seed; LastClock := AnimClock; end;

  nowT := AnimClock;
  dt   := nowT - LastClock;
  LastClock := nowT;
  if dt < 0 then dt := 0;
  if dt > 0.05 then dt := 0.05;   { a stall must not fast-forward the sim }
  Step(dt, nowT);

  { Dark room backdrop with a soft vertical wash. }
  Ctx.SetFillColor(Col(255, 11, 7, 16));
  Ctx.FillRect(0, 0, W, H);
  for i := 0 to 7 do
  begin
    t := i / 7;
    Ctx.SetGlobalAlpha(0.05);
    Ctx.SetFillColor(Col(255, Round(Mix(40, 12, t)), 20, Round(Mix(70, 26, t))));
    Ctx.FillRect(0, t * H, W, H / 7 + 1);
  end;
  Ctx.SetGlobalAlpha(1);

  { Metal base (heater) below the glass. }
  Ctx.SetFillColor(Col(255, 60, 58, 74));
  Ctx.BeginPath;
  Ctx.MoveTo(Cx - W * 0.20, GyBot + 6);
  Ctx.LineTo(Cx + W * 0.20, GyBot + 6);
  Ctx.LineTo(Cx + W * 0.30, H - 2);
  Ctx.LineTo(Cx - W * 0.30, H - 2);
  Ctx.ClosePath;
  Ctx.Fill;
  Ctx.SetFillColor(Col(255, 96, 94, 116));
  Ctx.FillRect(Cx - W * 0.20, GyBot + 6, W * 0.40, 5);

  { Liquid fill inside the vessel. }
  Ctx.SetFillColor(Col(255, 26, 14, 46));
  VesselPath(Ctx);
  Ctx.Fill;

  { Warm bulb glow rising from the heater at the base of the liquid. }
  for i := 5 downto 1 do
  begin
    Ctx.SetGlobalAlpha(0.10);
    Ctx.SetFillColor(Col(255, 255, 150, 70));
    Ctx.BeginPath;
    Ctx.Ellipse(Cx, GyBot - 8, RBot * (i / 5), RBot * 0.5 * (i / 5), 0, 0, 2 * Pi);
    Ctx.Fill;
  end;
  Ctx.SetGlobalAlpha(1);

  { The wax — a true metaball surface that merges and splits. }
  GlowUnder(Ctx);
  FillWax(Ctx, 1.0);
  Speculars(Ctx);

  { Glass sheen: a bright specular stripe down the left, and a rim outline. }
  Ctx.SetGlobalAlpha(0.10);
  Ctx.SetFillColor(Col(255, 255, 255, 255));
  Ctx.BeginPath;
  Ctx.Ellipse(Cx - RBot * 0.55, (GyTop + GyBot) * 0.5, W * 0.03, (GyBot - GyTop) * 0.42,
              0, 0, 2 * Pi);
  Ctx.Fill;
  Ctx.SetGlobalAlpha(1);
  Ctx.SetStrokeColor(Col(150, 190, 170, 255));
  Ctx.SetLineWidth(2);
  VesselPath(Ctx);
  Ctx.Stroke;

  { Metal cap on top of the glass. }
  Ctx.SetFillColor(Col(255, 60, 58, 74));
  Ctx.BeginPath;
  Ctx.MoveTo(Cx - RTop * 1.15, GyTop + 6);
  Ctx.LineTo(Cx + RTop * 1.15, GyTop + 6);
  Ctx.LineTo(Cx + W * 0.10, 2);
  Ctx.LineTo(Cx - W * 0.10, 2);
  Ctx.ClosePath;
  Ctx.Fill;

  { Keep the repaint loop alive so the sim advances next frame. }
  AnimMarkActive;
end;

procedure RegisterAppActions;
begin
  RegisterCanvasPainter('lava', @PaintLava);
end;

initialization
  { Float-heavy canvas math must not trap: the engine wraps the painter in a
    try/except, so an unmasked SIGFPE (div-by-zero / invalid / overflow from the
    metaball field) would silently abort the whole frame. Mask them so NaN/Inf
    propagate harmlessly instead. }
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,
                    exOverflow, exUnderflow, exPrecision]);
  Randomize;
  RegisterAppActions;
end.
