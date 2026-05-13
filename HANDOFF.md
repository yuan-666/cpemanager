# 接手文档

> 维护规则：后续任何代码、文档、依赖、打包、测试、发布流程或产品方向变更，都必须同步更新 `MODIFICATIONS.md`、`PROJECT_MEMORY.md` 和本文件。

## 快速背景

这是 `/Users/yuanhuang/code/cpemanager` 下的 CPE 管理工具。项目最初只有 6 个 Huawei Python 脚本，现在已经整理成：

- 可安装 Python 包
- 统一 CLI
- 旧脚本兼容入口
- Tkinter 桌面 GUI
- PyInstaller 桌面构建脚本
- Flutter 多端 App，Android debug/release APK 已可构建
- Flutter App 已加入 Huawei/Fiberhome(烽火) 设备选择；烽火当前是基于 HAR 的配置操作 alpha 适配
- API/打包文档和基础测试

当前发布版本：`0.3.0`

当前 Flutter App 开发版本：`0.3.0+3`

首个提交描述：

```text
chore: initialize cpemanager app project
```

GitHub 同步状态：

- 远程仓库：`https://github.com/yuan-666/cpemanager.git`
- 分支：`main`
- 首个提交：`b2cb9e4 chore: initialize cpemanager app project`
- 本轮移动端功能提交：`caf42c9 feat: enable Android Flutter app`
- 本轮烽火看板提交：`70b42b6 feat: add fiberhome mobile dashboard`
- GitHub Actions：`Desktop Build` workflow 已 active。
- 发布说明：`docs/releases/v0.3.0.md`
- GitHub Release：`https://github.com/yuan-666/cpemanager/releases/tag/v0.3.0`
- Release assets 已确认全部上传完成。
- 本轮 Flutter/Fiberhome 改动已整理为 `v0.3.0` GitHub Release；本地 APK 已重新构建。

## 先读文件

接手后建议按这个顺序阅读：

1. `PROJECT_MEMORY.md`
2. `MODIFICATIONS.md`
3. `README.md`
4. `CHANGELOG.md`
5. `docs/API_REFERENCE.md`
6. `docs/APP_PACKAGING_STRATEGY.md`
7. `src/cpemanager/client.py`
8. `src/cpemanager/cli.py`
9. `src/cpemanager/gui.py`
10. `apps/flutter_cpemanager/lib/api/cpe_client.dart`
11. `apps/flutter_cpemanager/lib/api/fiberhome_client.dart`
12. `apps/flutter_cpemanager/lib/domain/cell_math.dart`

## 环境准备

已有 conda 环境：

```bash
conda activate cpemanager
```

如需重装：

```bash
conda env create -f environment.yml
conda activate cpemanager
python -m pip install -e ".[desktop-build]"
```

## 当前可用命令

统一 CLI：

```bash
cpemanager login --password "密码"
cpemanager signal --password "密码"
cpemanager signal --password "密码" --json
cpemanager nbr --password "密码"
cpemanager lock --password "密码"
cpemanager lock --password "密码" --nr-pci 78:633984:360
cpemanager netmode --password "密码"
cpemanager netmode --password "密码" --auto-mode
cpemanager antenna --password "密码"
cpemanager raw --password "密码" http://192.168.8.1/api/device/signal
```

旧脚本仍可用：

```bash
python cpe_signal.py --password "密码"
python cpe_lock.py --password "密码" --nr-band 41,78
python cpe_netmode.py --password "密码"
python cpe_antenna.py --password "密码" --antenna 1
```

桌面 GUI：

```bash
cpemanager-desktop
```

构建 macOS 桌面 App：

```bash
python tools/build_desktop.py --onedir
```

当前产物：

- `dist/desktop/CPEManager.app`
- `dist/desktop/CPEManager/CPEManager`
- `dist/release/v0.3.0/cpemanager-0.3.0-py3-none-any.whl`

移动端 Android：

