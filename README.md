# Universal Dev Container — **Bypass Mode Default**

> 默认启用 **bypassPermissions**（绕过权限确认）。仅在**可信仓库**和**隔离环境**使用（默认启用基于白名单的出站防火墙）。

## 先决条件

- VS Code ≥ 1.105，扩展 `ms-vscode-remote.remote-containers` ≥ 0.427
- Docker Desktop（或兼容 Docker 引擎）已启动，支持 `host.docker.internal`
- Git 可用（用于脚本拉取仓库）
- 安装 Dev Containers CLI：`npm i -g @devcontainers/cli`
- 在受限网络或代理环境下，建议先阅读 `docs/PROXY_SETUP.md`

## 快速开始

推荐用法（一键用本配置打开任意项目）：
```bash
# 选择登录方式（console 推荐）
export CLAUDE_LOGIN_METHOD=console
export ANTHROPIC_API_KEY=sk-ant-...

# 在要作为项目的目录里运行，或指定路径/仓库（推荐已安装 devcontainer CLI）
scripts/open-here.sh                      # 用当前目录作为项目
# 或
scripts/open-project.sh /abs/path/to/project
# 或
scripts/open-project.sh https://github.com/owner/repo.git

# 正常情况下无需 Rebuild；脚本直接调用 devcontainer open
```

说明：
- 若 Dev Containers CLI 版本支持 `open`（较新版本），脚本将直接在容器中打开项目；
- 若不支持（如 0.80.x），脚本会写入临时的 `.devcontainer/devcontainer.local.json` 并提示你执行 “Reopen in Container”；
- 你也可以手动清理该覆盖：`scripts/clear-override.sh`。

进入容器后：
```bash
claude /help
/permissions   # 查看当前模式（应该显示 bypassPermissions）
```

### 验证清单
- `python3 --version`（预期 Ubuntu 24.04 为 3.12.x）
- `node -v`（LTS）/ `npm -v`
- `gh --version`
- `env | grep -i proxy`、`nc -vz host.docker.internal 1082`（如配置了代理）

## 环境变量配置

### 必需变量
| 变量 | 说明 | 示例 |
|------|------|------|
| `CLAUDE_LOGIN_METHOD` | 登录方式：`console`/`claudeai`/`apiKey` | `console` |
| `ANTHROPIC_API_KEY` | Anthropic API Key（用 apiKey 方式时） | `sk-ant-xxx...` |

注：也可用 VS Code 内置流程（无需脚本）：命令面板执行“Dev Containers: Open Folder in Container...”，选择“From a predefined container configuration”，把本仓库作为“配置文件夹”，你的项目目录作为“工作区文件夹”。

### 可选变量
| 变量 | 说明 | 示例 |
|------|------|------|
| `CLAUDE_ORG_UUID` | 强制使用指定组织 UUID | `org-xxx...` |
| `EXTRA_ALLOW_DOMAINS` | 防火墙额外白名单域名（空格分隔） | `"mycompany.com api.internal.net"` |
| `ALLOW_SSH_ANY` | 允许任意 SSH 连接（默认 `0`，仅允许 GitHub） | `1` |
| `ENABLE_CLAUDE_SANDBOX` | 启用 Claude Code 沙箱模式 | `1` |
| `CLAUDE_CODE_API_KEY_HELPER_TTL_MS` | API Key Helper 缓存时间（毫秒） | `300000` |
| `HOST_PROXY_URL` | 宿主机 HTTP/HTTPS 代理地址 | `http://host.docker.internal:7890` |
| `ALL_PROXY` | 宿主机 SOCKS 代理地址（可选） | `socks5h://host.docker.internal:1080` |
| `NO_PROXY` | 不走代理的地址列表（可选） | `localhost,127.0.0.1,.local` |

#### EXTRA_ALLOW_DOMAINS 使用示例
```bash
# 允许访问公司内部域名
export EXTRA_ALLOW_DOMAINS="gitlab.mycompany.com registry.internal.net"

# 防火墙将会额外放行这些域名的 HTTPS (443) 连接
```

## 模式切换（脚本与 JSON 两种）

- 用脚本：
  ```bash
  scripts/switch-mode.sh bypass      # 开启绕过（默认）
  scripts/switch-mode.sh safe        # 更安全（acceptEdits + 禁用绕过）
  scripts/switch-mode.sh custom ask  # 自定义模式字符串
  ```
- 手动 JSON：见 `MODE-SWITCH.md`。

## 防火墙白名单

容器启动时会应用默认拒绝的出站防火墙，仅允许以下域名的 HTTPS (443) 连接：

**默认白名单**：
- `registry.npmjs.org` / `npmjs.org` — npm 包管理
- `github.com` / `api.github.com` / `objects.githubusercontent.com` — GitHub 访问
- `claude.ai` / `api.anthropic.com` / `console.anthropic.com` — Claude Code 服务
- DNS 服务器（从 `/etc/resolv.conf` 读取）— UDP/TCP 53 端口
- GitHub SSH（22 端口，除非设置 `ALLOW_SSH_ANY=1`）

