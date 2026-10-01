program main;

{ Tina4Pascal HTTP client — a minimal API request example.

  No UI and no engine: just the Tina4Http client making a GET and a POST and
  printing the replies. This is the shape to copy into any app that needs to call
  a REST API.

  Requests are ASYNCHRONOUS: HttpGet/HttpPost return immediately with a request
  id, and your callback runs later — on the thread that calls HttpPump. A GUI app
  pumps once per frame; this console example loops HttpPump until the replies land.

  Build + run (needs internet; hits httpbin.org):
    cd examples/apirequest
    fpc -Mdelphi -Fu../../src main.pas && ./main

  TLS backend per platform (the client API below is identical on all of them):
    macOS  → Tina4HttpCocoa + InstallCocoaHttp   (NSURLSession — OS TLS)
    Linux/ → Tina4HttpFPC   + InstallFPCHttp      (fphttpclient over OpenSSL)
    Windows                                       FPC's OpenSSL binding does not
    mobile → Tina4HttpAndroid / Tina4HttpIOS      init on macOS, hence Cocoa there. }

{$mode delphi}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}   // the HTTP backend fetches on a worker thread
  SysUtils,
  Tina4Http,       // HttpGet / HttpPost / HttpPump + TTina4HttpResponse
  {$IFDEF DARWIN}
  Tina4HttpCocoa;  // InstallCocoaHttp — OS TLS (FPC's OpenSSL binding can't init on macOS)
  {$ELSE}
  Tina4HttpFPC;    // InstallFPCHttp — fphttpclient over OpenSSL (Linux/Windows)
  {$ENDIF}

var
  Done: Integer = 0;               // replies delivered so far
  Expect: Integer = 2;             // GET + POST

{ One handler for both calls — TTina4HttpResponse carries everything you need. }
procedure OnReply(const R: TTina4HttpResponse);
begin
  WriteLn('--- ', R.Url);
  if not R.Ok then
    WriteLn('  FAILED  status=', R.Status, '  error=', R.Error)
  else
  begin
    WriteLn('  status      : ', R.Status);
    WriteLn('  content-type: ', R.ContentType);
    WriteLn('  body        : ', Copy(R.Body, 1, 240));
    if Length(R.Body) > 240 then WriteLn('                … (', Length(R.Body), ' bytes total)');
  end;
  Inc(Done);
end;

var spins: Integer;
begin
  {$IFDEF DARWIN}InstallCocoaHttp;{$ELSE}InstallFPCHttp;{$ENDIF}   // one-time: pick the TLS backend

  // GET: fetch a resource.
  HttpGet('https://httpbin.org/get', @OnReply);

  // POST: send a JSON body (e.g. look up / record a roll).
  HttpPost('https://httpbin.org/post',
           '{"roll_ref":"R-1007","metres":12.5}',
           'application/json',
           @OnReply);

  // Deliver the async replies. HttpPump runs each ready callback and returns how
  // many it delivered; a UI app would call it on its tick instead of looping.
  spins := 0;
  while (Done < Expect) and (spins < 500) do   // ~10s safety cap
  begin
    HttpPump;
    Sleep(20);
    Inc(spins);
  end;

  if Done < Expect then
    WriteLn('timed out waiting for ', Expect - Done, ' reply(ies)');
end.
