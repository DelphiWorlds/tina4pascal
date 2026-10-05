unit Tina4ShareItemsAndroid;

{$mode delphi}{$H+}

interface

uses jni;

procedure InstallAndroidShareItems(VM: PJavaVM);

implementation

uses SysUtils, Tina4ShareItems, Tina4Capabilities;

var GVM: PJavaVM = nil;

function CurrentEnv: PJNIEnv;
var R: jint;
begin
  Result := nil;
  if GVM = nil then Exit;
  R := GVM^^.GetEnv(GVM, @Result, JNI_VERSION_1_6);
  if (R <> JNI_OK) and (GVM^^.AttachCurrentThread(GVM, @Result, nil) <> JNI_OK) then
    Result := nil;
end;

function JString(Env: PJNIEnv; const S: string): jstring;
begin
  Result := Env^.NewStringUTF(Env, PAnsiChar(AnsiString(S)));
end;

function AndroidShare(const Items: TTina4ShareItemArray;
  const Anchor: string): TTina4CapabilityStatus;
var
  Env: PJNIEnv; Cls, StrCls: jclass; Mid: jmethodID;
  Kinds, Values, Mimes: jobjectArray; A: array[0..2] of jvalue;
  I: Integer; K, M: string; V, JK, JM: jstring;
begin
  Result := tcsUnavailable;
  Env := CurrentEnv;
  if Env = nil then Exit;
  Cls := Env^.FindClass(Env, 'com/tina4/pascal/Tina4Share');
  if Cls = nil then Exit;
  StrCls := Env^.FindClass(Env, 'java/lang/String');
  if StrCls = nil then Exit;
  Mid := Env^.GetStaticMethodID(Env, Cls, 'share',
    '([Ljava/lang/String;[Ljava/lang/String;[Ljava/lang/String;)V');
  if Mid = nil then Exit;
  Kinds := Env^.NewObjectArray(Env, Length(Items), StrCls, nil);
  Values := Env^.NewObjectArray(Env, Length(Items), StrCls, nil);
  Mimes := Env^.NewObjectArray(Env, Length(Items), StrCls, nil);
  for I := 0 to Length(Items) - 1 do
  begin
    case Items[I].Kind of
      tsikText: begin K := 'text'; M := 'text/plain'; end;
      tsikFile: begin K := 'file'; M := '*/*'; end;
      tsikImage: begin K := 'image'; M := 'image/*'; end;
    end;
    V := JString(Env, Items[I].Value);
    JK := JString(Env, K); JM := JString(Env, M);
    Env^.SetObjectArrayElement(Env, Kinds, I, JK);
    Env^.SetObjectArrayElement(Env, Values, I, V);
    Env^.SetObjectArrayElement(Env, Mimes, I, JM);
    Env^.DeleteLocalRef(Env, V); Env^.DeleteLocalRef(Env, JK); Env^.DeleteLocalRef(Env, JM);
  end;
  A[0].l := Kinds; A[1].l := Values; A[2].l := Mimes;
  Env^.CallStaticVoidMethodA(Env, Cls, Mid, @A[0]);
  Env^.DeleteLocalRef(Env, Kinds); Env^.DeleteLocalRef(Env, Values); Env^.DeleteLocalRef(Env, Mimes);
  Result := tcsStarted;
end;

procedure InstallAndroidShareItems(VM: PJavaVM);
begin
  GVM := VM;
  Tina4SetSharePlatform(@AndroidShare);
end;

end.
