# 项目记忆

> 维护规则：后续任何代码、文档、依赖、打包、测试、发布流程或产品方向变更，都必须同步更新 `MODIFICATIONS.md`、本文件和 `HANDOFF.md`。

## 项目目标

本项目是一个 Huawei CPE 管理工具，目标是从当前 Python CLI/桌面工具继续迭代为可发布软件，并逐步覆盖：

- Windows
- macOS
- Android
- iOS
- HarmonyOS/OpenHarmony

当前策略是两条线并行：

- 快速桌面线：继续使用 Python 客户端 + Tkinter GUI + PyInstaller，优先覆盖 macOS/Windows。
- 长期全平台线：使用 Flutter/Dart 重写协议层和 UI，覆盖 Android/iOS/Windows/macOS；HarmonyOS/OpenHarmony 需要单独可行性验证。

## 当前环境

- 工作目录：`/Users/yuanhuang/code/cpemanager`
- GitHub 仓库已由用户创建，仓库名与目录同名：`cpemanager`。
- 本地提交身份应使用邮箱：`2991077067@qq.com`。
- 远程仓库 URL：`https://github.com/yuan-666/cpemanager.git`。
- `main` 已成功推送到 `origin/main`。
- 首个提交：`b2cb9e4 chore: initialize cpemanager app project`。
- 2026-05-13 检查到本机 `gh` 默认账号 `yuan-666` token 已失效；但 `git push` 可以通过已有凭据访问远程。
- 当前 OAuth token 缺少 `workflow` scope，不能推送 `.github/workflows/*`。桌面构建 workflow 暂存为 `docs/github-actions/desktop-build.yml` 模板，重新授权后再复制到 `.github/workflows/desktop-build.yml`。
- conda 环境名：`cpemanager`
- Python：3.11.15
- 主要 Python 运行依赖：`requests`
- 桌面打包依赖：`pyinstaller`
- 当前机器没有安装 `flutter` / `dart`，所以 Flutter 骨架不能在本机验证构建。

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

- 代码骨架在 `apps/flutter_cpemanager`。
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

实机 CPE 测试当前没有做过，因为需要真实密码和确认机器连接到 `192.168.8.1` 网络。写操作如锁频、网络模式、天线设置必须谨慎，后续应增加二次确认和只读 smoke test。

## 后续优先级

1. 把 Python 客户端进一步拆分为协议层、传输层、领域模型、展示层。
2. 给登录流程、payload builder、XML parser 补 fixture/golden tests。
3. 给写操作增加确认机制和恢复当前配置的保护。
4. 完善 Tkinter GUI 的锁频输入、网络模式输入和错误提示。
5. 安装 Flutter/Dart 后验证 `apps/flutter_cpemanager`。
6. 做 HarmonyOS/OpenHarmony spike，验证 HTTP、crypto、XML、局域网权限和打包链路。
