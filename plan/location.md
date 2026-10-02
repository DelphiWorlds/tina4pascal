# Location

## Purpose

`Tina4Location` provides a shared contract for requesting permission, starting
and stopping continuous location updates, and receiving portable location
records. Native adapters own permission prompts, provider selection, lifecycle
handling, and background-service details.

The current implementation covers foreground location on iOS, macOS, and
Android. Opt-in background updates are implemented on iOS and Android.
Windows remains an unsupported placeholder.

## Public API

Register a callback before requesting or starting updates:

```pascal
procedure LocationChanged(Status: TTina4CapabilityStatus;
  const Location: TTina4Location; const Error: string);
begin
  if Status = tcsSuccess then
    // Location.Latitude, Longitude, Accuracy, Altitude, Speed, and Timestamp
  else
    // Handle Error and Status.
end;

initialization
  Tina4SetLocationCallback(@LocationChanged);
```

The application then controls the location lifecycle:

```pascal
Tina4LocationRequest;          // Ask the platform for location permission.
Tina4LocationStart;            // Begin foreground updates.
Tina4LocationStop;             // Stop updates.
Tina4LocationStartBackground;  // Begin the platform's background mode.
```

There is no synchronous “get current location” function. Location values are
delivered asynchronously through `TTina4LocationCallback`:

| Field | Meaning |
| --- | --- |
| `Latitude`, `Longitude` | Coordinates in decimal degrees. |
| `Accuracy` | Horizontal accuracy in metres, when supplied by the platform. |
| `Altitude` | Altitude in metres, when supplied by the platform. |
| `Speed` | Speed in metres per second, when supplied by the platform. |
| `Timestamp` | Platform timestamp represented as a `Double`. |

Each lifecycle call returns a `TTina4CapabilityStatus`. The most useful values
are `tcsStarted`, `tcsSuccess`, `tcsPermissionDenied`, `tcsUnavailable`,
`tcsCancelled`, `tcsFailed`, and `tcsUnsupported`. Permission and provider
errors are also delivered to the callback with a descriptive `Error` string.

## Platform support

| Platform | Foreground | Background | Native implementation |
| --- | --- | --- | --- |
| iOS | Supported | Supported, opt-in | Core Location; background mode requires the appropriate Always permission and app background mode. |
| macOS | Supported | Not implemented | Core Location through the macOS host. |
| Android | Supported | Supported, opt-in | Platform `LocationManager`; background mode uses a foreground service with a persistent notification. Google Play Services is not required. |
| Windows | Placeholder | Placeholder | Returns `tcsUnsupported` until a WinRT `Geolocator` adapter is added. |

## Permissions and host configuration

### iOS

The app must provide `NSLocationWhenInUseUsageDescription`. Background use
also requires `NSLocationAlwaysAndWhenInUseUsageDescription` and the `location`
entry in `UIBackgroundModes`. The application should request permission first,
then call `Tina4LocationStartBackground` only when background tracking is
required.

### macOS

The user controls access under **System Settings → Privacy & Security →
Location Services**. The host must be a location-enabled macOS application;
the shared contract cannot add the app to the system location list by itself.

### Android

The host manifest includes coarse/fine location permissions and the foreground
service location declarations. Android runtime permission must be granted by
the user. Background mode is started from the foreground application and shows
a persistent low-priority notification; the user may also need to grant
notification permission on newer Android versions.

## Testing guidance

The example application is in
[`examples/location`](../examples/location/README.md). A practical test flow
is:

1. Build and install the example for the target platform.
2. Tap **Request permission** and complete the platform prompt.
3. Tap **Start updates** and verify that callback records are appended to the
   output.
4. Change the simulator/device location or move the device to produce another
   update.
5. For background testing, tap **Start background updates**, background or
   lock the app, and confirm that the platform continues to deliver updates
   according to its power and permission policy.

Location updates are asynchronous and may be delayed by the operating system,
provider availability, simulator settings, or the device's power policy. A
transient “location unknown”/cancelled callback should not automatically be
treated as permanent permission failure; the application should inspect the
status and continue or retry according to its UX policy.

The shared contract is in
[`src/Tina4Location.pas`](../src/Tina4Location.pas). Platform adapters are in
`src/Tina4LocationIOS.pas`, `src/Tina4LocationMacOS.pas`, and
`src/Tina4LocationAndroid.pas`.

