# CPE Manager

Huawei CPE management toolkit. The project has moved from separate proof-of-concept scripts into a package with a single CLI, reusable client, desktop GUI, tests, and release-ready packaging metadata.

## Version

- Current version: `0.1.0`
- Release state: alpha
- Maintainer account email: `2991077067@qq.com`
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Handoff docs: [HANDOFF.md](HANDOFF.md), [PROJECT_MEMORY.md](PROJECT_MEMORY.md), [MODIFICATIONS.md](MODIFICATIONS.md)

## What Is Included

- Python package and reusable Huawei CPE client.
- Unified CLI command: `cpemanager`.
- Legacy script compatibility for the original six scripts.
- Tkinter desktop GUI command: `cpemanager-desktop`.
- PyInstaller desktop build path for macOS and Windows.
- Flutter/Dart app skeleton for Android, iOS, Windows, macOS, and a future HarmonyOS/OpenHarmony spike.
- Unit tests, API notes, packaging strategy, and handoff documentation.
- GitHub Actions desktop build template: [docs/github-actions/desktop-build.yml](docs/github-actions/desktop-build.yml)

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

## Cross-Platform App Track

The long-term app lives in `apps/flutter_cpemanager`. Flutter is the planned shared UI/client layer for Android, iOS, Windows, and macOS. HarmonyOS/OpenHarmony needs a separate validation pass with the OpenHarmony-SIG Flutter SDK.

```bash
cd apps/flutter_cpemanager
flutter create --platforms=android,ios,windows,macos .
flutter pub get
flutter run -d macos
```

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

Note: the GitHub Actions workflow is stored as a template under `docs/github-actions/desktop-build.yml`. Copy it to `.github/workflows/desktop-build.yml` after authenticating GitHub with `workflow` scope.

## Release Roadmap

1. Keep the Python package and CLI stable.
2. Add mocked tests for every API payload and parser.
3. Add live-device smoke tests gated behind explicit host/password input.
4. Keep desktop PyInstaller builds working on Windows/macOS.
5. Finish the Flutter/Dart protocol port and build Android/iOS/desktop packages.
6. Run a HarmonyOS/OpenHarmony spike before promising production support.