**扩展白名单**：使用 `EXTRA_ALLOW_DOMAINS` 环境变量添加额外域名。

**VPN/代理支持**：容器支持通过宿主机代理访问网络。详见 [VPN/代理配置指南](docs/PROXY_SETUP.md)。

网络/代理注意事项（摘要）：
- 在 macOS/Windows 下通过 `host.docker.internal` 访问宿主代理端口（示例：`HTTP_PROXY=http://host.docker.internal:1082`）
- 设置 `NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local`
- 受限网络下建议只走代理；如需更严格策略，可按需调整 `.devcontainer/init-firewall.sh`

### 严格只走代理（Strict Proxy Only）
- 行为：仅放行 DNS 与代理主机端口（例如 1082），不再放行任何域名直连（即便在白名单中）。所有外网访问都必须通过代理，否则会被阻断。
- 影响：GitHub/npm/Claude 也必须走代理；不读取代理的工具会失败，需要显式配置它们的代理。
- 启用方式：设置环境变量 `STRICT_PROXY_ONLY=1`，并重建/重启容器。
  - 在 `devcontainer.json`（容器环境）加入：
    ```json
    "containerEnv": { "STRICT_PROXY_ONLY": "1" }
    ```
  - 或在 VS Code 运行时设置（临时）：容器内 `export STRICT_PROXY_ONLY=1` 后重启 postStart（或重建）
  - 需要直连 SSH（22）时，请在严格模式下为 SSH 配置代理（ProxyCommand/ProxyJump/HTTPS ProxyCommand 等）

## 内置功能

### 预装插件
- `commit-commands` — 提交辅助命令
- `pr-review-toolkit` — PR 审查工具
- `security-guidance` — 安全指导

#### 插件故障排查（not found in marketplace）
- 现象：`/doctor` 显示例如 `Plugin commit-commands not found in marketplace claude-code-plugins`。
- 原因：插件“市场”源路径未正确解析，或网络无法拉取 GitHub 索引。
- 解决：
  - 已修正 bootstrap 的市场配置（指向 `anthropics/claude-code/plugins`）。在容器内执行：`bash .devcontainer/bootstrap-claude.sh` 以合并更新到 `~/.claude/settings.json`。
  - 验证：
    - `claude /plugins marketplaces` 应出现 `claude-code-plugins`
    - `claude /plugins search commit-commands` 能搜索到插件
    - 如仍失败，检查网络/代理能否访问 GitHub（见下方“防火墙白名单”和 `docs/PROXY_SETUP.md`）。

### 自定义命令和技能
- `/review-pr <PR编号>` — 分析 GitHub PR 并生成审查要点
- `reviewing-prs` skill — 专注于代码审查的 AI 技能

### 端口转发
默认转发以下端口到主机：`3000`, `5173`, `8000`, `9003`

### 预装工具
- **开发工具**：Node.js (LTS), Python（系统版本，Ubuntu 24.04 为 3.12），GitHub CLI
- **系统工具**：git, curl, jq, iptables, dnsutils, netcat

说明：使用系统 Python 可避免在受限网络下源码编译与 GPG 校验失败。如果必须固定到 3.11 等非系统版本，可在 `devcontainer.json` 中修改 Feature 配置，并确保为该 Feature 提供专用代理（或预配置 dirmngr）。

## 目录结构
- `.devcontainer/` — 容器定义
  - `Dockerfile` — 基础镜像和系统包
  - `devcontainer.json` — VS Code Dev Container 配置
  - `bootstrap-claude.sh` — Claude Code 安装和配置（postCreate）
  - `init-firewall.sh` — 防火墙初始化（postStart）
  - `setup-proxy.sh` — 代理配置脚本（可选执行）
- `scripts/` — 辅助脚本
  - `open-here.sh` — 使用 Dev Containers CLI 用本配置打开当前目录为工作区
  - `open-project.sh <路径|Git URL>` — 用本配置打开指定项目（支持 git URL）
  - `switch-mode.sh` — 权限模式切换
- `.claude/` — Claude Code 配置
  - `settings.local.json` — 项目级权限配置
- `docs/` — 文档目录
  - `PROXY_SETUP.md` — VPN/代理配置指南
- `README.md` / `MODE-SWITCH.md` — 主要文档

## 安全提醒
- **绕过模式**不会有人类确认，请**只在可信项目**使用
- 防火墙默认拒绝所有出站连接，仅白名单域名可访问
- 敏感文件受保护：`.env*`, `secrets/**`, `id_rsa`, `id_ed25519`
- 容器需要 `--cap-add=NET_ADMIN` 权限来管理 iptables 防火墙

如需切换到更安全的模式（非绕过），请参见 `MODE-SWITCH.md` 或运行 `scripts/switch-mode.sh safe`。

## 许可证
MIT License — 详见 `LICENSE` 文件
