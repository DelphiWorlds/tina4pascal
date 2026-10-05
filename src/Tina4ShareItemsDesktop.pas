unit Tina4ShareItemsDesktop;

{$mode delphi}{$H+}

interface

procedure InstallDesktopShareItems;

implementation

uses Tina4ShareItems, Tina4Capabilities;

function DesktopShare(const Items: TTina4ShareItemArray;
  const Anchor: string): TTina4CapabilityStatus;
begin
  Result := tcsUnsupported;
end;

procedure InstallDesktopShareItems;
begin
  Tina4SetSharePlatform(@DesktopShare);
end;

initialization
  InstallDesktopShareItems;

end.
