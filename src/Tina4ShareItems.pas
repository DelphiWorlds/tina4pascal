unit Tina4ShareItems;

{ Cross-platform share-items contract. Images are supplied as local files so
  native hosts never receive a TBitmap or managed Pascal memory. }

{$mode delphi}{$H+}

interface

uses SysUtils, Tina4Capabilities;

type
  TTina4ShareItemKind = (tsikText, tsikFile, tsikImage);
  TTina4ShareItem = record
    Kind: TTina4ShareItemKind;
    Value: string;
  end;
  TTina4ShareItemArray = array of TTina4ShareItem;
  TTina4SharePlatformProc = function(const Items: TTina4ShareItemArray;
    const Anchor: string): TTina4CapabilityStatus;
  TTina4ShareCompletedProc = procedure(Status: TTina4CapabilityStatus;
    const Activity, Error: string);

  TTina4ShareItems = class
  private
    FItems: TTina4ShareItemArray;
  public
    procedure AddText(const Text: string);
    procedure AddFile(const FileName: string);
    procedure AddImageFile(const FileName: string);
    procedure Clear;
    function Count: Integer;
    function Share(const Anchor: string = ''): TTina4CapabilityStatus;
    function Item(Index: Integer): TTina4ShareItem;
  end;

procedure Tina4SetSharePlatform(P: TTina4SharePlatformProc);
procedure Tina4SetShareCompletedHandler(P: TTina4ShareCompletedProc);
procedure Tina4ShareComplete(Status: TTina4CapabilityStatus;
  const Activity, Error: string);
function Tina4ShareItemsToJSON(const Items: TTina4ShareItemArray): string;

implementation

var
  GSharePlatform: TTina4SharePlatformProc = nil;
  GShareCompleted: TTina4ShareCompletedProc = nil;

function JsonEscape(const S: string): string;
var I: Integer; C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    case C of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #12: Result := Result + '\f';
      #13: Result := Result + '\r';
    else
      if Ord(C) < 32 then Result := Result + '\u00' + IntToHex(Ord(C), 2)
      else Result := Result + C;
    end;
  end;
end;

function KindName(Kind: TTina4ShareItemKind): string;
begin
  case Kind of
    tsikText: Result := 'text';
    tsikFile: Result := 'file';
    tsikImage: Result := 'image';
  else Result := 'unknown';
  end;
end;

function Tina4ShareItemsToJSON(const Items: TTina4ShareItemArray): string;
var I: Integer;
begin
  Result := '[';
  for I := 0 to Length(Items) - 1 do
  begin
    if I > 0 then Result := Result + ',';
    Result := Result + '{"kind":"' + KindName(Items[I].Kind) +
      '","value":"' + JsonEscape(Items[I].Value) + '"}';
  end;
  Result := Result + ']';
end;

procedure Tina4SetSharePlatform(P: TTina4SharePlatformProc);
begin GSharePlatform := P; end;

procedure Tina4SetShareCompletedHandler(P: TTina4ShareCompletedProc);
begin GShareCompleted := P; end;

procedure Tina4ShareComplete(Status: TTina4CapabilityStatus;
  const Activity, Error: string);
begin
  if Assigned(GShareCompleted) then GShareCompleted(Status, Activity, Error);
end;

procedure TTina4ShareItems.AddText(const Text: string);
var I: Integer;
begin
  I := Length(FItems); SetLength(FItems, I + 1);
  FItems[I].Kind := tsikText; FItems[I].Value := Text;
end;

procedure TTina4ShareItems.AddFile(const FileName: string);
var I: Integer;
begin
  I := Length(FItems); SetLength(FItems, I + 1);
  FItems[I].Kind := tsikFile; FItems[I].Value := FileName;
end;

procedure TTina4ShareItems.AddImageFile(const FileName: string);
var I: Integer;
begin
  I := Length(FItems); SetLength(FItems, I + 1);
  FItems[I].Kind := tsikImage; FItems[I].Value := FileName;
end;

procedure TTina4ShareItems.Clear;
begin SetLength(FItems, 0); end;

function TTina4ShareItems.Count: Integer;
begin Result := Length(FItems); end;

function TTina4ShareItems.Item(Index: Integer): TTina4ShareItem;
begin
  if (Index < 0) or (Index >= Length(FItems)) then
    raise ERangeError.CreateFmt('Share item index out of range: %d', [Index]);
  Result := FItems[Index];
end;

function TTina4ShareItems.Share(const Anchor: string): TTina4CapabilityStatus;
var I: Integer;
begin
  if Length(FItems) = 0 then Exit(tcsInvalidArgument);
  for I := 0 to Length(FItems) - 1 do
  begin
    if FItems[I].Value = '' then Exit(tcsInvalidArgument);
    if (FItems[I].Kind in [tsikFile, tsikImage]) and
       not FileExists(FItems[I].Value) then Exit(tcsInvalidArgument);
  end;
  if not Assigned(GSharePlatform) then Exit(tcsUnsupported);
  Result := GSharePlatform(FItems, Anchor);
end;

end.
