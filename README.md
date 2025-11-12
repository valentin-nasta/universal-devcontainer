# Universal Dev Container — Claude Code 开发环境

> 可复用的 Dev Container 配置，集成 Claude Code、防火墙和代理支持。
> 默认启用 **bypassPermissions**（绕过权限确认）— 仅用于**可信仓库**和**隔离环境**。

## 这是什么？

这是一个预配置的开发容器环境，包含：
- ✅ **Claude Code** — AI 编程助手（已配置登录和权限）
- ✅ **开发工具** — Node.js (LTS)、Python 3.12、GitHub CLI
- ✅ **网络安全** — 基于白名单的出站防火墙
- ✅ **代理支持** — VPN/企业代理透传
- ✅ **可复用** — 一份配置，用于所有项目

## 先决条件

- VS Code ≥ 1.105 + Dev Containers 扩展 ≥ 0.427
- Docker Desktop 已启动
- （可选）`npm i -g @devcontainers/cli` — 用于脚本辅助

**受限网络/代理环境**：先阅读 [代理配置指南](docs/PROXY_SETUP.md)

---

## 快速开始 🚀

**选择以下任一方法**（从简单到高级）：

### 方法 1：VS Code UI 流程（推荐新手）

**零文件创建，纯 UI 操作**

1. 打开 VS Code
2. 命令面板（Cmd/Ctrl+Shift+P）→ `Dev Containers: Open Folder in Container`
3. 选择你的项目文件夹
4. 选择 **"From a local devcontainer.json"**
5. 导航到 `universal-devcontainer/.devcontainer/devcontainer.json`
6. 等待容器启动完成 ✅

### 方法 2：项目配置文件（推荐多项目使用）

**在项目中创建 1 个最小文件**

在你的项目根目录创建 `.devcontainer/devcontainer.json`：

```json
{
  "name": "my-project",
  "extends": "github:Joe-oss9527/universal-devcontainer"
}
```

然后：
- 命令面板 → `Dev Containers: Reopen in Container`
- 或直接用 VS Code 打开项目文件夹，会自动提示重新打开

**优点**：
- 项目可以提交这个文件（团队共享配置）
- 无需网络时可用 `file:相对路径` 替代 `github:`
- 支持项目级自定义（覆盖端口、环境变量等）

### 方法 3：脚本辅助工具

**一键生成配置并打开**

```bash
# 设置 Claude 登录方式
export CLAUDE_LOGIN_METHOD=console
export ANTHROPIC_API_KEY=sk-ant-...  # 或用其他登录方式

# 在当前目录创建配置
cd /path/to/your/project
/path/to/universal-devcontainer/scripts/open-here.sh

# 或指定项目路径
/path/to/universal-devcontainer/scripts/open-project.sh /path/to/your/project

# 或直接从 Git 仓库
/path/to/universal-devcontainer/scripts/open-project.sh https://github.com/owner/repo.git
```

脚本会：
1. 自动创建最小的 `.devcontainer/devcontainer.json`（方法 2 的配置）
2. 打开 VS Code
3. 提示你点击"Reopen in Container"

---

## 验证安装

容器启动后，打开终端验证：

```bash
# 检查 Claude Code
claude /help
/permissions          # 应显示 bypassPermissions

# 检查开发工具
node -v               # LTS 版本
python3 --version     # 3.12.x (Ubuntu 24.04)
gh --version          # GitHub CLI

# 检查代理（如已配置）
env | grep -i proxy
nc -vz host.docker.internal 1082  # 测试宿主代理连通性
```

---

## 环境变量配置

### 必需变量（登录 Claude）

| 变量 | 说明 | 示例 |
|------|------|------|
| `CLAUDE_LOGIN_METHOD` | 登录方式：`console`/`claudeai`/`apiKey` | `console` |
| `ANTHROPIC_API_KEY` | API Key（用 `apiKey` 方式时） | `sk-ant-xxx...` |

