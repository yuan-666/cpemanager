# Changelog

All notable changes to this project are documented here.

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
- Flutter and Dart are not installed on the current machine, so the Flutter app skeleton is not yet locally build-verified.
- The workflow template is not committed under `.github/workflows/` because the current GitHub OAuth token lacks `workflow` scope.
