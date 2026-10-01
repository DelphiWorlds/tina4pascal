# API request — Tina4Pascal HTTP client

The smallest possible example of calling a REST API with the `Tina4Http` client:
one `GET` and one JSON `POST`, printed to the console. No UI, no engine — copy
this shape into any app that needs to talk to an API.

## Run

```sh
cd examples/apirequest
fpc -Mdelphi -Fu../../src main.pas && ./main
```

(Needs internet — it hits `httpbin.org`.) Expected output: both requests return
`status: 200`, and the POST echoes back the JSON body you sent.

## The API

Requests are **asynchronous**: `HttpGet`/`HttpPost` return a request id immediately
and your callback runs later, on whichever thread calls `HttpPump`.

```pascal
InstallCocoaHttp;            // once at startup — pick a TLS backend (see below)

HttpGet('https://api.example.com/rolls/R-1007', @OnReply);
HttpPost('https://api.example.com/cuts', '{"roll":"R-1007","m":12.5}',
         'application/json', @OnReply);

while HttpPending > 0 do begin HttpPump; Sleep(20); end;   // a GUI app pumps per frame
```

Every reply is a `TTina4HttpResponse`: `Status`, `Body`, `ContentType`, `Error`,
and `Ok` (2xx and no transport error). Use `HttpRequest(Method, Url, Body, …)` for
verbs other than GET/POST, and `HttpSetHeader`/`HttpGetEx` for custom headers.

## TLS backend per platform

The client API above is identical everywhere; only the one-line install differs:

| Platform        | Unit               | Install            |
|-----------------|--------------------|--------------------|
| macOS           | `Tina4HttpCocoa`   | `InstallCocoaHttp` |
| Linux / Windows | `Tina4HttpFPC`     | `InstallFPCHttp`   |
| Android / iOS   | `Tina4HttpAndroid` / `Tina4HttpIOS` | installed by the shell |

macOS uses the OS TLS stack because FPC 3.2.2's OpenSSL binding does not
initialise on Darwin/arm64. `main.pas` picks the right one with `{$IFDEF DARWIN}`.