在宿主机设置（容器会自动读取）：

```bash
# 方式 1：环境变量
export CLAUDE_LOGIN_METHOD=console
export ANTHROPIC_API_KEY=sk-ant-...

# 方式 2：VS Code settings.json
// ~/.config/Code/User/settings.json
{
  "dev.containers.defaultEnv": {
    "CLAUDE_LOGIN_METHOD": "console",
    "ANTHROPIC_API_KEY": "sk-ant-..."
  }
}
```

### 可选变量

| 变量 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `CLAUDE_ORG_UUID` | 强制使用指定组织 | - | `org-xxx...` |
| `HOST_PROXY_URL` | 宿主机 HTTP/HTTPS 代理 | - | `http://host.docker.internal:7890` |
| `ALL_PROXY` | 宿主机 SOCKS 代理 | - | `socks5h://host.docker.internal:1080` |
| `NO_PROXY` | 不走代理的地址 | - | `localhost,127.0.0.1,.local` |
| `EXTRA_ALLOW_DOMAINS` | 防火墙额外白名单 | - | `"gitlab.com myapi.com"` |
| `ALLOW_SSH_ANY` | 允许任意 SSH 连接 | `0` | `1` |
| `STRICT_PROXY_ONLY` | 仅允许代理访问 | `0` | `1` |
| `ENABLE_CLAUDE_SANDBOX` | Claude 沙箱模式 | - | `1` |

**代理配置详细说明**：见 [docs/PROXY_SETUP.md](docs/PROXY_SETUP.md)

---

## 模式切换

默认使用 **bypass 模式**（无人工确认）。如需更安全的模式：

```bash
# 在容器内执行
scripts/switch-mode.sh bypass      # 绕过模式（默认）
scripts/switch-mode.sh safe        # 安全模式（acceptEdits + 禁用绕过）
scripts/switch-mode.sh custom ask  # 自定义模式
```

或手动编辑 `.claude/settings.local.json`，详见 `MODE-SWITCH.md`。

---

## 防火墙白名单

容器默认**拒绝所有出站连接**，仅允许以下域名的 HTTPS (443) 连接：

**基础白名单**：
- `registry.npmjs.org` / `npmjs.org` — npm 包管理
- `github.com` / `api.github.com` / `objects.githubusercontent.com` — GitHub
- `claude.ai` / `api.anthropic.com` / `console.anthropic.com` — Claude Code
- DNS 服务器（UDP/TCP 53）
- GitHub SSH（22 端口，除非 `ALLOW_SSH_ANY=1`）

**扩展白名单**：

```bash
export EXTRA_ALLOW_DOMAINS="gitlab.mycompany.com registry.internal.net"
```

防火墙会额外放行这些域名。

**严格代理模式**（`STRICT_PROXY_ONLY=1`）：
- 仅放行 DNS 和代理端口
- 所有外网访问必须走代理
- 适用于高安全要求的受限网络

---

## 内置功能

### 预装插件
- `commit-commands` — 提交辅助
- `pr-review-toolkit` — PR 审查
- `security-guidance` — 安全指导

**插件故障排查**：如果 `/doctor` 显示插件 "not found in marketplace"：

```bash
# 重新运行 bootstrap 脚本
bash .devcontainer/bootstrap-claude.sh

# 验证
claude /plugins marketplaces        # 应显示 claude-code-plugins
claude /plugins search commit-commands
```

### 自定义命令和技能
- `/review-pr <PR编号>` — 分析 GitHub PR
- `reviewing-prs` skill — 代码审查 AI 技能

### 端口转发
默认转发：`3000`, `5173`, `8000`, `9003`

### 预装工具
- **开发工具**：Node.js (LTS), Python 3.12, GitHub CLI
- **系统工具**：git, curl, jq, iptables, dnsutils, netcat

---

## 目录结构

