unit AppLogic;

{ A live data list — add rows, delete any row, live count. The rows ARE the DOM:
  actions build <tr> nodes and append them to the <tbody>, or find a row by id and
  remove it. No separate model to keep in sync — the table is the source of truth. }

{$mode delphi}{$H+}

interface

procedure RegisterAppActions;

implementation

uses
  SysUtils,
  Tina4HTMLDom,    // THTMLTag
  Tina4Events,     // RegisterAction
  Tina4Builtins;   // BuiltinsRoot, FindById, SetElementText, BuiltinsDirty

var
  GNextId: Integer = 100;   // ids for rows added at runtime (static rows use 1..3)

{ Strip surrounding quotes from an onclick arg, e.g. list.del('row5'). }
function Unq(const S: string): string;
begin
  Result := Trim(S);
  if (Length(Result) >= 2) and ((Result[1] = '''') or (Result[1] = '"')) then
    Result := Copy(Result, 2, Length(Result) - 2);
end;

{ A <td> with text and the shared cell padding. }
function Cell(Parent: THTMLTag; const Text: string): THTMLTag;
var td, tn: THTMLTag;
begin
  td := THTMLTag.Create; td.TagName := 'td'; td.Parent := Parent;
  td.Style.AddOrSetValue('padding', '10px 12px');
  tn := THTMLTag.Create; tn.TagName := '#text'; tn.Text := Text; tn.Parent := td;
  td.Children.Add(tn);
  Parent.Children.Add(td);
  Result := td;
end;

{ Recount the <tbody> rows into #count. }
procedure Recount;
var rows, c, n: THTMLTag; i: Integer;
begin
  rows := FindById(BuiltinsRoot, 'rows');
  n := FindById(BuiltinsRoot, 'count');
  if (rows = nil) or (n = nil) then Exit;
  i := 0;
  for c in rows.Children do if SameText(c.TagName, 'tr') then Inc(i);
  SetElementText(n, IntToStr(i) + ' item(s)');
end;

procedure Add(const Args: string);
var rows, tr, td, btn, tn, inp: THTMLTag; name, rid: string;
begin
  inp := FindById(BuiltinsRoot, 'newitem');
  rows := FindById(BuiltinsRoot, 'rows');
  if (inp = nil) or (rows = nil) then Exit;
  name := Trim(inp.GetAttribute('value'));
  if name = '' then Exit;
  Inc(GNextId); rid := 'row' + IntToStr(GNextId);

  tr := THTMLTag.Create; tr.TagName := 'tr'; tr.Parent := rows;
  tr.Attributes.AddOrSetValue('id', rid);
  tr.Style.AddOrSetValue('border-top', '1px solid #e2e8f0');

  Cell(tr, IntToStr(GNextId - 100));
  Cell(tr, name);

  { action cell with a delete button bound to this row id }
  td := THTMLTag.Create; td.TagName := 'td'; td.Parent := tr;
  td.Style.AddOrSetValue('padding', '8px 12px'); td.Style.AddOrSetValue('text-align', 'right');
  btn := THTMLTag.Create; btn.TagName := 'button'; btn.Parent := td;
  btn.Attributes.AddOrSetValue('onclick', 'list.del(''' + rid + ''')');
  btn.Style.AddOrSetValue('padding', '5px 10px');
  btn.Style.AddOrSetValue('border', '1px solid #fecaca');
  btn.Style.AddOrSetValue('border-radius', '6px');
  btn.Style.AddOrSetValue('background', '#fef2f2');
  btn.Style.AddOrSetValue('color', '#dc2626');
  tn := THTMLTag.Create; tn.TagName := '#text'; tn.Text := 'Delete'; tn.Parent := btn;
  btn.Children.Add(tn);
  td.Children.Add(btn);
  tr.Children.Add(td);

  rows.Children.Add(tr);
  inp.Attributes.AddOrSetValue('value', '');   // clear the input
  Recount;
  BuiltinsDirty := True;
end;

procedure Del(const Args: string);
var row: THTMLTag;
begin
  row := FindById(BuiltinsRoot, Unq(Args));
  if row = nil then Exit;
  row.Free;                 // detaches from its parent in Destroy
  Recount;
  BuiltinsDirty := True;
end;

procedure Clear(const Args: string);
var rows: THTMLTag; i: Integer;
begin
  rows := FindById(BuiltinsRoot, 'rows');
  if rows = nil then Exit;
  for i := rows.Children.Count - 1 downto 0 do
    if SameText(rows.Children[i].TagName, 'tr') then rows.Children[i].Free;
  Recount;
  BuiltinsDirty := True;
end;

procedure RegisterAppActions;
begin
  RegisterAction('list.add',   TTina4ActionProc(@Add));
  RegisterAction('list.del',   TTina4ActionProc(@Del));
  RegisterAction('list.clear', TTina4ActionProc(@Clear));
end;

initialization
  RegisterAppActions;
end.
