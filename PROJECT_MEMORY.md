# 项目记忆

> 维护规则：后续任何代码、文档、依赖、打包、测试、发布流程或产品方向变更，都必须同步更新 `MODIFICATIONS.md`、本文件和 `HANDOFF.md`。

## 项目目标

本项目是一个 CPE 管理工具，当前 Huawei 是最完整目标，Fiberhome/烽火正在按 HAR 抓包进入 Flutter App。目标是从当前 Python CLI/桌面工具继续迭代为可发布软件，并逐步覆盖：

- Windows
- macOS
- Android
- iOS
- HarmonyOS/OpenHarmony

当前策略是两条线并行：

- 快速桌面线：继续使用 Python 客户端 + Tkinter GUI + PyInstaller，优先覆盖 macOS/Windows。
- 长期全平台线：使用 Flutter/Dart 重写协议层和 UI，覆盖 Android/iOS/Windows/macOS/web；Android debug/release APK 已经可以本机构建，HarmonyOS/OpenHarmony 需要单独可行性验证。

## 当前环境

- 工作目录：`/Users/yuanhuang/code/cpemanager`
- GitHub 仓库已由用户创建，仓库名与目录同名：`cpemanager`。
- 本地提交身份应使用邮箱：`2991077067@qq.com`。
- 远程仓库 URL：`https://github.com/yuan-666/cpemanager.git`。
- `main` 已成功推送到 `origin/main`。
- 首个提交：`b2cb9e4 chore: initialize cpemanager app project`。
- 2026-05-13 曾检查到本机 `gh` 默认账号 `yuan-666` token 失效；本轮已重新授权修复。
- GitHub CLI 已重新授权，当前 token scopes 包含 `gist`、`read:org`、`repo`、`workflow`。
- `.github/workflows/desktop-build.yml` 已正式启用；`docs/github-actions/desktop-build.yml` 保留为模板副本。
- `gh workflow list --repo yuan-666/cpemanager` 已确认 `Desktop Build` workflow 为 active。
- 本轮移动端功能提交：`caf42c9 feat: enable Android Flutter app`。
- `v0.2.0` 发布说明文件：`docs/releases/v0.2.0.md`。
- `v0.2.0` release assets 本地暂存在 `dist/release/v0.2.0/`，该目录被 git ignore，资产通过 GitHub Release 上传。
- `v0.2.0` GitHub Release URL：`https://github.com/yuan-666/cpemanager/releases/tag/v0.2.0`。
- 2026-05-13 已确认 release 包含 6 个 uploaded assets：release APK、debug APK、macOS arm64 app zip、Web/PWA zip、Python wheel、SHA256SUMS。
- 当前开发版本：Python `0.3.1`，Flutter App `0.3.1+4`。
- 最近已发布版本：`v0.3.1`，GitHub Release URL：`https://github.com/yuan-666/cpemanager/releases/tag/v0.3.1`。
- 2026-05-13 已确认 `v0.3.1` release 包含 6 个 uploaded assets：release APK、debug APK、macOS arm64 app zip、Web/PWA zip、Python wheel、SHA256SUMS。
- 本地 HAR 抓包目录 `烽火/`、`烽火(1)/` 不要提交；HAR 内含 `sessionid`，`.gitignore` 已忽略 `*.har` 和 `烽火*/`。
- conda 环境名：`cpemanager`
- Python：3.11.15
- 主要 Python 运行依赖：`requests`
- 桌面打包依赖：`pyinstaller`
- Flutter：3.41.9
- Dart：3.11.5
- OpenJDK：`/opt/homebrew/opt/openjdk@17`
- Android SDK：`/opt/homebrew/share/android-commandlinetools`
- Android SDK Platform：36
- Android SDK Build Tools：36.0.0
- Android NDK：28.2.13676358
- CMake：3.22.1
- 当前机器只有 Xcode Command Line Tools；iOS/macOS Flutter native build 仍需要完整 Xcode 和 CocoaPods。

常用命令：

```bash
conda activate cpemanager
python -m pip install -e .
python -m pip install -e ".[desktop-build]"
python -m unittest discover -s tests
python tools/build_desktop.py --onedir
```

版本管理命令参考：

