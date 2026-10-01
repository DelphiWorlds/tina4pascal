program test_codearea;

{
  Real (no-mock) console test for the <codearea> control's VALUE semantics — the
  part that makes it a real form field. Asserts the parser seeds `value` from the
  body, honours an explicit value attribute, and keeps the body LITERAL (so PHP's
  <?php and a bare '<' are not mis-parsed as tags). Exits 0 with 'ALL TESTS PASS'.
}

{$mode delphi}{$H+}

uses
  SysUtils, Generics.Collections, Tina4HTMLDom;

var
  PassCount: Integer = 0;

procedure Check(Cond: Boolean; const Msg: string);
begin
  if Cond then Inc(PassCount)
  else begin Writeln('FAIL: ', Msg); Halt(1); end;
end;

{ First descendant (or self) with the given tag name, else nil. }
function FirstTag(Root: THTMLTag; const Name: string): THTMLTag;
var c: THTMLTag;
begin
  Result := nil;
  if Root = nil then Exit;
  if SameText(Root.TagName, Name) then Exit(Root);
  for c in Root.Children do
  begin
    Result := FirstTag(c, Name);
    if Result <> nil then Exit;
  end;
end;

function ElementChildCount(T: THTMLTag): Integer;
var c: THTMLTag;
begin
  Result := 0;
  for c in T.Children do
    if c.TagName <> '#text' then Inc(Result);
end;

var
  P: THTMLParser;
  ca: THTMLTag;
begin
  { body seeds value }
  P := THTMLParser.Create;
  try
    P.Parse('<body><codearea lang="pascal">begin end;</codearea></body>');
    ca := FirstTag(P.Root, 'codearea');
    Check(ca <> nil, 'codearea parsed');
    Check(ca.GetAttribute('lang') = 'pascal', 'lang attribute preserved');
    Check(ca.GetAttribute('value') = 'begin end;', 'value seeded from body');
  finally P.Free; end;

  { explicit value attribute wins over body }
  P := THTMLParser.Create;
  try
    P.Parse('<codearea value="X">ignored body</codearea>');
    ca := FirstTag(P.Root, 'codearea');
    Check(ca.GetAttribute('value') = 'X', 'explicit value attribute wins');
  finally P.Free; end;

  { literal body: '<' and <?php are NOT parsed as tags }
  P := THTMLParser.Create;
  try
    P.Parse('<codearea lang="php"><?php if ($a < 3) echo $a; ?></codearea>');
    ca := FirstTag(P.Root, 'codearea');
    Check(ca <> nil, 'php codearea parsed');
    Check(Pos('<?php', ca.GetAttribute('value')) > 0, 'literal <?php kept in value');
    Check(Pos('< 3', ca.GetAttribute('value')) > 0, 'bare < kept literally');
    Check(ElementChildCount(ca) = 0, 'no element children (body not parsed as tags)');
  finally P.Free; end;

  { multi-line body keeps newlines (preformatted) }
  P := THTMLParser.Create;
  try
    P.Parse('<codearea>line1'#10'line2</codearea>');
    ca := FirstTag(P.Root, 'codearea');
    Check(Pos(#10, ca.GetAttribute('value')) > 0, 'newline preserved in value');
  finally P.Free; end;

  Writeln;
  Writeln(PassCount, ' assertions passed.');
  Writeln('ALL TESTS PASS');
end.
