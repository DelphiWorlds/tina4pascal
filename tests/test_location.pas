program test_location;

{$mode delphi}{$H+}

uses SysUtils, Tina4Capabilities, Tina4Location;

var Passed, Failed: Integer;
    SeenStatus: TTina4CapabilityStatus;
    SeenLocation: TTina4Location;

procedure Check(Cond: Boolean; const Name: string);
begin
  if Cond then Inc(Passed)
  else begin Inc(Failed); Writeln('FAIL: ', Name); end;
end;

procedure Seen(Status: TTina4CapabilityStatus; const Location: TTina4Location;
  const Error: string);
begin
  SeenStatus := Status; SeenLocation := Location;
end;

begin
  Passed := 0; Failed := 0;
  Tina4SetLocationCallback(@Seen);
  Check(Tina4LocationStart = tcsUnsupported, 'no adapter is unsupported');
  Tina4LocationDeliver(tcsSuccess, -33.8568, 151.2153, 5, 12, 0, 123, '');
  Check(SeenStatus = tcsSuccess, 'callback status');
  Check(Abs(SeenLocation.Latitude - (-33.8568)) < 0.00001, 'latitude delivered');
  Check(Abs(SeenLocation.Longitude - 151.2153) < 0.00001, 'longitude delivered');
  Check(Tina4LocationStop = tcsUnsupported, 'stop without adapter is unsupported');
  Check(Tina4LocationRequest = tcsUnsupported, 'request without adapter is unsupported');
  Writeln(Passed, ' assertions passed, ', Failed, ' failed.');
  if Failed = 0 then begin Writeln('ALL TESTS PASS'); Halt(0); end
  else Halt(1);
end.
