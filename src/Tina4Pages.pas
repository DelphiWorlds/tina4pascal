unit Tina4Pages;

{ Embedded page store — static HTML pages compiled INTO the binary, so an app can
  ship as a single executable with no assets folder and no files to resolve on
  device. A generated unit (see `tina4pascal pages`) calls RegisterEmbeddedPage
  once per page in its initialization; the renderer's <include src>/view.load
  resolver checks this store BEFORE touching disk, so the same
  `view.load('stage','views/stats.html')` works whether the page is a bundled
  file or welded into the binary. Names are matched by their relative path.

  This unit is part of core and always links; the store is simply empty until an
  app registers pages, so nothing changes for apps that don't use it. }

{$mode delphi}{$H+}

interface

{ Store HTML under a page name (a relative path like 'views/stats.html'). A later
  call with the same name replaces it. Safe to call before any renderer init. }
procedure RegisterEmbeddedPage(const Name, Html: string);
{ As RegisterEmbeddedPage, but the HTML is base64 — what the `tina4pascal pages`
  generator emits, so no page content has to be escaped into Pascal string
  literals. Invalid base64 registers an empty page rather than raising. }
procedure RegisterEmbeddedPageB64(const Name, B64: string);
{ Fetch a previously registered page. False (and Html='') when none is stored. }
function TryGetEmbeddedPage(const Name: string; out Html: string): Boolean;
{ How many pages are embedded (0 when the app registered none). }
function EmbeddedPageCount: Integer;
{ Forget every embedded page (mainly for tests). }
procedure ClearEmbeddedPages;

implementation

uses SysUtils, Generics.Collections, base64;

var
  GPages: TDictionary<string, string> = nil;

{ Normalise a page name so a disk-style src and a registered name match: back- to
  forward-slashes and a leading './' dropped. Case is kept (asset paths are). }
function NormName(const N: string): string;
begin
  Result := StringReplace(Trim(N), '\', '/', [rfReplaceAll]);
  if (Length(Result) >= 2) and (Result[1] = '.') and (Result[2] = '/') then
    Delete(Result, 1, 2);
end;

procedure RegisterEmbeddedPage(const Name, Html: string);
begin
  if GPages = nil then GPages := TDictionary<string, string>.Create;
  GPages.AddOrSetValue(NormName(Name), Html);
end;

procedure RegisterEmbeddedPageB64(const Name, B64: string);
var html: string;
begin
  try html := DecodeStringBase64(B64); except html := ''; end;
  RegisterEmbeddedPage(Name, html);
end;

function TryGetEmbeddedPage(const Name: string; out Html: string): Boolean;
begin
  Html := '';
  Result := (GPages <> nil) and GPages.TryGetValue(NormName(Name), Html);
end;

function EmbeddedPageCount: Integer;
begin
  if GPages = nil then Result := 0 else Result := GPages.Count;
end;

procedure ClearEmbeddedPages;
begin
  if GPages <> nil then GPages.Clear;
end;

finalization
  GPages.Free;

end.
