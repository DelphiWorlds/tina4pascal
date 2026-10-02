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
  Tina4Builtins,   // BuiltinsRoot, FindById, SetElementText, BuiltinsDirty
  Tina4Interact;   // TinaSetColorScheme — the engine-native dark/light switch

var Dark: Boolean = True;   // dashboard opens dark (the brand default)

{ Toggle the whole UI between dark and light. tina4pascal.css puts the dark tokens
  on :root and the light tokens in a prefers-color-scheme:light @media block, which
  the engine drives from TinaSetColorScheme — so one call re-themes every surface. }
procedure ToggleTheme(const Args: string);
begin
  Dark := not Dark;
  TinaSetColorScheme(Dark);   // flips @media(prefers-color-scheme) + re-cascades
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
  TinaSetColorScheme(Dark);   // open in dark regardless of the host OS appearance
end.
