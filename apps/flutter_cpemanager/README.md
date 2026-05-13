# Flutter CPE Manager

This is the long-term cross-platform app track for Android, iOS, Windows, macOS, web, and HarmonyOS/OpenHarmony.

Current state:

- Android, iOS, macOS, Windows, and web platform folders are generated.
- Android debug APK builds successfully on the current Mac.
- The app includes a mobile connection form, status dashboard, NR neighbor panel, raw snapshot view, and guarded automatic-mode/unlock-all actions.
- iOS/macOS native builds still require full Xcode and CocoaPods.

Verified commands:

```bash
flutter pub get
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter test
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter analyze
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build web
```

Android APK output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Web/PWA output:

```text
build/web
```

HarmonyOS/OpenHarmony should be built with the OpenHarmony-SIG Flutter SDK rather than upstream Flutter stable.
