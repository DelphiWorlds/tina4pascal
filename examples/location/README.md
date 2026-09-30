# Location demo

Foreground and opt-in background location support using the shared `Tina4Location` contract.

On iOS, build the project with the normal iOS project command, select a signed
device, and tap **Request permission** followed by **Start updates**. The app
uses `CLLocationManager` and includes foreground and Always usage descriptions.
For background testing, tap **Start background updates** and accept the upgrade
to Always permission, then lock or background the device while it moves.

The macOS Cocoa host also installs a Core Location adapter. macOS permission is
controlled by System Settings → Privacy & Security → Location Services.

Geofencing and Windows location are not part of this milestone.

On Android, the initial adapter uses the platform `LocationManager` and requests
coarse or fine runtime permission without requiring Google Play Services. Build
with the Android SDK configured, install the generated APK, then use the same
Request permission and Start updates controls. Android background updates will
be added as a foreground-service milestone.
