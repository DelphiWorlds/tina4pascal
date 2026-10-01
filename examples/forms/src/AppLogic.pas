unit AppLogic;

{ Form validation — read field values, show inline errors, confirm on success.

  The actions read each <input>'s `value` straight from the DOM, write per-field
  error messages into the <small> helpers, and set a result line. No widgets — the
  form is HTML; this unit is just the rules. }

{$mode delphi}{$H+}

interface

procedure RegisterAppActions;

implementation

uses
  SysUtils,
  Tina4HTMLDom,    // THTMLTag
  Tina4Events,     // RegisterAction
  Tina4Builtins;   // BuiltinsRoot, FindById, SetElementText, BuiltinsDirty

{ The trimmed value of input #id. }
function Val(const Id: string): string;
var t: THTMLTag;
begin
  t := FindById(BuiltinsRoot, Id);
  if t <> nil then Result := Trim(t.GetAttribute('value')) else Result := '';
end;

{ Write an error message (red) into helper #id; empty clears it. }
procedure SetErr(const Id, Msg: string);
var t: THTMLTag;
begin
  t := FindById(BuiltinsRoot, Id);
  if t = nil then Exit;
  SetElementText(t, Msg);
  t.Style.AddOrSetValue('color', '#dc2626');
end;

function LooksLikeEmail(const S: string): Boolean;
var at, dot: Integer;
begin
  at := Pos('@', S);
  dot := Pos('.', Copy(S, at + 1, MaxInt));
  Result := (at > 1) and (dot > 1) and (at + dot < Length(S));
end;

procedure Check(const Args: string);
var name, email, ageS: string; age, bad: Integer; res: THTMLTag;
begin
  name := Val('f-name'); email := Val('f-email'); ageS := Val('f-age');
  bad := 0;

  if name = '' then begin SetErr('e-name', 'Name is required'); Inc(bad); end
  else SetErr('e-name', '');

  if email = '' then begin SetErr('e-email', 'Email is required'); Inc(bad); end
  else if not LooksLikeEmail(email) then begin SetErr('e-email', 'That is not a valid email'); Inc(bad); end
  else SetErr('e-email', '');

  if ageS = '' then begin SetErr('e-age', 'Age is required'); Inc(bad); end
  else if (not TryStrToInt(ageS, age)) or (age < 1) or (age > 120) then
    begin SetErr('e-age', 'Age must be 1–120'); Inc(bad); end
  else SetErr('e-age', '');

  res := FindById(BuiltinsRoot, 'result');
  if res <> nil then
  begin
    if bad = 0 then
    begin
      SetElementText(res, 'Thanks, ' + name + ' — form is valid ✓');
      res.Style.AddOrSetValue('color', '#16a34a');
    end
    else
    begin
      SetElementText(res, 'Please fix ' + IntToStr(bad) + ' field(s) above.');
      res.Style.AddOrSetValue('color', '#dc2626');
    end;
  end;
  BuiltinsDirty := True;
end;

procedure RegisterAppActions;
begin
  RegisterAction('form.check', TTina4ActionProc(@Check));
end;

initialization
  RegisterAppActions;
end.
