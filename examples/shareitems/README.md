# Tina4 ShareItems demo

This project exercises the cross-platform `Tina4ShareItems` contract:

- share text
- share a generated text file
- share a generated image file
- share a mixed text + file + image payload
- clear the queued item list

Desktop compile:

```sh
../../tools/tina4pascal build macos
```

Android packaging uses the SDK and FPC cross tools configured for the repository:

```sh
PATH=/Users/dave/fpc/cross/bin/aarch64-android:/Users/dave/fpc/bin:$PATH \
TINA4_HOME=/path/to/tina4pascal/.tina4 \
ANDROID_SDK=/Users/dave/Library/Android/sdk \
../../tools/tina4pascal build android
```

Install the resulting `build/android/ShareItems Demo.apk` on a device or emulator,
tap a share action, and confirm Android opens its native chooser. The generated
file/image payloads are written to the app's temporary directory before sharing.
