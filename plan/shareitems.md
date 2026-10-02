# ShareItems

## Purpose

`Tina4ShareItems` provides a small, platform-neutral contract for presenting
the native share sheet. An application can compose text, local files, and local
image files without depending on Android or Apple UI types. The platform
adapter owns the native chooser and reports the result through the shared
capability status contract.

This is currently implemented for Android and iOS. The desktop adapter is an
explicit unsupported placeholder until a desktop window/share API is defined.

## Public API

Include `Tina4ShareItems` and `Tina4Capabilities`:

```pascal
var
  Items: TTina4ShareItems;
  Status: TTina4CapabilityStatus;
begin
  Items := TTina4ShareItems.Create;
  try
    Items.AddText('Daily report');
    Items.AddFile('/path/to/report.pdf');
    Items.AddImageFile('/path/to/chart.png');

    Status := Items.Share;
    if Status <> tcsStarted then
      // Handle Tina4CapabilityStatusName(Status) as appropriate.
  finally
    Items.Free;
  end;
end;
```

The available operations are:

- `AddText(Text)` adds a text item.
- `AddFile(FileName)` adds an existing local file.
- `AddImageFile(FileName)` adds an existing local image file.
- `Clear` removes all items.
- `Count` returns the number of items.
- `Item(Index)` reads an item by zero-based index.
- `Share(Anchor)` presents the native share UI. `Anchor` is optional and is
  reserved for a platform-specific presentation anchor.

`Share` returns `tcsInvalidArgument` when the collection is empty, an item has
an empty value, or a file path does not exist. It returns `tcsUnsupported` when
no platform adapter is installed. A native adapter normally returns
`tcsStarted`; the final result is delivered asynchronously.

## Completion handling

Install the process-wide completion handler if the application needs to know
whether the user completed or cancelled the share operation:

```pascal
procedure ShareFinished(Status: TTina4CapabilityStatus;
  const Activity, Error: string);
begin
  // Use Status, Activity, and Error to update the application UI.
end;

initialization
  Tina4SetShareCompletedHandler(@ShareFinished);
```

The callback receives the shared status, the native activity/action name when
available, and an error description when the operation fails. The handler is
global to the process, so an application should register one coordinated
handler rather than one handler per share collection.

## Platform support

| Platform | Current implementation | Supported items | Notes |
| --- | --- | --- | --- |
| Android | Native `ACTION_SEND` / `ACTION_SEND_MULTIPLE` chooser with Tina4 content provider | Text, files, images, mixed collections | File URIs are exposed through the private provider; the source files must exist before calling `Share`. |
| iOS | Native `UIActivityViewController` | Text, files, images, mixed collections | The host presents the controller from the active view/window context. |
| Windows | Explicit unsupported adapter | None yet | A future adapter can use `DataTransferManager` when a real application window is available. |
| macOS/Linux desktop | Explicit unsupported adapter | None yet | A desktop share/window contract is still required. |

## Integration notes

The shared unit is deliberately independent of native UI frameworks. A Tina4
host must include the target platform adapter and its native bridge when
building an application. Applications should pass stable, readable local file
paths and retain the files until the share operation has completed.

The implementation is in
[`src/Tina4ShareItems.pas`](../src/Tina4ShareItems.pas), with platform adapters
in `src/Tina4ShareItemsAndroid.pas`, `src/Tina4ShareItemsIOS.pas`, and
`src/Tina4ShareItemsDesktop.pas`.

