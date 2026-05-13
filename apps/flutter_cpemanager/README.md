# Flutter CPE Manager

This is the long-term cross-platform app track for Android, iOS, Windows, macOS, web, and HarmonyOS/OpenHarmony.

Current state:

- Android, iOS, macOS, Windows, and web platform folders are generated.
- Android debug and release APKs build successfully on the current Mac.
- App version is `0.3.2+5`.
- The app includes a dense dark dashboard, scalable Huawei/Fiberhome device-profile selector, PCC/signal panels, SIM information panel, carrier/neighbor panels, raw snapshot view, and guarded configuration actions.
- After the first successful read, the dashboard auto-refreshes every 5 seconds and shows the last update time.
- Simple mode translates source parameters for normal users; Pro mode keeps raw field names such as `UL_AMBR`, `DL_AMBR`, `QCI`, `DL_Modulation`, and `UL_Modulation`.
- Huawei mode supports password login, status/signal/traffic/PLMN reads, neighbor reads, automatic mode, and unlock-all.
- Fiberhome/烽火 mode is alpha: it uses username/password login via `get_refresh_sessionid` + `app_do_login`, reads `app_get_base_info`, and uses captured `POST /api/tmp/FHTOOLAPIS` calls for network mode, lock Band, NR lock cell, 4G+5G combined lock cell, and clear lock-cell list.
- Fiberhome `FHTOOLAPIS` JSON POST calls are sent with fixed `Content-Length`, a fresh `get_refresh_sessionid` per POST, and direct LAN routing; the tested device returns HTTP 403 for chunked POST requests, stale POST sessionids, or proxy-routed local traffic.
- The app displays TAC decimal conversion plus LTE ECI and NR GCI calculations where source fields exist.
- iOS/macOS native builds still require full Xcode and CocoaPods.

Verified commands:

```bash
flutter pub get
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter test
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter analyze
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --release
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build web
```

Android APK output:

```text
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
```

Web/PWA output:

```text
build/web
```

GitHub Release `v0.3.1` uploads the packaged Android APKs, Web/PWA zip, macOS desktop zip, Python wheel, and checksums.

The current local APKs are rebuilt from the `0.3.2+5` Flutter app state and staged in `dist/release/v0.3.2/`:

```text
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
../../dist/release/v0.3.2/CPEManager-android-v0.3.2-release.apk
../../dist/release/v0.3.2/CPEManager-android-v0.3.2-debug.apk
```

HarmonyOS/OpenHarmony should be built with the OpenHarmony-SIG Flutter SDK rather than upstream Flutter stable.