```bash
cd apps/flutter_cpemanager
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

当前 Android APK：

- `apps/flutter_cpemanager/build/app/outputs/flutter-apk/app-debug.apk`
- `apps/flutter_cpemanager/build/app/outputs/flutter-apk/app-release.apk`
- 当前本地 APK 来自 Flutter app `0.3.0+3`。

Release assets staging:

- `dist/release/v0.3.0/CPEManager-android-v0.3.0-release.apk`
- `dist/release/v0.3.0/CPEManager-android-v0.3.0-debug.apk`
- `dist/release/v0.3.0/CPEManager-macos-arm64-v0.3.0-app.zip`
- `dist/release/v0.3.0/CPEManager-web-v0.3.0.zip`
- `dist/release/v0.3.0/cpemanager-0.3.0-py3-none-any.whl`
- `dist/release/v0.3.0/SHA256SUMS.txt`

Web/PWA：

```bash
cd apps/flutter_cpemanager
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build web
```

当前 Web 产物：

- `apps/flutter_cpemanager/build/web`

## 验证状态

最近一次验证通过：

```bash
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --release
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter test
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter analyze
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build web
conda run -n cpemanager python -m unittest discover -s tests
conda run -n cpemanager python -m pip wheel --no-deps --no-build-isolation . -w dist/release/v0.3.0
conda run -n cpemanager python tools/build_desktop.py --onedir
conda run -n cpemanager cpemanager-desktop --version
```

结果：

```text
Ran 10 tests in 0.001s
OK
CPE Manager 0.3.0
```

本轮 Flutter/Fiberhome 验证额外确认：

```bash
flutter test
flutter analyze
flutter build web
conda run -n cpemanager python -m unittest discover -s tests
```

Flutter 测试当前 5 个用例通过；`flutter analyze` 无问题。

编译检查通过：

```bash
conda run -n cpemanager python -m compileall -q src tests cpe_login.py cpe_signal.py cpe_nbr.py cpe_lock.py cpe_netmode.py cpe_antenna.py tools/build_desktop.py packaging/desktop_entry.py
```

桌面构建通过：

```bash
conda run -n cpemanager python tools/build_desktop.py --onedir
```

## 当前限制

- 没有做真实 CPE 登录测试，因为需要真实密码并确认机器连到 `192.168.8.1`。
- 没有做真实写操作测试，锁频/网络模式/天线切换可能影响设备网络，必须谨慎。
- 烽火 HAR 只覆盖 `POST /api/tmp/FHTOOLAPIS` 的配置接口，未覆盖 session 获取、实时信号、流量、设备信息和邻区状态；当前 App 要求手动输入 `sessionid`。
- 不要提交 `烽火/*.har` 或其他原始 HAR，里面可能包含 live `sessionid`。
- `adb devices` 当前未发现已连接手机，所以 Android APK 尚未做真机安装启动验证。
- Flutter `3.41.9` / Dart `3.11.5` 已安装并可构建 Android debug APK。
- Android SDK 位于 `/opt/homebrew/share/android-commandlinetools`，OpenJDK 17 位于 `/opt/homebrew/opt/openjdk@17`。
- 当前机器只有 Xcode Command Line Tools；iOS/macOS Flutter native build 仍需要完整 Xcode 和 CocoaPods。
- HarmonyOS/OpenHarmony 不是 Flutter 官方主线支持目标，需要 OpenHarmony-SIG Flutter SDK 或 ArkTS 备选路线。
- GitHub 仓库已由用户创建，仓库名与目录同名；`main` 已成功推送到该远程仓库。
- 远程仓库 URL：`https://github.com/yuan-666/cpemanager.git`。
- 2026-05-13 已通过 `gh auth login -h github.com --git-protocol https --web -s repo -s workflow -s read:org` 修复 GitHub CLI 授权。
- 当前 GitHub token scopes 包含 `gist`、`read:org`、`repo`、`workflow`。
- `.github/workflows/desktop-build.yml` 已启用；`docs/github-actions/desktop-build.yml` 保留为模板副本。

## 下一步建议

1. 新增 live smoke test：默认只读，使用 `CPE_HOST/CPE_USERNAME/CPE_PASSWORD`，写操作必须显式 `CPE_ALLOW_WRITE=1`。
2. 继续补抓烽火登录/session 获取、实时信号、流量、设备信息和邻区状态接口。
3. 增加 fixtures：Huawei 登录 challenge、authentication、signal、nbrcell、seccell、lock-freq、net-mode；Fiberhome `FHTOOLAPIS` 的六个方法。
4. 把 `format_status_summary()` 从 `HuaweiCPE` 客户端中拆到展示层。
5. Tkinter GUI 增加安全写操作确认、锁频输入表单和状态恢复提示。
6. 安装完整 Xcode 和 CocoaPods 后验证 iOS/macOS Flutter native build。
7. 增加 Android release signing、`.aab` 构建和发布说明。
8. 用 GitHub Actions 在 Windows/macOS 分别构建桌面产物。

## 接手纪律

- 不要删除旧脚本兼容入口，除非用户明确同意。
- 不要把 Python 客户端直接嵌到移动端作为长期方案；移动端应移植协议到 Dart/Flutter。
- 写入设备的功能必须保守处理，优先只读验证。
- 每次改动完成后，更新：
  - `MODIFICATIONS.md`
  - `PROJECT_MEMORY.md`
  - `HANDOFF.md`
