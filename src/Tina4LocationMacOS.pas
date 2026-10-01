unit Tina4LocationMacOS;

{$mode delphi}{$H+}
{$modeswitch objectivec1}

interface

procedure InstallMacOSLocation;

implementation

uses CocoaAll, CoreLocation, Tina4Location, Tina4Capabilities;

type
  { The FPC 3.2.2 CoreLocation binding predates this selector. }
  CLLocationManagerAuthorization = objccategory external (CLLocationManager)
    procedure requestWhenInUseAuthorization; message 'requestWhenInUseAuthorization';
  end;

  TLocationDelegate = objcclass(NSObject)
    Manager: CLLocationManager;
    Requesting: Boolean;
    procedure locationManager_didUpdateLocations(AManager: CLLocationManager;
      Locations: NSArray); message 'locationManager:didUpdateLocations:';
    procedure locationManager_didFailWithError(AManager: CLLocationManager;
      Error: NSError); message 'locationManager:didFailWithError:';
    procedure locationManagerDidChangeAuthorization(AManager: CLLocationManager);
      message 'locationManagerDidChangeAuthorization:';
    procedure locationManager_didChangeAuthorizationStatus(AManager: CLLocationManager;
      Status: CLAuthorizationStatus); message 'locationManager:didChangeAuthorizationStatus:';
  end;

var GDelegate: TLocationDelegate = nil;

procedure DeliverLocation(Location: CLLocation);
var C: CLLocationCoordinate2D; D: Double;
begin
  if Location = nil then Exit;
  C := Location.coordinate; D := 0;
  if Location.timestamp <> nil then D := Location.timestamp.timeIntervalSince1970;
  Tina4LocationDeliver(tcsSuccess, C.latitude, C.longitude,
    Location.horizontalAccuracy, Location.altitude, Location.speed, D, '');
end;

procedure TLocationDelegate.locationManager_didUpdateLocations(AManager: CLLocationManager;
  Locations: NSArray);
var L: CLLocation;
begin
  if (Locations = nil) or (Locations.count = 0) then Exit;
  L := CLLocation(Locations.objectAtIndex(Locations.count - 1));
  DeliverLocation(L); Requesting := False;
end;

procedure TLocationDelegate.locationManager_didFailWithError(AManager: CLLocationManager;
  Error: NSError);
begin
  Tina4LocationDeliver(tcsFailed, 0, 0, 0, 0, 0, 0,
    string(Error.localizedDescription.UTF8String));
end;

procedure TLocationDelegate.locationManagerDidChangeAuthorization(AManager: CLLocationManager);
begin
  locationManager_didChangeAuthorizationStatus(AManager,
    CLLocationManager.authorizationStatus);
end;

procedure TLocationDelegate.locationManager_didChangeAuthorizationStatus(AManager: CLLocationManager;
  Status: CLAuthorizationStatus);
begin
  if Status = kCLAuthorizationStatusDenied then
    Tina4LocationDeliver(tcsPermissionDenied, 0, 0, 0, 0, 0, 0, 'location permission denied')
  else if (Status = kCLAuthorizationStatusAuthorized) and Requesting then
    AManager.startUpdatingLocation;
end;

function EnsureManager: CLLocationManager;
begin
  if GDelegate = nil then
  begin
    GDelegate := TLocationDelegate.alloc.init;
    GDelegate.Manager := CLLocationManager(CLLocationManager.alloc.init);
    GDelegate.Manager.setDelegate(CLLocationManagerDelegateProtocol(GDelegate));
    GDelegate.Manager.setDesiredAccuracy(kCLLocationAccuracyBest);
    GDelegate.Manager.setDistanceFilter(kCLDistanceFilterNone);
  end;
  Result := GDelegate.Manager;
end;

function MacStart: TTina4CapabilityStatus;
var M: CLLocationManager; S: CLAuthorizationStatus;
begin
  M := EnsureManager; GDelegate.Requesting := True;
  S := CLLocationManager.authorizationStatus;
  if S = kCLAuthorizationStatusNotDetermined then M.requestWhenInUseAuthorization
  else if S = kCLAuthorizationStatusAuthorized then M.startUpdatingLocation
  else if S = kCLAuthorizationStatusDenied then
    Tina4LocationDeliver(tcsPermissionDenied, 0, 0, 0, 0, 0, 0, 'location permission denied');
  Result := tcsStarted;
end;

function MacStop: TTina4CapabilityStatus;
begin
  if GDelegate <> nil then begin GDelegate.Requesting := False; GDelegate.Manager.stopUpdatingLocation; end;
  Result := tcsSuccess;
end;

function MacRequest: TTina4CapabilityStatus;
begin
  EnsureManager.requestWhenInUseAuthorization; Result := tcsStarted;
end;

procedure InstallMacOSLocation;
begin
  Tina4SetLocationStart(@MacStart);
  Tina4SetLocationStop(@MacStop);
  Tina4SetLocationRequest(@MacRequest);
end;

initialization
  InstallMacOSLocation;

end.
