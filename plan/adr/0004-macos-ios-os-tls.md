# ADR-0004: macOS/iOS HTTP uses the OS TLS stack, not FPC's OpenSSL

- **Status:** Accepted
- **Date:** 2026-10-01 (retrofit)

## Context

FPC 3.2.2's OpenSSL binding does not initialise on Darwin/arm64 (any OpenSSL
version) — a request fails with "Could not initialize OpenSSL library". The
`Tina4Http` client is backend-pluggable precisely so TLS can come from the host.

## Decision

Select the HTTP backend per platform (the `Tina4Http` client API is identical on
all of them):

| Platform        | Unit               | Install            |
|-----------------|--------------------|--------------------|
| macOS           | `Tina4HttpCocoa`   | `InstallCocoaHttp` (NSURLSession) |
| Linux / Windows | `Tina4HttpFPC`     | `InstallFPCHttp` (fphttpclient + OpenSSL) |
| Android / iOS   | `Tina4HttpAndroid` / `Tina4HttpIOS` | installed by the shell |

## Consequences

- A headless/console program on macOS must use the Cocoa backend (`{$IFDEF DARWIN}`);
  `InstallFPCHttp` there will always fail to init TLS. See `examples/apirequest`.
- The Cocoa backend delivers on a background queue into `HttpDeliver`, drained by
  `HttpPump`, so it works without a GUI run loop.
- Undo this and macOS/iOS HTTPS silently stops working.
