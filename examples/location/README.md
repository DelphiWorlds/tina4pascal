# Location demo

Foreground location support using the shared `Tina4Location` contract.

On iOS, build the project with the normal iOS project command, select a signed
device, and tap **Request permission** followed by **Start updates**. The app
uses `CLLocationManager` and includes the foreground usage description.

The macOS Cocoa host also installs a Core Location adapter. macOS permission is
controlled by System Settings → Privacy & Security → Location Services.

Background updates, geofencing, and Windows location are intentionally not part
of this first foreground milestone.
