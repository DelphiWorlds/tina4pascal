unit AppLogic;

{ Dashboard behaviour — in Pascal, not JavaScript.

  The engine has no script runtime (ADR-0002/0009): a tap routes to a named
  action here. This unit powers the theme toggle (flip the <body data-theme>, so
  the design system's light/dark tokens re-cascade) and a demo "New project"
  button — proving an interactive, themed app needs zero JS. }

{$mode delphi}{$H+}

interface

procedure RegisterAppActions;

implementation

uses
  SysUtils,
  Tina4HTMLDom,    // THTMLTag
  Tina4Events,     // RegisterAction
  Tina4Builtins;   // BuiltinsRoot, FindById, SetElementText, BuiltinsDirty

{ Toggle the whole UI between dark and light by flipping the data-theme attribute
  on <body id="app">. tina4pascal.css defines --tina-* tokens for [data-theme=light]
  (and dark on :root), so every surface re-themes from the one attribute. }
procedure ToggleTheme(const Args: string);
var b: THTMLTag;
begin
  b := FindById(BuiltinsRoot, 'app');
  if b = nil then Exit;
  if SameText(b.GetAttribute('data-theme'), 'light') then
    b.Attributes.Remove('data-theme')               // back to the dark :root default
  else
    b.Attributes.AddOrSetValue('data-theme', 'light');
  BuiltinsDirty := True;                             // re-cascade + repaint
end;

var Deploys: Integer = 0;

procedure NewProject(const Args: string);
var n: THTMLTag;
begin
  Inc(Deploys);
  n := FindById(BuiltinsRoot, 'note');
  if n <> nil then SetElementText(n,
    'Queued ' + IntToStr(Deploys) + ' new deployment(s) — this ran in Pascal, no JavaScript.');
  BuiltinsDirty := True;
end;

procedure RegisterAppActions;
begin
  RegisterAction('app.theme', TTina4ActionProc(@ToggleTheme));
  RegisterAction('app.deploy', TTina4ActionProc(@NewProject));
end;

initialization
  RegisterAppActions;
end.
