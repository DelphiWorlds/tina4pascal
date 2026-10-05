unit Tina4ShareItemsIOS;

{$mode delphi}{$H+}

interface

procedure InstallIOSShareItems;

implementation

uses Tina4ShareItems, Tina4Capabilities;

procedure tina4_ios_share_items(Json, Anchor: PAnsiChar); cdecl;
  external name 'tina4_ios_share_items';

function IOSShare(const Items: TTina4ShareItemArray;
  const Anchor: string): TTina4CapabilityStatus;
var J, A: AnsiString;
begin
  J := AnsiString(Tina4ShareItemsToJSON(Items));
  A := AnsiString(Anchor);
  tina4_ios_share_items(PAnsiChar(J), PAnsiChar(A));
  Result := tcsStarted;
end;

procedure InstallIOSShareItems;
begin
  Tina4SetSharePlatform(@IOSShare);
end;

initialization
  InstallIOSShareItems;

end.