```
universal-devcontainer/
├── .devcontainer/
│   ├── devcontainer.json       # 主配置（已简化，无 workspaceMount）
│   ├── Dockerfile              # 基础镜像
│   ├── bootstrap-claude.sh     # Claude Code 安装
│   ├── init-firewall.sh        # 防火墙规则
│   └── setup-proxy.sh          # 代理配置
├── scripts/
│   ├── open-here.sh            # 在当前目录创建配置
│   ├── open-project.sh         # 为指定项目创建配置
│   └── switch-mode.sh          # 权限模式切换
├── .claude/
│   └── settings.local.json     # 项目级权限配置
└── docs/
    ├── PROXY_SETUP.md          # 代理配置详细指南
    ├── DEVCONTAINERS_KNOWN_ISSUES.md  # 已知问题和解决方案
    └── MIGRATION.md            # 升级指南（针对旧版本用户）
```

---

## 故障排查

### 问题：容器无法访问外网

**检查项**：
1. 防火墙是否阻止了你需要的域名？→ 添加到 `EXTRA_ALLOW_DOMAINS`
2. 是否在受限网络？→ 配置 `HOST_PROXY_URL`，见 [docs/PROXY_SETUP.md](docs/PROXY_SETUP.md)
3. Docker 文件共享权限（macOS）：Docker Desktop → Resources → File Sharing 包含 `/Users`

### 问题：Claude Code 插件找不到

```bash
# 检查市场配置
claude /plugins marketplaces

# 重新 bootstrap
bash .devcontainer/bootstrap-claude.sh

# 检查网络
curl -I https://api.github.com
```

### 问题：路径权限错误（macOS/Linux）

```bash
# 确保父目录可遍历
chmod o+rx /Users/<username>
chmod o+rx /Users/<username>/developer
chmod o+rx /Users/<username>/developer/<project>
```

### 问题：extends 找不到配置文件

**现象**：提示 "missing image information"

**解决**：
- **方法 1**：使用 `github:owner/repo` 而非 `file:相对路径`
- **方法 2**：检查相对路径是否正确（从项目根目录到配置文件的路径）
- **方法 3**：使用方法 1（VS Code UI 流程），无需 extends

---

## 安全提醒 ⚠️

- **绕过模式**不会有人工确认，请**只在可信项目**使用
- 防火墙默认拒绝所有出站连接，仅白名单域名可访问
- 敏感文件受保护：`.env*`, `secrets/**`, `id_rsa`, `id_ed25519`
- 容器需要 `--cap-add=NET_ADMIN` 权限来管理防火墙

如需更安全的模式：
```bash
scripts/switch-mode.sh safe
```

---

## 常见使用场景

### 场景 1：快速试用（临时项目）
→ 使用**方法 1**（UI 流程），无需创建任何文件

### 场景 2：团队协作项目
→ 使用**方法 2**（项目配置），提交 `.devcontainer/devcontainer.json` 到代码库

### 场景 3：多个个人项目
→ 使用**方法 3**（脚本辅助），快速为每个项目生成配置

### 场景 4：企业受限网络
→ 先配置代理（见 [docs/PROXY_SETUP.md](docs/PROXY_SETUP.md)），然后使用任一方法

---

## 更新日志

### v2.0.0（简化版本）— 2025-01

**重大变更**（提升易用性）：
- ✅ **移除** `workspaceMount` 和 `workspaceFolder`（修复所有已知问题）
- ✅ **简化**脚本逻辑（减少 50%+ 复杂度，移除 Python 依赖）
- ✅ **重构**文档（新增快速开始指南）
- ✅ **统一**策略（extends 作为唯一推荐方法）

**升级指南**：见 [docs/MIGRATION.md](docs/MIGRATION.md)

---

## 参考资料

- [VS Code Dev Containers 官方文档](https://code.visualstudio.com/docs/devcontainers/containers)
- [Dev Container 规范](https://containers.dev/)
- [Claude Code 文档](https://code.claude.com/docs)

## 许可证

MIT License — 详见 `LICENSE` 文件
