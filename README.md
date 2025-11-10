# Universal Dev Container (v2-bypass) — **Bypass Mode Default**

> 这一版默认启用 **bypassPermissions**（绕过权限确认）。仅在**可信仓库**和**隔离环境**使用（本模板自带默认拒绝出网的白名单防火墙）。

## 快速开始

```bash
# 选择登录方式（console 推荐）
export CLAUDE_LOGIN_METHOD=console
export ANTHROPIC_API_KEY=sk-ant-...

# 指定你的项目
export PROJECT_DIR=/abs/path/to/project
export PROJECT_NAME=$(basename "$PROJECT_DIR")

# 打开此仓库并 Reopen in Container
code /abs/path/to/universal-devcontainer-v2-bypass
```

进入容器后：
```bash
claude /help
/permissions   # 查看当前模式（应该显示 bypassPermissions）
```

## 模式切换（脚本与 JSON 两种）

- 用脚本：
  ```bash
  scripts/switch-mode.sh bypass      # 开启绕过（默认）
  scripts/switch-mode.sh safe        # 更安全（acceptEdits + 禁用绕过）
  scripts/switch-mode.sh custom ask  # 自定义模式字符串
  ```
- 手动 JSON：见 `MODE-SWITCH.md`。

## 目录
- `.devcontainer/`：容器定义（postCreate 安装/配置 Claude；postStart 每次重放防火墙）
- `scripts/open-here.sh` / `open-project.sh`：一键打开容器开发
- `scripts/switch-mode.sh`：快速切换权限模式
- `README.md`、`MODE-SWITCH.md`：指南

## 安全提醒
- **绕过模式**不会有人类确认，请**只在可信项目**使用。
- 防火墙白名单可用 `EXTRA_ALLOW_DOMAINS` 扩展公司域名；默认允许 npm/GitHub/Anthropic/DNS/SSH(GitHub)。

