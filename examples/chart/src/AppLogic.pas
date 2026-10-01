unit AppLogic;

{ A tiny bar chart, data-driven. Each bar is a <div> whose pixel height encodes a
  value; "Randomize" rebuilds the bars from fresh numbers. Pure layout — the chart
  is HTML the engine already draws (no canvas needed for bars). }

{$mode delphi}{$H+}

interface

procedure RegisterAppActions;

implementation

uses
  SysUtils,
  Tina4HTMLDom,    // THTMLTag
  Tina4Events,     // RegisterAction
  Tina4Builtins;   // BuiltinsRoot, FindById, BuiltinsDirty

const
  BARS = 8;
  MAXH = 200;   // px, the chart body height

{ Re-value the existing bars in place — set each bar's pixel height and its label.
  The bars are the 8 <div>s already in #chart (app.html); we update, never recreate. }
procedure Rebuild(Fixed: Boolean);
var host, bar: THTMLTag; i, h, idx: Integer;
begin
  host := FindById(BuiltinsRoot, 'chart');
  if host = nil then Exit;
  idx := 0;
  for i := 0 to host.Children.Count - 1 do
  begin
    bar := host.Children[i];
    if not SameText(bar.TagName, 'div') then Continue;
    if Fixed then h := 30 + (idx * (MAXH - 30)) div (BARS - 1)   // a tidy ramp
    else h := 24 + Random(MAXH - 24);
    bar.Style.AddOrSetValue('height', IntToStr(h) + 'px');
    SetElementText(bar, IntToStr(h));   // the value label inside the bar
    Inc(idx);
  end;
  BuiltinsDirty := True;
end;

procedure Randomize(const Args: string); begin Rebuild(False); end;
procedure Reset(const Args: string);     begin Rebuild(True);  end;

procedure RegisterAppActions;
begin
  RegisterAction('chart.randomize', TTina4ActionProc(@Randomize));
  RegisterAction('chart.reset',     TTina4ActionProc(@Reset));
end;

initialization
  RegisterAppActions;
end.
