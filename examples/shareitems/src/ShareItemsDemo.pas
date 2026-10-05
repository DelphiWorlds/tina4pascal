unit ShareItemsDemo;

{ Small, portable integration demo for Tina4ShareItems. The generated files keep
  the demo self-contained: no platform-specific asset path is required. }

{$mode delphi}{$H+}

interface

procedure RegisterShareItemsDemo;

implementation

uses
  SysUtils, Classes,
  Tina4Capabilities,
  Tina4Events,
  Tina4HTMLDom,
  Tina4Builtins,
  Tina4ShareItems;

const
  { A valid 1x1 transparent PNG, used only as a portable test payload. }
  DemoPng: array[0..66] of Byte = (
    $89,$50,$4E,$47,$0D,$0A,$1A,$0A,$00,$00,$00,$0D,$49,$48,$44,$52,
    $00,$00,$00,$01,$00,$00,$00,$01,$08,$06,$00,$00,$00,$1F,$15,$C4,
    $89,$00,$00,$00,$0A,$49,$44,$41,$54,$78,$9C,$63,$00,$01,$00,$00,
    $05,$00,$01,$0D,$0A,$2D,$B4,$00,$00,$00,$00,$49,$45,$4E,$44,$AE,
    $42,$60,$82);

var
  ShareItems: TTina4ShareItems;
  DemoTextFile, DemoImageFile: string;

procedure SetStatus(const S: string);
var T: THTMLTag;
begin
  T := FindById(BuiltinsRoot, 'status');
  if T <> nil then SetElementText(T, S);
  BuiltinsDirty := True;
end;

procedure EnsureDemoFiles;
var F: TFileStream; I: Integer; Dir: string;
begin
  Dir := IncludeTrailingPathDelimiter(GetTempDir) + 'tina4-shareitems-demo';
  ForceDirectories(Dir);
  DemoTextFile := IncludeTrailingPathDelimiter(Dir) + 'share-demo.txt';
  DemoImageFile := IncludeTrailingPathDelimiter(Dir) + 'share-demo.png';
  if not FileExists(DemoTextFile) then
    with TStringList.Create do
    try
      Text := 'Tina4 ShareItems demo file';
      SaveToFile(DemoTextFile);
    finally
      Free;
    end;
  if not FileExists(DemoImageFile) then
  begin
    F := TFileStream.Create(DemoImageFile, fmCreate);
    try
      for I := Low(DemoPng) to High(DemoPng) do F.WriteBuffer(DemoPng[I], 1);
    finally
      F.Free;
    end;
  end;
end;

procedure ShareCompleted(Status: TTina4CapabilityStatus;
  const Activity, Error: string);
begin
  if Error <> '' then
    SetStatus('Completed: ' + Tina4CapabilityStatusName(Status) + ' — ' + Error)
  else if Activity <> '' then
    SetStatus('Completed: ' + Tina4CapabilityStatusName(Status) +
      ' (' + Activity + ')')
  else
    SetStatus('Completed: ' + Tina4CapabilityStatusName(Status));
end;

procedure StartShare(const Description: string);
var Status: TTina4CapabilityStatus;
begin
  EnsureDemoFiles;
  Status := ShareItems.Share;
  SetStatus(Description + ': ' + Tina4CapabilityStatusName(Status) +
    ' (' + IntToStr(ShareItems.Count) + ' item(s))');
end;

procedure ShareText(const Args: string);
begin
  ShareItems.Clear;
  ShareItems.AddText('Hello from Tina4 ShareItems.');
  StartShare('Text share');
end;

procedure ShareFile(const Args: string);
begin
  ShareItems.Clear;
  EnsureDemoFiles;
  ShareItems.AddFile(DemoTextFile);
  StartShare('File share');
end;

procedure ShareImage(const Args: string);
begin
  ShareItems.Clear;
  EnsureDemoFiles;
  ShareItems.AddImageFile(DemoImageFile);
  StartShare('Image share');
end;

procedure ShareMixed(const Args: string);
begin
  ShareItems.Clear;
  EnsureDemoFiles;
  ShareItems.AddText('Tina4 mixed share payload');
  ShareItems.AddFile(DemoTextFile);
  ShareItems.AddImageFile(DemoImageFile);
  StartShare('Mixed share');
end;

procedure ClearShare(const Args: string);
begin
  ShareItems.Clear;
  SetStatus('Cleared. 0 item(s) queued.');
end;

procedure RegisterShareItemsDemo;
begin
  if ShareItems = nil then ShareItems := TTina4ShareItems.Create;
  Tina4SetShareCompletedHandler(@ShareCompleted);
  RegisterAction('share.text', TTina4ActionProc(@ShareText));
  RegisterAction('share.file', TTina4ActionProc(@ShareFile));
  RegisterAction('share.image', TTina4ActionProc(@ShareImage));
  RegisterAction('share.mixed', TTina4ActionProc(@ShareMixed));
  RegisterAction('share.clear', TTina4ActionProc(@ClearShare));
end;

initialization
  RegisterShareItemsDemo;

finalization
  ShareItems.Free;

end.
