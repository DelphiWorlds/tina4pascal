unit LocationDemo;

{$mode delphi}{$H+}

interface

procedure RegisterLocationDemo;

implementation

uses SysUtils, Tina4Capabilities, Tina4Events, Tina4HTMLDom, Tina4Builtins,
  Tina4Interact, Tina4Location;

var
  LocationUpdateCount: Integer = 0;
  StatusHistory: string = 'Ready.';

procedure SetStatus(const S: string);
var T: THTMLTag;
begin
  T := FindById(BuiltinsRoot, 'status');
  StatusHistory := S + #10#10 + StatusHistory;
  if Length(StatusHistory) > 16000 then
    Delete(StatusHistory, 16001, Length(StatusHistory));
  if T <> nil then SetElementText(T, StatusHistory);
  TinaInvalidateLayout;
  BuiltinsDirty := True;
end;

procedure LocationChanged(Status: TTina4CapabilityStatus;
  const Location: TTina4Location; const Error: string);
begin
  if Status = tcsSuccess then
  begin
    Inc(LocationUpdateCount);
    SetStatus(Format('Location update #%d' + #10 + 'Latitude: %.6f' + #10 +
      'Longitude: %.6f' + #10 + 'Accuracy: %.1f m',
      [LocationUpdateCount, Location.Latitude, Location.Longitude, Location.Accuracy]));
  end
  else if Error <> '' then
    SetStatus('Location: ' + Tina4CapabilityStatusName(Status) + ' — ' + Error)
  else
    SetStatus('Location: ' + Tina4CapabilityStatusName(Status));
end;

procedure RequestLocation(const Args: string);
begin
  SetStatus('Permission request: ' + Tina4CapabilityStatusName(Tina4LocationRequest));
end;

procedure StartLocation(const Args: string);
begin
  SetStatus('Start: ' + Tina4CapabilityStatusName(Tina4LocationStart));
end;

procedure StopLocation(const Args: string);
begin
  SetStatus('Stop: ' + Tina4CapabilityStatusName(Tina4LocationStop));
end;

procedure RegisterLocationDemo;
begin
  Tina4SetLocationCallback(@LocationChanged);
  RegisterAction('location.request', @RequestLocation);
  RegisterAction('location.start', @StartLocation);
  RegisterAction('location.stop', @StopLocation);
end;

initialization
  RegisterLocationDemo;

end.
