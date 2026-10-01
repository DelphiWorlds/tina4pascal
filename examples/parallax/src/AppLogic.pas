unit AppLogic;

{ Scroll-linked parallax, driven by the engine's onscroll dispatch.

  The <body onscroll="plx.scroll()"> fires this on every scroll; the engine passes
  the current scroll offset (CSS px) as the argument. We move layers at different
  rates (the logo drifts at half speed, the caption rises) and grow a progress bar
  — the classic multi-rate parallax, in pure Pascal. }

{$mode delphi}{$H+}

interface

procedure RegisterAppActions;

implementation

uses
  SysUtils,
  Tina4HTMLDom,    // THTMLTag
  Tina4Events,     // RegisterAction
  Tina4Builtins;   // BuiltinsRoot, FindById, BuiltinsDirty

procedure SetTransform(const Id, Value: string);
var t: THTMLTag;
begin
  t := FindById(BuiltinsRoot, Id);
  if t <> nil then t.Style.AddOrSetValue('transform', Value);
end;

procedure SetWidthPct(const Id: string; Pct: Integer);
var t: THTMLTag;
begin
  t := FindById(BuiltinsRoot, Id);
  if t <> nil then t.Style.AddOrSetValue('width', IntToStr(Pct) + '%');
end;

procedure Scroll(const Args: string);
var y, w: Integer;
begin
  y := StrToIntDef(Trim(Args), 0);
  // the logo drifts DOWN at half the scroll rate → net rises at half speed (parallax)
  SetTransform('logo', 'translateY(' + IntToStr(y div 2) + 'px)');
  // the caption rises faster than the page for depth
  SetTransform('cap', 'translateY(' + IntToStr(-(y div 4)) + 'px)');
  // a scroll-progress bar across the top
  w := y div 6; if w > 100 then w := 100; if w < 0 then w := 0;
  SetWidthPct('bar', w);
  BuiltinsDirty := True;
end;

procedure RegisterAppActions;
begin
  RegisterAction('plx.scroll', TTina4ActionProc(@Scroll));
end;

initialization
  RegisterAppActions;
end.
