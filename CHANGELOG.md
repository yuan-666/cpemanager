# Changelog

All notable changes to this project are documented here.

## 0.2.0 - 2026-05-13

Mobile and workflow enablement release.

### Added

- Generated Flutter native platform folders for Android, iOS, macOS, Windows, and web.
- Replaced the placeholder Flutter screen with a mobile-first CPE dashboard:
  - connection form for host, username, and password
  - status metric grid
  - NR neighbor panel sorted by RSRP
  - raw JSON snapshot panel
  - guarded automatic-network-mode and unlock-all actions
- Extended the Dart CPE client with device info, network mode, neighbor cells, secondary cells, antenna read support, automatic network mode writes, unlock-all writes, and neighbor list parsing.
- Added Android cleartext HTTP/local network support for `192.168.8.1`.
- Added iOS local-network and HTTP transport permissions.
- Added macOS network client entitlement.
- Added a Dart parser test for neighbor-cell RSRP sorting.
- Activated GitHub Actions at `.github/workflows/desktop-build.yml` after refreshing the GitHub token with `workflow` scope.
- Rebranded generated iOS, macOS, Windows, and web templates from Flutter defaults to CPE Manager identifiers.

### Changed

- Android Gradle wrapper now uses `gradle-8.14-bin.zip` to avoid the larger `all` distribution during first-time mobile builds.
- Android app id and namespace changed from the Flutter template value to `com.cpemanager.app`.
- Android build explicitly uses installed Build Tools `36.0.0`.

### Verified

- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter test`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter analyze`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build web`
- `conda run -n cpemanager python -m unittest discover -s tests`
- `conda run -n cpemanager python -m compileall -q src tests cpe_login.py cpe_signal.py cpe_nbr.py cpe_lock.py cpe_netmode.py cpe_antenna.py tools/build_desktop.py packaging/desktop_entry.py`

### Notes

- Android debug APK output: `apps/flutter_cpemanager/build/app/outputs/flutter-apk/app-debug.apk`.
- Web/PWA output: `apps/flutter_cpemanager/build/web`.
- No Android phone was connected during verification, so device install/launch remains to be checked on hardware.
- iOS/macOS Flutter native builds still require full Xcode and CocoaPods on this Mac.
- HarmonyOS/OpenHarmony remains a separate spike using the OpenHarmony-SIG Flutter SDK or an ArkTS fallback.

## 0.1.0 - 2026-05-13

Initial alpha release prepared for GitHub version control.

### Added

- Standard Python package layout under `src/cpemanager`.
- Unified CLI entrypoint `cpemanager` with `login`, `signal`, `nbr`, `netmode`, `antenna`, `lock`, and `raw` subcommands.
- Reusable Huawei CPE client with login challenge/authentication flow, token handling, XML parsing, status reads, network mode control, antenna control, and lock-frequency commands.
- Compatibility wrappers for the original scripts:
  - `cpe_login.py`
  - `cpe_signal.py`
  - `cpe_nbr.py`
  - `cpe_lock.py`
  - `cpe_netmode.py`
  - `cpe_antenna.py`
- Tkinter desktop GUI entrypoint `cpemanager-desktop`.
- PyInstaller desktop build script `tools/build_desktop.py`.
- GitHub Actions desktop build workflow template for macOS and Windows under `docs/github-actions/desktop-build.yml`.
- Flutter/Dart app skeleton in `apps/flutter_cpemanager`.
- API reference, packaging strategy, project memory, modification log, and handoff documents.
- Unit tests for XML helpers, client parsing/builders, and CLI compatibility.

### Verified

- `conda run -n cpemanager python -m unittest discover -s tests`
- `conda run -n cpemanager python -m compileall -q src tests cpe_login.py cpe_signal.py cpe_nbr.py cpe_lock.py cpe_netmode.py cpe_antenna.py tools/build_desktop.py packaging/desktop_entry.py`
- `conda run -n cpemanager python tools/build_desktop.py --onedir`
- `conda run -n cpemanager cpemanager-desktop --version`

### Notes

- Real-device login and write operations have not been verified because they require the actual CPE password and network access to `192.168.8.1`.
- PyInstaller builds are platform-local; Windows artifacts must be built on Windows.
- At the initial `0.1.0` checkpoint, Flutter/Dart and workflow scope were not yet configured locally; both are addressed in `0.2.0`.
