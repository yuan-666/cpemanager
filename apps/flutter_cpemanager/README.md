# Flutter CPE Manager

This is the long-term cross-platform app track for Android, iOS, Windows, macOS, web, and HarmonyOS/OpenHarmony.

Current state:

- Android, iOS, macOS, Windows, and web platform folders are generated.
- Android debug and release APKs build successfully on the current Mac.
- App version is `0.3.0+3`.
- The app includes a dense dark dashboard, Huawei/Fiberhome device selector, PCC/signal panels, carrier/neighbor panels, raw snapshot view, and guarded configuration actions.
- Huawei mode supports password login, status/signal/traffic/PLMN reads, neighbor reads, automatic mode, and unlock-all.
- Fiberhome/烽火 mode is alpha: it uses manual `sessionid` input and the captured `POST /api/tmp/FHTOOLAPIS` calls for network mode, lock Band, NR lock cell, 4G+5G combined lock cell, and clear lock-cell list.
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

GitHub Release `v0.3.0` uploads the packaged Android APKs, Web/PWA zip, macOS desktop zip, Python wheel, and checksums.

The current local APKs are rebuilt from the `0.3.0+3` Flutter app state:

```text
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
```

HarmonyOS/OpenHarmony should be built with the OpenHarmony-SIG Flutter SDK rather than upstream Flutter stable.
