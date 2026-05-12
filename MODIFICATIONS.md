# 修改记录

> 维护规则：后续任何代码、文档、依赖、打包、测试、发布流程或产品方向变更，都必须同步更新本文件、`PROJECT_MEMORY.md` 和 `HANDOFF.md`。

## 2026-05-13

- 准备 GitHub 版本管理：
  - 新增 `CHANGELOG.md`，记录 `0.1.0` alpha 版本描述。
  - 更新 `README.md`，补版本、维护账号邮箱、项目内容、连续维护文档入口。
  - 更新 `pyproject.toml` 作者邮箱为 `2991077067@qq.com`。
  - 扩展 `.gitignore`，补 Flutter/Dart 生成文件忽略规则。
  - 将 GitHub Actions 桌面构建文件保存为 `docs/github-actions/desktop-build.yml` 模板；当前 OAuth token 缺少 `workflow` scope，不能直接推送 `.github/workflows/desktop-build.yml`。
  - 计划首个提交描述：`chore: initialize cpemanager app project`。
- 新增本项目的连续维护三件套：
  - `MODIFICATIONS.md`：记录每次重要修改和验证结果。
  - `PROJECT_MEMORY.md`：保存项目长期约定、架构记忆、环境要求和注意事项。
  - `HANDOFF.md`：给下一位 AI/开发者的接手说明。
- 固化后续维护要求：每次改动都要更新上述三个文件，避免切换模型或转交其他 AI 后丢上下文。

## 2026-05-12

- 将原本 6 个散装 Python 脚本重构为可安装 Python 包：
  - `src/cpemanager/client.py`：统一 Huawei CPE API 客户端。
  - `src/cpemanager/cli.py`：统一 CLI，提供 `login/signal/nbr/netmode/antenna/lock/raw` 子命令。
  - `src/cpemanager/gui.py`：Tkinter 桌面 GUI。
  - `src/cpemanager/endpoints.py`、`src/cpemanager/xmlutil.py`：端点与 XML 工具。
- 保留旧命令兼容入口：
  - `cpe_login.py`
  - `cpe_signal.py`
  - `cpe_nbr.py`
  - `cpe_lock.py`
  - `cpe_netmode.py`
  - `cpe_antenna.py`
- 新建 conda 环境 `cpemanager`，Python 版本为 3.11.15。
- 新增打包/依赖文件：
  - `pyproject.toml`
  - `environment.yml`
  - `requirements.txt`
  - `.gitignore`
- 新增测试：
  - `tests/test_client.py`
  - `tests/test_cli.py`
  - `tests/test_xmlutil.py`
- 新增文档：
  - `README.md`
  - `docs/API_REFERENCE.md`
  - `docs/APP_PACKAGING_STRATEGY.md`
- 新增桌面打包：
  - `packaging/desktop_entry.py`
  - `tools/build_desktop.py`
  - 构建产物：`dist/desktop/CPEManager.app`
- 新增 GitHub Actions 桌面构建模板：
  - `docs/github-actions/desktop-build.yml`
- 新增长期 Flutter 多端 App 骨架：
  - `apps/flutter_cpemanager/pubspec.yaml`
  - `apps/flutter_cpemanager/lib/main.dart`
  - `apps/flutter_cpemanager/lib/api/cpe_client.dart`
  - `apps/flutter_cpemanager/README.md`
- 当前验证结果：
  - `conda run -n cpemanager python -m unittest discover -s tests` 通过，10 个测试 OK。
  - `conda run -n cpemanager python -m compileall -q ...` 通过。
  - `conda run -n cpemanager python tools/build_desktop.py --onedir` 通过，产物位于 `dist/desktop`。
  - `conda run -n cpemanager cpemanager-desktop --version` 输出 `CPE Manager 0.1.0`。
