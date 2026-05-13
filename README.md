# CPE Manager

Huawei CPE management toolkit, now expanding into a multi-vendor CPE app. The project has moved from separate proof-of-concept scripts into a package with a single CLI, reusable client, desktop GUI, Flutter mobile app, tests, and release-ready packaging metadata.

## Version

- Current local build version: `0.3.2`
- Current published version: `0.3.2`
- Current Flutter app version: `0.3.2+5`
- Release state: alpha
- Maintainer account email: `2991077067@qq.com`
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Current build notes: [docs/releases/v0.3.2.md](docs/releases/v0.3.2.md)
- Latest published release notes: [docs/releases/v0.3.2.md](docs/releases/v0.3.2.md)
- Handoff docs: [HANDOFF.md](HANDOFF.md), [PROJECT_MEMORY.md](PROJECT_MEMORY.md), [MODIFICATIONS.md](MODIFICATIONS.md)

## Latest Release Assets

Release `v0.3.2` is published at [GitHub Releases](https://github.com/yuan-666/cpemanager/releases/tag/v0.3.2).

GitHub Release `v0.3.2` intentionally uploads only the release APK and checksum file. The full debug APK is large, so it is kept local under `dist/release/v0.3.2/` for troubleshooting.

| Asset | Use |
| --- | --- |
| `CPEManager-android-v0.3.2-release.apk` | Recommended Android phone install package uploaded to GitHub Release. |
| `SHA256SUMS.txt` | Release APK checksum uploaded to GitHub Release. |
| `CPEManager-android-v0.3.2-debug.apk` | Full local-only debug package for troubleshooting; not uploaded. |

Previous `v0.3.1` release assets:

| Asset | Use |
| --- | --- |
| `CPEManager-android-v0.3.1-release.apk` | Recommended Android phone test package. |
| `CPEManager-android-v0.3.1-debug.apk` | Debug Android package for troubleshooting. |
| `CPEManager-macos-arm64-v0.3.1-app.zip` | macOS Apple Silicon desktop app bundle. |
| `CPEManager-web-v0.3.1.zip` | Flutter Web/PWA static build. |
| `cpemanager-0.3.1-py3-none-any.whl` | Python CLI and desktop wheel. |
| `SHA256SUMS.txt` | Checksums for release assets. |

Android alpha install:

```bash
adb install -r dist/release/v0.3.2/CPEManager-android-v0.3.2-release.apk
```

Python wheel install:

```bash
python -m pip install cpemanager-0.3.1-py3-none-any.whl
```

Fiberhome read-only smoke test:

```bash
CPE_PASSWORD="管理密码" conda run -n cpemanager python tools/fiberhome_readonly_smoke.py
```

This probe only calls `get_refresh_sessionid`, `app_do_login`, and `app_get_*` methods. It never calls `app_set_*`, lock writes, reboot, reset, or airplane writes.

## What Is Included

- Python package and reusable Huawei CPE client.
- Unified CLI command: `cpemanager`.
- Legacy script compatibility for the original six scripts.
- Tkinter desktop GUI command: `cpemanager-desktop`.
- PyInstaller desktop build path for macOS and Windows.
- Flutter/Dart mobile-first app for Android, iOS, Windows, macOS, web, and a future HarmonyOS/OpenHarmony spike.
- Flutter app now includes a scalable Huawei/Fiberhome device-profile selector, 5-second auto refresh, Simple/Pro display modes, SIM information, and RF modulation tiles; Fiberhome support is alpha and based on captured `FHTOOLAPIS` calls.
- Unit tests, API notes, packaging strategy, and handoff documentation.
- Active GitHub Actions desktop build workflow: [.github/workflows/desktop-build.yml](.github/workflows/desktop-build.yml)
- Workflow template copy: [docs/github-actions/desktop-build.yml](docs/github-actions/desktop-build.yml)

## Current Scope

Supported read APIs:

- `/api/net/current-plmn`
- `/api/device/nbrcellinfo`
- `/api/device/seccellinfo`
- `/api/device/signal`
- `/api/monitoring/traffic-statistics`
- `/api/monitoring/status`
- `/api/webserver/token`

Supported write/login APIs:

- `/api/user/challenge_login`
- `/api/user/authentication_login`
- `/api/net/net-mode`
- `/api/net/lock-freq`
- `/api/device/antenna_set_type`

Additional discovered device APIs used by existing scripts:

- `/api/device/basic_information`
- `/api/device/antenna_type`
- `/config/network/bandfreqlist.xml`

Fiberhome/烽火 alpha APIs captured from HAR:

- `GET /api/tmp/FHNCAPIS?ajaxmethod=get_refresh_sessionid` obtains the login sessionid.
- `POST /api/tmp/FHTOOLAPIS` with JSON body fields `ajaxmethod`, `sessionid`, and `dataObj`.
- Confirmed methods: `app_do_login`, `app_get_base_info`, `app_get_airplane`, `app_get_network_info`, `app_set_network_info`, `app_get_lockband`, `app_set_lockband`, `app_get_cell_list`, `app_set_cell_list`.
- `app_get_base_info` now supplies Fiberhome signal, traffic, model, software, TAC/NCGI, MCS, MIMO, temperature, and neighbor rows.
- Fiberhome `FHTOOLAPIS` POST calls must use fixed `Content-Length` JSON bodies and a fresh `get_refresh_sessionid` value per POST; chunked transfer or reusing the login sessionid returns HTTP 403 on the tested device. The app now also bypasses desktop proxy settings for LAN CPE traffic.

## Conda Setup

```bash
conda activate cpemanager
python -m pip install -e .
```

Or recreate the environment later:

```bash
conda env create -f environment.yml
conda activate cpemanager
```

## CLI Usage

All commands default to `192.168.8.1` and username `admin`. Password can be provided with `--password`, environment variable `CPE_PASSWORD`, or the hidden prompt.

```bash
cpemanager login
cpemanager signal
cpemanager signal --json
cpemanager nbr
cpemanager netmode
cpemanager netmode --net-mode 08 --net-option 2
cpemanager netmode --auto-mode
cpemanager antenna
cpemanager antenna --set 1
cpemanager lock
cpemanager lock --nr-band 41,78
cpemanager lock --nr-pci 78:633984:360
cpemanager lock --lte-band 1,3,28
cpemanager lock --mix-band 41,78 1,3
cpemanager lock --unlock
cpemanager lock --bands
cpemanager raw /api/device/signal
cpemanager raw http://192.168.8.1/api/device/signal
```

## Desktop App

The first desktop app is a Tkinter GUI on top of the same Python client. It is intended as the fast Windows/macOS packaging track while the Flutter app matures.

```bash
conda activate cpemanager
python -m pip install -e ".[desktop-build]"
cpemanager-desktop
```

Build the local desktop app:

```bash
python tools/build_desktop.py --onedir
```

On macOS this creates:

```text
dist/desktop/CPEManager.app
```

PyInstaller builds are platform-local: build Windows artifacts on Windows and macOS artifacts on macOS.

## Mobile App

The phone app lives in `apps/flutter_cpemanager`. It is a Flutter app with a dense dark dashboard, device selector, PCC/signal panels, carrier and neighbor panels, raw snapshot panel, and guarded configuration actions.

Current mobile device modes:

- Huawei: password login, signal/status/traffic/PLMN reads, neighbor reads, automatic network mode, and unlock-all.
- Fiberhome/烽火: username/password login for the captured `FHNCAPIS` + `FHTOOLAPIS` flow, live `app_get_base_info` dashboard, Auto/LTE/SA/NSA mode writes, lock Band, NR lock cell, 4G+5G combined lock cell, clear lock-cell list, and readback of network/lock state.
- Display modes: Simple mode translates fields such as `UL_AMBR` into “上行签约带宽”; Pro mode keeps source parameter names for debugging and handoff.
- Auto refresh: after a successful read, the mobile dashboard refreshes every 5 seconds unless disabled in the header.

Cell calculations shown in the app:

- LTE ECI = `eNB ID * 256 + cell ID`
- NR GCI = `gNB ID * 4096 + cell ID`
- TAC hex values are also displayed as decimal where the source field exists.

```bash
cd apps/flutter_cpemanager
flutter pub get
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug
```

Current verified Android debug APK:

```text
apps/flutter_cpemanager/build/app/outputs/flutter-apk/app-debug.apk
```

Current verified Android release APK:

```text
apps/flutter_cpemanager/build/app/outputs/flutter-apk/app-release.apk
```

Install on an Android phone with USB debugging enabled:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Cross-Platform App Track

Flutter is the shared UI/client layer for Android, iOS, Windows, macOS, and web. Native platform folders have been generated under `apps/flutter_cpemanager` for Android, iOS, macOS, Windows, and web.

Useful commands:

```bash
cd apps/flutter_cpemanager
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter test
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter analyze
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --release
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build web
flutter build appbundle
flutter build ios --no-codesign
flutter build macos
flutter build windows
```

Notes:

- Android builds are verified locally with Flutter `3.41.9`, Dart `3.11.5`, OpenJDK 17, Android SDK 36, Build Tools 36.0.0, and NDK 28.2.13676358.
- iOS and macOS Flutter native builds require full Xcode and CocoaPods; the current machine only has Command Line Tools, so those builds are not verified yet.
- Windows artifacts must be built on Windows.
- HarmonyOS/OpenHarmony needs a separate validation pass with the OpenHarmony-SIG Flutter SDK.

Legacy scripts are kept as compatibility wrappers. These commands match the earlier manual:

```bash
python cpe_signal.py --password "密码"
python cpe_signal.py --password "密码" --json
python cpe_nbr.py --password "密码"
python cpe_lock.py --password "密码"
python cpe_lock.py --password "密码" --bands
python cpe_lock.py --password "密码" --nr-band 41,78
python cpe_lock.py --password "密码" --nr-arfcn 78:633984
python cpe_lock.py --password "密码" --nr-pci 78:633984:360
python cpe_lock.py --password "密码" --lte-band 1,3,28
python cpe_lock.py --password "密码" --lte-arfcn 1:100
python cpe_lock.py --password "密码" --lte-pci 1:100:308
python cpe_lock.py --password "密码" --mix-band 1,78 1,8
python cpe_lock.py --password "密码" --unlock
python cpe_netmode.py --password "密码"
python cpe_netmode.py --password "密码" --net-mode 03
python cpe_netmode.py --password "密码" --net-mode 08
python cpe_netmode.py --password "密码" --net-option 0
python cpe_netmode.py --password "密码" --net-option 1
python cpe_netmode.py --password "密码" --net-option 2
python cpe_netmode.py --password "密码" --auto-mode
python cpe_antenna.py --password "密码"
python cpe_antenna.py --password "密码" --antenna 0
python cpe_antenna.py --password "密码" --antenna 1
python cpe_antenna.py --password "密码" --antenna 2
python cpe_antenna.py --password "密码" --antenna 3
python cpe_login.py --password "密码"
```

Note: the legacy `python cpe_netmode.py --password "密码"` command keeps the original behavior and restores automatic mode with SA+NSA. The new `cpemanager netmode` command only displays the current mode unless a setting option is passed.

## Development

```bash
conda activate cpemanager
python -m pip install -e .
python -m unittest discover -s tests
python -m pip wheel . -w dist
```

Detailed API notes live in [docs/API_REFERENCE.md](docs/API_REFERENCE.md).
Packaging notes live in [docs/APP_PACKAGING_STRATEGY.md](docs/APP_PACKAGING_STRATEGY.md).
Project continuity notes live in [PROJECT_MEMORY.md](PROJECT_MEMORY.md).

GitHub Actions is active under `.github/workflows/desktop-build.yml`. If a future token loses workflow permission, refresh it with:

```bash
gh auth refresh -h github.com -s workflow
```

## Release Roadmap

1. Keep the Python package and CLI stable.
2. Add mocked tests for every API payload and parser.
3. Add live-device smoke tests gated behind explicit host/password input.
4. Keep desktop PyInstaller builds working on Windows/macOS.
5. Finish the Flutter/Dart protocol port and build Android/iOS/desktop packages.
6. Run a HarmonyOS/OpenHarmony spike before promising production support.
