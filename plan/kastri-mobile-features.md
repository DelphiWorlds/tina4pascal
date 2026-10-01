# Task: Kastri mobile feature migration assessment

**Branch:** `kastri`

**Outcome:** Define the work required to migrate Kastri-equivalent AdMob,
Location, and ShareItems capabilities into Tina4Pascal for iOS and Android,
with Windows implementations where the platform supports them and explicit
no-op/diagnostic fallbacks elsewhere.

## Current evidence and boundary

- The requested local `Kastri/` folder is not present in this checkout. There
  is no tracked `Kastri` path, no `API/` bridge source, and no related Git
  history. Exact Kastri unit names and signatures therefore still need to be
  checked in when that source is added.
- Upstream Kastri separates low-level API imports from higher-level `Features`
  units. Its API imports are Delphi bindings and cannot be reused directly by
  Free Pascal; Tina4Pascal must expose only the needed native contracts and
  implement them through JNI, Objective-C/C, or Windows APIs.
- Tina4Pascal already has the right integration seam: the shared Pascal engine
  is platform-neutral, while Android (`android/jni/tina4jni.pas` + Java host)
  and iOS (`ios/tina4ios.pas` + Objective-C host) own permissions, native views,
  lifecycle, and callbacks. Project `appUnits` are already staged into both
  mobile builds.
- The current Android packager is deliberately dependency-light and can consume
  local JARs, but it has no generic AAR/Maven dependency/configuration path.
  The iOS project links system frameworks but has no third-party XCFramework
  staging/configuration path.

## Recommended architecture

Create small public Pascal units with stable, asynchronous contracts:

| Unit | Shared contract | Android adapter | iOS adapter | Windows / other |
|---|---|---|---|---|
| `Tina4AdMob` | configure app/ad IDs, consent, banner/interstitial/rewarded load/show, status/error callbacks | Java wrapper over Google Mobile Ads + UMP; Activity/View overlay | Objective-C/Swift wrapper over GoogleMobileAds + UMP; UIView overlay/presenting VC | Explicit unsupported result and diagnostic; no fake ad surface |
| `Tina4Location` | permission state, start/stop updates, one-shot location, background mode, location/error callbacks | Java `LocationManager` or Fused Location Provider wrapper; permission and foreground service owned by Activity | `CLLocationManager` delegate; authorization and background lifecycle owned by host | WinRT `Geolocator` adapter where practical; otherwise unsupported result |
| `Tina4ShareItems` | add text/image/file, clear, share, completion/cancel/error | `ACTION_SEND` / `ACTION_SEND_MULTIPLE` chooser with `FileProvider` URIs | `UIActivityViewController` with excluded activity mapping | Windows `DataTransferManager` where a real app window is available; otherwise shell/file fallback or unsupported result |

The shared units should not call JNI, UIKit, Google SDKs, or shell commands.
They should return a deterministic `Tina4CapabilityStatus` (supported,
unsupported, permission denied, unavailable, failed) and marshal all callbacks
back to the UI/main thread. A no-op adapter is preferable to silently claiming
success.

## Feature assessment

### AdMob — highest integration cost

Kastri's AdMob surface includes banner and full-screen formats, asynchronous
preloading/showing, and User Messaging Platform consent. It is not a simple API
import. The equivalent requires:

1. A native dependency strategy. Android needs the Google Mobile Ads and UMP
   artifacts, manifest metadata, `INTERNET` and `ACCESS_NETWORK_STATE`, and an
   application/activity context. iOS needs GoogleMobileAds/UMP frameworks (or
   XCFrameworks), linker flags, Swift runtime handling, and the minimum OS
   version supported by the selected SDK.
2. A project configuration surface for app ID, ad unit IDs, test-device IDs,
   consent/debug geography, and whether the app opts into ATT. Secrets must not
   be embedded in the shared Pascal unit.
3. A native view/presentation route. Banners must be inserted into the existing
   Android `FrameLayout` / iOS `Tina4View` hierarchy and positioned from a
   layout rectangle or exposed as an explicit host-controlled banner slot.
   Interstitial/rewarded/app-open ads must be presented by the foreground
   Activity/ViewController, never from a worker thread.
4. Event/error callbacks for load, impression, click, dismissal, reward, and
   consent failure. The callbacks need stable IDs so a project can correlate
   multiple ads without relying on object pointers.
5. Test and policy gates: Google test IDs only in test builds, no real-ad clicks
   during testing, consent before a request where required, and device tests on
   both an emulator/simulator-safe path and real hardware.

**Recommendation:** implement AdMob after the other two features, behind an
optional dependency profile. Keep the first milestone to banner + interstitial
and consent/status callbacks; add rewarded formats only after the lifecycle and
SDK packaging path is proven.

### Location — medium/high cost, especially for background updates

