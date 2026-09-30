unit Tina4LocationAndroid;

{$mode delphi}{$H+}

interface

uses jni;

procedure InstallAndroidLocation(VM: PJavaVM);

implementation

uses Tina4Location, Tina4Capabilities;

var GVM: PJavaVM = nil;

function AndroidLocationCall(const Name, Signature: string): Boolean;
var Env: PJNIEnv; Cls: jclass; Mid: jmethodID;
begin
  Result := False;
  if GVM = nil then Exit;
  Env := nil;
  if GVM^^.GetEnv(GVM, @Env, JNI_VERSION_1_6) <> JNI_OK then
    if GVM^^.AttachCurrentThread(GVM, @Env, nil) <> JNI_OK then Exit;
  Cls := Env^.FindClass(Env, 'com/tina4/pascal/Tina4Location');
  if Cls = nil then Exit;
  Mid := Env^.GetStaticMethodID(Env, Cls, PAnsiChar(Name), PAnsiChar(Signature));
  if Mid = nil then Exit;
  Env^.CallStaticVoidMethodA(Env, Cls, Mid, nil);
  Result := True;
end;

function AndroidStart: TTina4CapabilityStatus;
begin
  if AndroidLocationCall('start', '()V') then Result := tcsStarted
  else Result := tcsUnavailable;
end;

function AndroidStop: TTina4CapabilityStatus;
begin
  if AndroidLocationCall('stop', '()V') then Result := tcsSuccess
  else Result := tcsUnavailable;
end;

function AndroidRequest: TTina4CapabilityStatus;
begin
  if AndroidLocationCall('request', '()V') then Result := tcsStarted
  else Result := tcsUnavailable;
end;

function AndroidBackground: TTina4CapabilityStatus;
begin
  Result := tcsUnsupported;
end;

procedure InstallAndroidLocation(VM: PJavaVM);
begin
  GVM := VM;
  Tina4SetLocationStart(@AndroidStart);
  Tina4SetLocationStop(@AndroidStop);
  Tina4SetLocationRequest(@AndroidRequest);
  Tina4SetLocationBackgroundStart(@AndroidBackground);
end;

end.
