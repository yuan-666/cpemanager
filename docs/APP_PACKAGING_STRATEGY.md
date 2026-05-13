# App Packaging Strategy

The project has two release tracks:

1. **Desktop fast track:** package the current Python client and Tkinter GUI for Windows and macOS with PyInstaller.
2. **Cross-platform product track:** build a Flutter/Dart app that reimplements the CPE HTTP client and targets Android, iOS, Windows, macOS, and HarmonyOS/OpenHarmony.

## Platform Matrix

| Platform | Recommended track | Build output | Notes |
| --- | --- | --- | --- |
| Windows | Python desktop now, Flutter later | `.exe` or installer | PyInstaller can package the current GUI quickly. Flutter gives the long-term shared UI. |
| macOS | Python desktop now, Flutter later | `.app`, `.dmg` later | Build/sign on macOS. Current repo can generate a PyInstaller `.app` from the Tkinter GUI. |
| Android | Flutter | `.apk` / `.aab` | Debug APK is locally verified. The app allows cleartext HTTP access to `192.168.8.1`. |
| iOS | Flutter | `.ipa` through Xcode/TestFlight | Needs full Xcode, CocoaPods, signing, and local-network/HTTP permissions. Native build is not verified on this machine yet. |
| HarmonyOS/OpenHarmony | Flutter for OpenHarmony | `.hap` / `.app` package | Use OpenHarmony-SIG `flutter_flutter`; not supported by upstream Flutter stable directly. |

Reference links:

- Flutter supported platforms: <https://docs.flutter.dev/reference/supported-platforms>
- PyInstaller operating mode: <https://pyinstaller.org/en/stable/operating-mode.html>
- OpenHarmony-SIG Flutter SDK: <https://gitee.com/openharmony-sig/flutter_flutter>

## Current Desktop Build

```bash
conda activate cpemanager
python -m pip install -e ".[desktop-build]"
python tools/build_desktop.py
```

Expected output:

- Windows: `dist/CPEManager.exe`
- macOS: `dist/CPEManager` one-file executable, or run `python tools/build_desktop.py --onedir` to get an app directory suited for `.app` style packaging.

The GUI entrypoint is:

```bash
cpemanager-desktop
```

## Flutter Product Track

This repo includes a Flutter source tree under `apps/flutter_cpemanager`. Native platform folders are generated for Android, iOS, macOS, Windows, and web. The app currently provides a dense mobile dashboard, Huawei/Fiberhome device selection, Dart CPE clients, status reads for Huawei, Fiberhome configuration calls from HAR, neighbor/lock-cell display, automatic network mode, Band/cell lock controls, and confirmation dialogs.

Verified local Android environment:

- Flutter `3.41.9`
- Dart `3.11.5`
- OpenJDK 17 at `/opt/homebrew/opt/openjdk@17`
- Android SDK at `/opt/homebrew/share/android-commandlinetools`
- Android SDK Platform 36
- Android SDK Build Tools 36.0.0
- Android NDK 28.2.13676358
- CMake 3.22.1

Common commands:

```bash
cd apps/flutter_cpemanager
flutter pub get
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter test
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter analyze
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --release
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build web
```

Verified Android output:

```text
apps/flutter_cpemanager/build/app/outputs/flutter-apk/app-debug.apk
apps/flutter_cpemanager/build/app/outputs/flutter-apk/app-release.apk
```

Release asset staging:

```bash
dist/release/v0.2.0/
```

The `v0.2.0` GitHub Release includes Android release/debug APKs, a macOS arm64 desktop `.app.zip`, a Web/PWA zip, the Python wheel, and `SHA256SUMS.txt`.

Current unreleased Flutter app version is `0.3.0+3`; local Android debug/release APKs have been rebuilt from this state, but a new GitHub Release has not yet been cut.

Install to a USB-connected Android phone with developer mode and USB debugging enabled:

```bash
adb install -r apps/flutter_cpemanager/build/app/outputs/flutter-apk/app-debug.apk
```

Future release builds:

```bash
flutter build apk
flutter build appbundle
flutter build ios --no-codesign
flutter build windows
flutter build macos
flutter build web
```

iOS/macOS native Flutter builds are blocked on installing full Xcode and CocoaPods on this Mac. Windows builds must be produced on Windows.

For HarmonyOS/OpenHarmony, install the OpenHarmony-SIG Flutter SDK and matching OpenHarmony/HarmonyOS SDK, then create/build the OHOS platform target with that SDK. Keep the Dart client in `lib/api/cpe_client.dart` platform-neutral.

## Multi-Platform Client Boundary

The Python client remains the reference implementation:

- `src/cpemanager/client.py`
- `src/cpemanager/endpoints.py`
- `docs/API_REFERENCE.md`

The Flutter client should mirror these methods:

- `login`
- `deviceSignal`
- `monitoringStatus`
- `trafficStatistics`
- `currentPlmn`
- `secondaryCells`
- `neighborCells`
- `setNetMode`
- `lockFreq`
- `unlockAll`
- `antennaType`
- `setAntennaType`

Before mobile releases, add recorded XML fixtures for every supported endpoint and run the same parser tests in Python and Dart.

Fiberhome/烽火 is a separate adapter because the captured device uses JSON `FHTOOLAPIS` methods rather than Huawei XML endpoints. Do not commit raw HAR files; they can contain live `sessionid` values.
