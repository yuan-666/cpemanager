# Flutter CPE Manager

This is the long-term cross-platform app track for Android, iOS, Windows, macOS, and HarmonyOS/OpenHarmony.

The current machine does not have Flutter installed, so only the portable Dart/Flutter source skeleton is committed. Generate native platform folders after installing the SDK:

```bash
flutter create --platforms=android,ios,windows,macos .
flutter pub get
flutter run -d macos
```

HarmonyOS/OpenHarmony should be built with the OpenHarmony-SIG Flutter SDK rather than upstream Flutter stable.