```bash
git init
git config user.email "2991077067@qq.com"
git config user.name "Yuan Huang"
git add .
git commit -m "chore: initialize cpemanager app project"
git branch -M main
git remote add origin https://github.com/yuan-666/cpemanager.git
git push -u origin main
```

## 架构记忆

Python 包采用 `src/` 布局：

- `src/cpemanager/client.py`：协议参考实现，包含登录、token、PBKDF2/HMAC clientproof、CPE API 调用、锁频、网络模式、天线、状态汇总等逻辑。
- `src/cpemanager/cli.py`：统一 CLI 入口。
- `src/cpemanager/gui.py`：当前桌面 GUI。
- `src/cpemanager/endpoints.py`：端点常量。
- `src/cpemanager/xmlutil.py`：XML 解析与 escape。

Flutter App 采用 Dart 客户端：

- `apps/flutter_cpemanager/lib/api/cpe_client.dart`：Huawei XML API 客户端，含 challenge/authentication 登录、状态读取、邻区读取、自动模式和解除锁频。
- `apps/flutter_cpemanager/lib/api/fiberhome_client.dart`：Fiberhome/烽火 `FHNCAPIS` + `FHTOOLAPIS` JSON 客户端，当前使用用户名/密码自动获取 sessionid 并登录。
- `apps/flutter_cpemanager/lib/domain/cell_math.dart`：TAC 十进制、LTE ECI、NR GCI 和 ECI/GCI 拆分工具。
- `apps/flutter_cpemanager/lib/main.dart`：深色密集看板 UI，含 Huawei/Fiberhome 设备选择、PCC、载波聚合、锁频、速率/原始快照工作区。

兼容脚本必须继续保留：

- `cpe_login.py`
- `cpe_signal.py`
- `cpe_nbr.py`
- `cpe_lock.py`
- `cpe_netmode.py`
- `cpe_antenna.py`

特别注意：

- `cpe_netmode.py --password "密码"` 保留旧行为：默认恢复自动模式 + SA+NSA。
- 新 CLI `cpemanager netmode` 默认只查看当前模式，只有传入设置参数才写入设备。
- `cpe_antenna.py --antenna 0/1/2/3` 需要继续兼容。

## 已知 API

核心读取端点：

- `/api/net/current-plmn`
- `/api/device/nbrcellinfo`
- `/api/device/seccellinfo`
- `/api/device/signal`
- `/api/monitoring/traffic-statistics`
- `/api/monitoring/status`
- `/api/webserver/token`

核心登录/写入端点：

- `/api/user/challenge_login`
- `/api/user/authentication_login`
- `/api/net/net-mode`
- `/api/net/lock-freq`
- `/api/device/antenna_set_type`

额外已使用端点：

- `/api/device/basic_information`
- `/api/device/antenna_type`
- `/config/network/bandfreqlist.xml`

Fiberhome/烽火已确认 API：

- `GET /api/tmp/FHNCAPIS?ajaxmethod=get_refresh_sessionid`
- `POST /api/tmp/FHTOOLAPIS`
- JSON 请求体包含 `ajaxmethod`、`sessionid`、`dataObj`。
- 已确认 `ajaxmethod`：`app_do_login`、`app_get_base_info`、`app_get_airplane`、`app_get_network_info`、`app_set_network_info`、`app_get_lockband`、`app_set_lockband`、`app_get_cell_list`、`app_set_cell_list`。
- `app_get_base_info` 返回烽火信号/流量/设备/邻区混合状态，字段包括 `RSSI/RSRQ/SSB_RSRP/SSB_SINR/PLMN/NR_Band/TAC/NCGI/EARFCN_NBR/PCI_NBR/Temperature/TxSpeed/RxSpeed/modelName/RRCStatus/DlMCS/UlMCS/CQI/DlMimo/UlMimo/Software_version/WorkMode`。
- 网络模式枚举：LTE=`networkMode:0, ENDC:1`；SA=`2,1`；NSA=`3,2`；Auto=`3,3`。
- 锁小区中 `act=1` 推断为 LTE，`act=2` 推断为 NR；需要真机继续确认。

Huawei 新 HAR 登录注意事项：

- 新设备登录前优先用 `/api/webserver/SesTokInfo` 获取 `SesInfo` 和 `TokInfo`。
- `challenge_login` 和 `authentication_login` 需要分别使用不同 token；只用旧 `/api/webserver/token` 容易出现 `challenge_login` 错误码 `125003`。
- 客户端仍保留旧 `/api/webserver/token` fallback，以兼容之前的设备。

