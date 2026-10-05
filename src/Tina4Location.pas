unit Tina4Location;

{ Foreground location contract. Native adapters own permission prompts and
  lifecycle; this unit only stores portable values and delivers callbacks. }

{$mode delphi}{$H+}

interface

uses Tina4Capabilities;

type
  TTina4Location = record
    Latitude: Double;
    Longitude: Double;
    Accuracy: Double;
    Altitude: Double;
    Speed: Double;
    Timestamp: Double;
  end;

  TTina4LocationCallback = procedure(Status: TTina4CapabilityStatus;
    const Location: TTina4Location; const Error: string);
  TTina4LocationStartProc = function: TTina4CapabilityStatus;
  TTina4LocationStopProc = function: TTina4CapabilityStatus;
  TTina4LocationRequestProc = function: TTina4CapabilityStatus;
  TTina4LocationBackgroundStartProc = function: TTina4CapabilityStatus;

procedure Tina4SetLocationStart(P: TTina4LocationStartProc);
procedure Tina4SetLocationStop(P: TTina4LocationStopProc);
procedure Tina4SetLocationRequest(P: TTina4LocationRequestProc);
procedure Tina4SetLocationBackgroundStart(P: TTina4LocationBackgroundStartProc);
procedure Tina4SetLocationCallback(P: TTina4LocationCallback);

function Tina4LocationStart: TTina4CapabilityStatus;
function Tina4LocationStop: TTina4CapabilityStatus;
function Tina4LocationRequest: TTina4CapabilityStatus;
function Tina4LocationStartBackground: TTina4CapabilityStatus;
procedure Tina4LocationDeliver(Status: TTina4CapabilityStatus;
  Latitude, Longitude, Accuracy, Altitude, Speed, Timestamp: Double;
  const Error: string);

implementation

var
  GStart: TTina4LocationStartProc = nil;
  GStop: TTina4LocationStopProc = nil;
  GRequest: TTina4LocationRequestProc = nil;
  GBackgroundStart: TTina4LocationBackgroundStartProc = nil;
  GCallback: TTina4LocationCallback = nil;

procedure Tina4SetLocationStart(P: TTina4LocationStartProc); begin GStart := P; end;
procedure Tina4SetLocationStop(P: TTina4LocationStopProc); begin GStop := P; end;
procedure Tina4SetLocationRequest(P: TTina4LocationRequestProc); begin GRequest := P; end;
procedure Tina4SetLocationBackgroundStart(P: TTina4LocationBackgroundStartProc); begin GBackgroundStart := P; end;
procedure Tina4SetLocationCallback(P: TTina4LocationCallback); begin GCallback := P; end;

function Tina4LocationStart: TTina4CapabilityStatus;
begin
  if not Assigned(GStart) then Exit(tcsUnsupported);
  Result := GStart;
end;

function Tina4LocationStop: TTina4CapabilityStatus;
begin
  if not Assigned(GStop) then Exit(tcsUnsupported);
  Result := GStop;
end;

function Tina4LocationRequest: TTina4CapabilityStatus;
begin
  if not Assigned(GRequest) then Exit(tcsUnsupported);
  Result := GRequest;
end;

function Tina4LocationStartBackground: TTina4CapabilityStatus;
begin
  if not Assigned(GBackgroundStart) then Exit(tcsUnsupported);
  Result := GBackgroundStart;
end;

procedure Tina4LocationDeliver(Status: TTina4CapabilityStatus;
  Latitude, Longitude, Accuracy, Altitude, Speed, Timestamp: Double;
  const Error: string);
var L: TTina4Location;
begin
  L.Latitude := Latitude; L.Longitude := Longitude; L.Accuracy := Accuracy;
  L.Altitude := Altitude; L.Speed := Speed; L.Timestamp := Timestamp;
  if Assigned(GCallback) then GCallback(Status, L, Error);
end;

end.
