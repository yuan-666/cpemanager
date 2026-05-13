# Changelog

All notable changes to this project are documented here.

## Unreleased - 2026-05-13

Mobile dashboard and Fiberhome device-adapter iteration.

### Added

- Reworked the Flutter app into a denser dark toolboard UI with device selection, status chips, PCC/signal panels, carrier/neighbor panels, lock-frequency controls, speed/raw views, and responsive mobile stacking.
- Added a Fiberhome/烽火 Dart client for the captured `POST /api/tmp/FHTOOLAPIS` API shape:
  - `app_get_network_info`
  - `app_set_network_info`
  - `app_get_lockband`
  - `app_set_lockband`
  - `app_get_cell_list`
  - `app_set_cell_list`
- Added Fiberhome configuration actions for Auto/LTE/SA/NSA mode, lock Band, NR lock cell, 4G+5G combined lock cell, and clear locked cells.
- Added shared cell math helpers for TAC decimal conversion, LTE ECI (`eNB ID * 256 + cell ID`), NR GCI (`gNB ID * 4096 + cell ID`), and ECI/GCI splitting.
- Added Dart tests for TAC/ECI/GCI conversion and Fiberhome lock-cell payload shape.

### Changed

- Bumped the Flutter app package version to `0.3.0+3`; the Python package remains at the published `0.2.0` release until the next full release bundle is cut.
- Hardened the Dart Huawei and Fiberhome clients so host input can include or omit `http://`.
- Ignored raw `.har` captures because they can contain live `sessionid` values and device identifiers.

### Verified

- `flutter test`
- `flutter analyze`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --release`
- `flutter build web`
- `conda run -n cpemanager python -m unittest discover -s tests`

### Notes

- The current Fiberhome HAR set only covers configuration operations through `FHTOOLAPIS`; it does not include the session acquisition/login flow, live RF signal, traffic, device info, or neighbor-cell status endpoints.
- The rebuilt Android APKs are local artifacts at `apps/flutter_cpemanager/build/app/outputs/flutter-apk/` and are not yet uploaded as a new GitHub Release.

## 0.2.0 - 2026-05-13

Mobile and workflow enablement release.

### Release Assets

- `CPEManager-android-v0.2.0-release.apk`
- `CPEManager-android-v0.2.0-debug.apk`
- `CPEManager-macos-arm64-v0.2.0-app.zip`
- `CPEManager-web-v0.2.0.zip`
- `cpemanager-0.2.0-py3-none-any.whl`
- `SHA256SUMS.txt`

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
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --release`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter test`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter analyze`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build web`
- `conda run -n cpemanager python -m unittest discover -s tests`
- `conda run -n cpemanager python -m compileall -q src tests cpe_login.py cpe_signal.py cpe_nbr.py cpe_lock.py cpe_netmode.py cpe_antenna.py tools/build_desktop.py packaging/desktop_entry.py`

### Notes

- Android debug APK output: `apps/flutter_cpemanager/build/app/outputs/flutter-apk/app-debug.apk`.
- Web/PWA output: `apps/flutter_cpemanager/build/web`.
- Release assets are assembled under `dist/release/v0.2.0` and uploaded to GitHub Release `v0.2.0`; they are not committed to git.
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