小区换算规则：

- LTE ECI = `eNB ID * 256 + cell ID`
- NR GCI = `gNB ID * 4096 + cell ID`
- TAC 优先按十六进制转十进制；纯数字按十进制解析。

详细 API 文档在 `docs/API_REFERENCE.md`。

## 打包记忆

桌面 GUI 入口：

```bash
cpemanager-desktop
```

本机 macOS 构建命令：

```bash
conda activate cpemanager
python tools/build_desktop.py --onedir
```

当前 macOS 构建产物：

- `dist/desktop/CPEManager.app`
- `dist/desktop/CPEManager/CPEManager`

PyInstaller 不能跨平台编译：

- Windows 产物必须在 Windows 构建。
- macOS 产物必须在 macOS 构建。

Flutter 方向：

- 代码在 `apps/flutter_cpemanager`。
- Native 平台目录已经生成：Android、iOS、macOS、Windows、web。
- Android debug APK 已验证产出：`apps/flutter_cpemanager/build/app/outputs/flutter-apk/app-debug.apk`。
- Android release APK 已验证产出：`apps/flutter_cpemanager/build/app/outputs/flutter-apk/app-release.apk`。
- Web/PWA 已验证产出：`apps/flutter_cpemanager/build/web`。
- 当前本地 APK 已由 Flutter app `0.3.1+4` 重新构建；`v0.3.1` GitHub Release 使用同一版本线整理资产。
- Android 包名/namespace：`com.cpemanager.app`。
- iOS bundle id：`com.cpemanager.app`；macOS bundle id：`com.cpemanager.app.macos`；Windows executable name：`CPEManager`；web manifest title：`CPE Manager`。
- Android 允许明文 HTTP 访问 `192.168.8.1`；iOS 已配置局域网说明和 HTTP 放行；macOS 已配置 network client entitlement。
- Gradle wrapper 使用 `gradle-8.14-bin.zip`；Android app 显式使用 Build Tools `36.0.0`，避免坏的 `35.0.0` 自动安装包阻塞构建。
- Python 客户端是协议参考实现，不建议在移动端直接嵌 CPython。
- Flutter 官方主线覆盖 Android/iOS/Windows/macOS。
- HarmonyOS/OpenHarmony 需要 OpenHarmony-SIG Flutter SDK 或 ArkTS 备选方案，不要直接承诺已可发布。

## 测试和验证要求

每次修改后至少跑：

```bash
conda run -n cpemanager python -m unittest discover -s tests
conda run -n cpemanager python -m compileall -q src tests cpe_login.py cpe_signal.py cpe_nbr.py cpe_lock.py cpe_netmode.py cpe_antenna.py tools/build_desktop.py packaging/desktop_entry.py
```

如果修改打包或 GUI，再跑：

```bash
conda run -n cpemanager cpemanager-desktop --version
conda run -n cpemanager python tools/build_desktop.py --onedir
```

如果修改 wheel/发布配置，再跑：

```bash
conda run -n cpemanager python -m pip wheel --no-deps --no-build-isolation . -w dist
```

如果修改 Flutter app，再跑：

```bash
cd apps/flutter_cpemanager
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter test
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter analyze
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --release
JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build web
```

实机 CPE 测试当前没有做过，因为需要真实密码和确认机器连接到 `192.168.8.1` 网络。写操作如锁频、网络模式、天线设置必须谨慎，后续应增加二次确认和只读 smoke test。

Android APK 已构建，但 `adb devices` 当前未发现已连接手机，所以还没有做真机安装启动验证。

## 后续优先级

1. 把 Python 客户端进一步拆分为协议层、传输层、领域模型、展示层。
2. 给登录流程、payload builder、XML parser 补 fixture/golden tests。
3. 给写操作增加确认机制和恢复当前配置的保护。
4. 完善 Tkinter GUI 的锁频输入、网络模式输入和错误提示。
5. 安装完整 Xcode 和 CocoaPods 后验证 iOS/macOS Flutter native build。
6. 做 Android release signing 和 `.aab` 发布流程。
7. 做 HarmonyOS/OpenHarmony spike，验证 HTTP、crypto、XML、局域网权限和打包链路。
