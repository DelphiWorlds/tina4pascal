unit Tina4Capabilities;

{$mode delphi}{$H+}

interface

type
  TTina4CapabilityStatus = (
    tcsSuccess, tcsStarted, tcsUnsupported, tcsInvalidArgument,
    tcsPermissionDenied, tcsUnavailable, tcsCancelled, tcsFailed
  );

function Tina4CapabilityStatusName(Status: TTina4CapabilityStatus): string;

implementation

function Tina4CapabilityStatusName(Status: TTina4CapabilityStatus): string;
begin
  case Status of
    tcsSuccess:          Result := 'success';
    tcsStarted:          Result := 'started';
    tcsUnsupported:      Result := 'unsupported';
    tcsInvalidArgument:  Result := 'invalid_argument';
    tcsPermissionDenied: Result := 'permission_denied';
    tcsUnavailable:      Result := 'unavailable';
    tcsCancelled:        Result := 'cancelled';
    tcsFailed:           Result := 'failed';
  else
    Result := 'failed';
  end;
end;

end.