The foreground one-shot/update path is feasible without changing the renderer.
Background operation is a separate product capability and must be explicit:

- Android: declare coarse/fine permissions; request runtime permission; request
  background permission separately when needed; decide whether the implementation
  uses platform `LocationManager` (no Google dependency) or the Google fused
  provider; use a foreground service and notification for long-running updates;
  handle disabled providers, approximate location, revocation, and process death.
- iOS: add `NSLocationWhenInUseUsageDescription` and, only for the chosen
  background mode, `NSLocationAlwaysAndWhenInUseUsageDescription` plus the
  `location` background mode; retain a `CLLocationManager` delegate; handle
  authorization transitions, reduced accuracy, unavailable/errors, and deferred
  updates.
- Windows: a WinRT `Geolocator` adapter is possible but needs COM/WinRT bindings
  and a desktop-window lifecycle. It should be a later adapter, not a reason to
  contaminate the shared unit with Windows-only types.

**Recommendation:** first ship foreground `GetCurrent` and continuous updates
with explicit permission callbacks. Treat background updates/geofencing as a
second milestone with a separate privacy/lifecycle test matrix.

### ShareItems — lowest cost and best first implementation

The existing `Tina4LinkOpen` and clipboard hooks are useful but are not a
multi-item share contract. The equivalent needs a temporary/content URI policy
and completion handling:

- Android: share text, images, and files through `ACTION_SEND` or
  `ACTION_SEND_MULTIPLE`; add a `FileProvider` with a narrow cache/files-path;
  grant read URI permissions; preserve MIME types; use a chooser; report
  cancelled/no-handler/failure. Avoid `file://` URIs and broad storage
  permissions.
- iOS: create `UIActivityViewController` on the main thread, map excluded
  activities, provide a popover source/anchor on iPad, and translate completion
  activity/error/cancel into the shared result.
- Windows: use `DataTransferManager` for an actual Win32/UWP-compatible host if
  the required bridge is available. Until then, support text via the existing
  clipboard hook and return `unsupported` for file/image share rather than
  pretending that `ShellExecute` is a share sheet.

**Recommendation:** implement this first. It exercises the reusable native
request/completion bridge without introducing a third-party SDK.

## Tina4Pascal changes required

### Shared Pascal layer

- Add a small capability/result vocabulary and callback registration in a new
  unit (or a narrowly scoped extension of the existing hook pattern).
- Add `Tina4ShareItems` first, then `Tina4Location`; keep `Tina4AdMob` in an
  optional unit so desktop builds do not link ad SDK symbols.
- Use opaque request IDs and copied strings/records at the boundary. Never pass
  Pascal managed strings, dynamic arrays, or object references directly through
  C/JNI callbacks.
- Define cancellation, permission denial, provider unavailable, user cancel,
  and unsupported-platform behavior before implementation.

### Android host/build

- Add Java bridge classes and native entry points following the existing
  `Tina4Notify`/`Tina4Scanner` pattern.
- Add a host callback/overlay manager to the existing `FrameLayout`; avoid
  changing the renderer's paint path for native views.
- Extend project generation/packaging so per-project permissions, manifest
  metadata, `FileProvider`, assets, and optional AdMob dependencies are declared
  from `tina4.json` rather than hard-coded in the reference app.
- Decide whether to keep the current no-Maven packager (requiring vendored,
  reproducibly pinned artifacts) or add an explicit Gradle/AAR profile. AdMob
  should not be silently downloaded during a normal build.

### iOS host/build

- Add C ABI declarations to `ios/app/tina4.h` and implementations in a small
  Objective-C/Swift bridge, with all UIKit/CoreLocation/share/ad calls on the
  main queue.
- Extend the generated Xcode spec/Info.plist staging for usage descriptions,
  background modes, URL/content handling, optional frameworks, and AdMob
  XCFramework search/linker settings.
- Keep the simulator build honest: Location and ShareItems can have limited
  simulator tests; AdMob should expose a clean unavailable/test result if its
  SDK is not linked into the simulator profile.

### Windows

- Add compile-time no-op capability adapters first, returning `unsupported` and
  logging the requested operation.
- Add real ShareItems only after the desktop host's window/COM bridge is defined;
  add Location only after WinRT binding and permission behavior are verified.
- Do not add Windows AdMob code unless a supported desktop ad SDK is selected;
  the correct initial equivalent is a documented placeholder.

## Implementation order

1. [x] Create the `kastri` branch and inventory Tina4Pascal mobile seams.
2. [x] Record the absence of the local Kastri/API source and the resulting
   port-mapping limitation.
3. [x] Add a shared capability/result contract and unsupported adapters.
4. [x] Implement ShareItems on Android and iOS; add Windows placeholder;
   verify cancel, no-handler, URI/path, and multi-item cases.
5. [ ] Implement foreground Location on Android and iOS; add Windows
   placeholder; verify permission denial, provider disabled, update, and stop.
