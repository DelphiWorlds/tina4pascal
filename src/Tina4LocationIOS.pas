unit Tina4LocationIOS;

{$mode delphi}{$H+}

interface

procedure InstallIOSLocation;

implementation

uses Tina4Location, Tina4Capabilities;

procedure tina4_ios_location_start; cdecl; external name 'tina4_ios_location_start';
procedure tina4_ios_location_stop; cdecl; external name 'tina4_ios_location_stop';
procedure tina4_ios_location_request; cdecl; external name 'tina4_ios_location_request';

function IOSStart: TTina4CapabilityStatus;
begin tina4_ios_location_start; Result := tcsStarted; end;

function IOSStop: TTina4CapabilityStatus;
begin tina4_ios_location_stop; Result := tcsSuccess; end;

function IOSRequest: TTina4CapabilityStatus;
begin tina4_ios_location_request; Result := tcsStarted; end;

procedure InstallIOSLocation;
begin
  Tina4SetLocationStart(@IOSStart);
  Tina4SetLocationStop(@IOSStop);
  Tina4SetLocationRequest(@IOSRequest);
end;

initialization
  InstallIOSLocation;

end.
