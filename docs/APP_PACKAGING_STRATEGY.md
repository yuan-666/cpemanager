# App Packaging Strategy

The project has two release tracks:

1. **Desktop fast track:** package the current Python client and Tkinter GUI for Windows and macOS with PyInstaller.
2. **Cross-platform product track:** build a Flutter/Dart app that reimplements the CPE HTTP client and targets Android, iOS, Windows, macOS, and HarmonyOS/OpenHarmony.

## Platform Matrix

| Platform | Recommended track | Build output | Notes |
| --- | --- | --- | --- |
| Windows | Python desktop now, Flutter later | `.exe` or installer | PyInstaller can package the current GUI quickly. Flutter gives the long-term shared UI. |
| macOS | Python desktop now, Flutter later | `.app`, `.dmg` later | Build/sign on macOS. Current repo can generate a PyInstaller `.app` from the Tkinter GUI. |
| Android | Flutter | `.apk` / `.aab` | Needs Android SDK. The app must allow HTTP access to `192.168.8.1`. |
| iOS | Flutter | `.ipa` through Xcode/TestFlight | Needs macOS, Xcode, signing, and local-network/HTTP permissions. |
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

This repo includes a starter Flutter source tree under `apps/flutter_cpemanager`. Because Flutter is not installed in this machine right now, the generated platform folders are intentionally not committed yet.

After installing Flutter:

```bash
cd apps/flutter_cpemanager
flutter create --platforms=android,ios,windows,macos .
flutter pub get
flutter run -d macos
```

Release builds:

```bash
flutter build apk
flutter build appbundle
flutter build ios
flutter build windows
flutter build macos
```

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
