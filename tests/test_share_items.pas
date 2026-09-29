program test_share_items;

{$mode delphi}{$H+}

uses
  SysUtils, Classes, Tina4Capabilities, Tina4ShareItems, Tina4ShareItemsDesktop;

var
  Passed, Failed: Integer;
  Shares: TTina4ShareItems;
  TempFile: string;
  OneItem: TTina4ShareItemArray;

procedure Check(Cond: Boolean; const Name: string);
begin
  if Cond then Inc(Passed)
  else begin Inc(Failed); Writeln('FAIL: ', Name); end;
end;

begin
  Passed := 0; Failed := 0;
  Check(Tina4CapabilityStatusName(tcsUnsupported) = 'unsupported', 'status name');
  Shares := TTina4ShareItems.Create;
  try
    Check(Shares.Share = tcsInvalidArgument, 'empty share rejected');
    Shares.AddText('hello "world"'#10'next');
    Check(Shares.Count = 1, 'text count');
    SetLength(OneItem, 1);
    OneItem[0] := Shares.Item(0);
    Check(Pos('hello \"world\"\nnext', Tina4ShareItemsToJSON(
      OneItem)) > 0, 'json escapes text');
    Check(Shares.Share = tcsUnsupported, 'desktop adapter status');
    Shares.Clear;
    TempFile := GetTempDir + 'tina4-share-test.txt';
    with TStringList.Create do
    try SaveToFile(TempFile); finally Free; end;
    Shares.AddFile(TempFile);
    Check(Shares.Share = tcsUnsupported, 'desktop file placeholder');
    DeleteFile(TempFile);
    Shares.Clear;
    Shares.AddFile(TempFile);
    Check(Shares.Share = tcsInvalidArgument, 'missing file rejected');
  finally
    Shares.Free;
  end;
  Writeln(Passed, ' assertions passed, ', Failed, ' failed.');
  if Failed = 0 then begin Writeln('ALL TESTS PASS'); Halt(0); end
  else Halt(1);
end.
