# Changelog

All notable changes to this project are documented here.

## 0.3.2 - 2026-05-13

Fiberhome readback and mobile dashboard usability release.

### Release Assets

- `CPEManager-android-v0.3.2-release.apk`
- `SHA256SUMS.txt`
- Full debug APK is built and kept local at `dist/release/v0.3.2/CPEManager-android-v0.3.2-debug.apk`; it is not uploaded because of its size.

### Fixed

- Fixed Fiberhome/烽火 HTTP 403 on `FHTOOLAPIS` JSON POST calls by sending a fixed `Content-Length` body instead of Dart's default chunked transfer.
- Fixed Fiberhome POST readback after login by refreshing `get_refresh_sessionid` before each `FHTOOLAPIS` POST, matching captured HAR behavior where every POST uses a fresh sessionid.
- Bypassed desktop HTTP proxy environment settings for LAN CPE clients so `192.168.8.1` traffic goes direct from Flutter and Python.
- Fixed mobile dashboard tile overflow that appeared as Flutter red/yellow debug stripes on long Fiberhome values.
- Reset the scroll position when switching bottom workspaces so the login view no longer opens at the previous tab's scroll offset.

### Added

- Added 5-second auto refresh after the first successful read, with a header toggle and last-update timestamp.
- Added Simple/Pro display modes: Simple translates common fields for normal users; Pro keeps source parameter names such as `UL_AMBR`, `DL_AMBR`, `QCI`, `DL_Modulation`, and `UL_Modulation`.
- Added a SIM information panel for `UL_AMBR`, `DL_AMBR`, and `QCI`, displayed in Mbps where applicable.
- Added RF-quality modulation tiles for downlink and uplink modulation.
- Reworked the CPE device selector into a scalable device-profile dropdown for future multi-device support.
- Bumped Flutter app version to `0.3.2+5` and Python package version to `0.3.2`.

### Verified

- `dart format apps/flutter_cpemanager/lib/main.dart apps/flutter_cpemanager/test/widget_test.dart apps/flutter_cpemanager/lib/api/cpe_client.dart apps/flutter_cpemanager/lib/api/fiberhome_client.dart`
- `flutter test`
- `flutter analyze`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --release`
- `conda run -n cpemanager python -m unittest discover -s tests`
- `conda run -n cpemanager python -m compileall -q src tests cpe_login.py cpe_signal.py cpe_nbr.py cpe_lock.py cpe_netmode.py cpe_antenna.py tools/build_desktop.py tools/fiberhome_readonly_smoke.py packaging/desktop_entry.py`
- `conda run -n cpemanager cpemanager-desktop --version`
- `flutter clean` followed by fresh debug/release APK rebuilds.
- `aapt dump badging` confirmed the full local debug APK and uploaded release APK use `versionName='0.3.2'` and `versionCode='5'`.
- GitHub Release `v0.3.2` uploads only the release APK and checksum file; the full debug APK is kept local because of its size.
- Local Fiberhome read-only probe with the real device password: `get_refresh_sessionid`, `app_do_login`, `app_get_base_info`, `app_get_airplane`, `app_get_network_info`, `app_get_lockband`, and `app_get_cell_list` return HTTP 200.

## 0.3.1 - 2026-05-13

Huawei login and Fiberhome live-status release.

### Release Assets

- `CPEManager-android-v0.3.1-release.apk`
- `CPEManager-android-v0.3.1-debug.apk`
- `CPEManager-macos-arm64-v0.3.1-app.zip`
- `CPEManager-web-v0.3.1.zip`
- `cpemanager-0.3.1-py3-none-any.whl`
- `SHA256SUMS.txt`

### Added

- Added Fiberhome/烽火 automatic login from the new `login_v1.py` flow: `get_refresh_sessionid` followed by `app_do_login`.
- Added Fiberhome `app_get_base_info` status mapping for model, PLMN, WorkMode, RRC, NR band, ARFCN, PCI, RSRP/RSRQ/SINR/RSSI/CQI, MCS, MIMO, AMBR, temperature, software version, traffic speeds, daily/monthly bytes, TAC, and NCGI.
- Added Fiberhome neighbor parsing from comma-separated `BAND_NBR`, `EARFCN_NBR`, `PCI_NBR`, `RSRP_NBR`, `RSRQ_NBR`, and `SINR_NBR`.
- Added Fiberhome `app_get_airplane` readback in the snapshot.

### Changed

- Huawei login now prefers `/api/webserver/SesTokInfo` and fetches separate tokens for `challenge_login` and `authentication_login`, matching the new Huawei HAR and avoiding `challenge_login` error code `125003`.
- The Fiberhome UI now asks for username/password instead of a captured `sessionid`.
- Local capture folders such as `烽火(1)/` are ignored to avoid committing HAR files or temporary login scripts.
- Bumped Flutter app version to `0.3.1+4` and Python package version to `0.3.1`.

### Verified

- `flutter test`
- `flutter analyze`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug`
- `JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --release`
- `conda run -n cpemanager python -m unittest discover -s tests`
- `conda run -n cpemanager python -m compileall -q src tests cpe_login.py cpe_signal.py cpe_nbr.py cpe_lock.py cpe_netmode.py cpe_antenna.py tools/build_desktop.py packaging/desktop_entry.py`

## 0.3.0 - 2026-05-13

Mobile dashboard and Fiberhome device-adapter release.

### Release Assets

- `CPEManager-android-v0.3.0-release.apk`
- `CPEManager-android-v0.3.0-debug.apk`
- `CPEManager-macos-arm64-v0.3.0-app.zip`
- `CPEManager-web-v0.3.0.zip`
- `cpemanager-0.3.0-py3-none-any.whl`
- `SHA256SUMS.txt`

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

- Bumped the Flutter app package version to `0.3.0+3` and Python package version to `0.3.0`.
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
- Release assets are assembled under `dist/release/v0.3.0` and uploaded to GitHub Release `v0.3.0`; they are not committed to git.

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