6. [ ] Add background Location/geofencing only after an explicit privacy and
   lifecycle decision.
7. [ ] Establish optional mobile SDK packaging, then implement AdMob banner and
   interstitial/consent; add reward formats later.
8. [ ] Re-read the exact Kastri sources when supplied and map each public
   feature/API to the Tina4 contract without importing Delphi-only bindings.
9. [ ] Run portable tests plus real Android/iOS device or emulator tests; do not
   mark native work complete from compilation alone.

## Parity

| Capability | iOS | Android | Windows | Status |
|---|---|---|---|---|
| AdMob | planned native SDK bridge | planned Google SDK bridge | documented placeholder | Assessment |
| Location foreground | planned Core Location bridge | planned platform provider bridge | planned placeholder/WinRT later | Assessment |
| Location background | separate milestone | separate milestone/foreground service | placeholder | Assessment |
| ShareItems | ✅ activity controller bridge | ✅ chooser + private content provider | ✅ explicit unsupported adapter | Implemented; iOS archive/syntax verified |
| Location foreground | ✅ Core Location bridge | ❌ | ❌ | iOS + macOS adapter implemented; Android/Windows remain |

## Tests (to be written before implementation)

- [x] Shared contract: unsupported adapter never reports success; cancellation and
  permission denial are distinct; callbacks are delivered once.
- [x] ShareItems: text, one file, image, multiple mixed items, invalid path, no
  handler, user cancellation, and MIME propagation.
- [x] Portable contract test: `tests/test_share_items.pas` — 7 assertions pass.
- [x] iOS Pascal archive and Objective-C bridge syntax check; the presenter uses
  foreground `UIWindowScene` discovery for iOS 13+.
- [x] Android APK/device smoke test — the ShareItems demo APK packages,
  installs beside the reference app, opens Android's native chooser, and
  stages file payloads through the private provider.
- Location: permission denied, provider disabled, one-shot success, update
  delivery, stop/cancel, malformed/native error callback, and process/lifecycle
  teardown.
- [x] Portable Location contract test — 6 assertions pass; iOS/macOS native
  adapters compile and the Location demo is staged for project builds.
- AdMob: missing configuration, test configuration, consent denied, load error,
  successful banner/interstitial callback sequence, dismissal, and reward.
- Native verification: Android APK packaging/manifest and iOS Xcode link/staged
  plist checks; real-device smoke tests for every supported operation.

## Bugs / blockers

- [x] Exact Kastri `API`, `Core`, `Features/AdMob`, `Features/Location`, and
  `Features/ShareItems` sources were located in the sibling checkout
  `/Users/Shared/Projects/Kastri`; they are used as the reference, not copied
  wholesale into the Free Pascal tree.
- [x] Android assembler wrapper was present but missing from the build script's
  `PATH`; `android/build.sh` now discovers the standard FPC cross-bin directory
  and successfully builds `libtina4.so` with the supplied SDK/NDK.
- [x] Android APK packaging/device verification uses the supplied ignored
  `android/libs/zxing-core-3.5.3.jar`; the project build cache is local-only.
- [x] Project APK provider authority is bundle-specific, so multiple Tina4
  apps can be installed on the same Android device without provider collisions.
- [x] iOS project-level Xcode build now passes unsigned for the ShareItems demo
  after installing `xcodegen` and disabling Xcode 27 chained fixups for the FPC
  static archive.
- [x] iOS Simulator toolchain/runtime provisioned; the native arm64 simulator
  engine and `ios/sim` Xcode host now compile and link successfully.
- [x] Wire the ShareItems demo/actions into a dedicated simulator host; the
  generated app now uses the shared iOS activity-controller bridge.
- [x] Build/install the dedicated simulator app on an iPhone 16 Pro simulator;
  the ShareItems UI renders successfully. Interactive chooser selection remains
  a manual tap check because the command-line harness has no touch injection.
- [ ] Existing unrelated suite failures remain in `test_crypto`, `test_authflow`,
  `test_secrets`, and `test_ssoflow`; `test_share_items` is green.

## Commits

- (working tree) `feat: add capability contract and ShareItems adapters`
- (working tree) `test: add ShareItems integration demo`
- (working tree) `fix: use scene-aware iOS ShareItems presenter`
- (working tree) `feat: add foreground Location contract and Apple adapters`

## Status: ShareItems implementation complete; iOS unsigned project build verified

## References

- [Kastri upstream overview and feature structure](https://github.com/DelphiWorlds/Kastri)
- [Kastri AdMob demo and SDK/configuration notes](https://github.com/DelphiWorlds/Kastri/blob/master/Demos/AdMob/ReadMe.md)
- [Kastri ShareItems usage summary](https://github.com/emozgun/delphi-ios-file-storage-sharing)
