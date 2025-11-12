# 迁移指南：v1.x → v2.0.0

> 从旧版本升级到 v2.0.0 的完整指南

---

## 概述

v2.0.0 是一个**重大简化版本**，解决了所有已知问题并大幅降低了复杂度。

**关键变更**：
- ✅ 移除了导致所有问题的 `workspaceMount` 和 `workspaceFolder`
- ✅ 简化脚本（减少 50%+ 复杂度）
- ✅ 统一为单一 `extends` 策略
- ✅ 新增清晰的快速开始指南

**升级影响**：
- 🟢 **无需修改项目代码**
- 🟡 **可能需要清理旧的本地覆盖文件**
- 🟡 **推荐更新项目级 devcontainer 配置**（可选）

---

## 快速升级步骤

### 步骤 1：更新 universal-devcontainer 仓库

```bash
cd /path/to/universal-devcontainer
git pull origin main
```

### 步骤 2：清理旧的本地覆盖文件（如果有）

**检查是否存在**：
```bash
ls -la .devcontainer/*.local.json
```

**删除旧文件**：
```bash
rm .devcontainer/devcontainer.local.json
```

**说明**：v2.0.0 不再需要本地覆盖文件，因为基础配置已经移除了 `workspaceMount`。

### 步骤 3：更新你的项目配置（推荐）

如果你的项目中有 `.devcontainer/devcontainer.json`，推荐更新为简化格式。

#### 旧格式（v1.x）
```json
{
  "name": "my-project",
  "extends": "file:../../universal-devcontainer/.devcontainer/devcontainer.json"
}
```

#### 新格式（v2.0.0 推荐）
```json
{
  "name": "my-project",
  "extends": "github:Joe-oss9527/universal-devcontainer"
}
```

**优点**：
- 无需关心相对路径
- 支持离线工作时自动缓存
- 更符合 Dev Containers 最佳实践

**如果离线环境**：可继续使用 `file:` 相对路径，但确保路径正确。

### 步骤 4：重建容器

```bash
# 在 VS Code 中
# 命令面板 → "Dev Containers: Rebuild Container"
```

### 步骤 5：验证

容器启动后，验证一切正常：

```bash
# 检查工作区路径
pwd
# 应该显示你的项目路径，例如 /workspaces/my-project

# 检查 Claude Code
claude /help

# 检查开发工具
node -v
python3 --version
gh --version
```

---

## 详细迁移场景

### 场景 1：你使用的是 UI 流程（无项目级配置）

**v1.x 行为**：
- 使用 "Open Folder in Container" → "From a local devcontainer.json"
- 有时会遇到工作区身份混淆

**v2.0.0 改进**：
- ✅ 相同的 UI 流程，但不再有工作区混淆问题
- ✅ 无需任何操作，直接使用即可

**迁移步骤**：
1. 更新 universal-devcontainer（`git pull`）
2. 继续使用相同的 UI 流程
3. 享受无问题的体验 🎉

---

### 场景 2：你使用的是项目级 extends 配置

**v1.x 配置**：
```json
{
  "name": "my-project",
  "extends": "file:../../universal-devcontainer/.devcontainer/devcontainer.json"
}
```

**v1.x 问题**：
- 有时会遇到 "missing image information" 提示
- 依赖相对路径（容易出错）

**v2.0.0 推荐配置**：
```json
{
  "name": "my-project",
  "extends": "github:Joe-oss9527/universal-devcontainer"
}
```

**迁移步骤**：
1. 编辑项目的 `.devcontainer/devcontainer.json`
2. 将 `extends` 改为 `github:owner/repo` 格式
3. Rebuild 容器
4. 验证工作正常

**如果你在离线环境**：
```json
{
  "name": "my-project",
  "extends": "file:../../universal-devcontainer/.devcontainer/devcontainer.json"
}
```
- 仍然可以工作，但确保相对路径正确
- v2.0.0 已修复与 `file:` 相关的冲突问题

---

### 场景 3：你使用的是 local override（devcontainer.local.json）

**v1.x 配置**：
```json
// .devcontainer/devcontainer.local.json
{
  "workspaceMount": "source=/abs/path/to/project,target=/workspaces/project,type=bind,consistency=cached",
  "workspaceFolder": "/workspaces/project"
}
```

**v1.x 问题**：
- 导致重复挂载错误
- 工作区身份混淆
- 需要手动管理路径

**v2.0.0 解决方案**：
- ✅ **完全不需要** local override 文件
- ✅ 基础配置已移除 workspace 属性，自动使用正确的工作区

**迁移步骤**：
1. 删除 `.devcontainer/devcontainer.local.json`
   ```bash
   rm .devcontainer/devcontainer.local.json
   ```
2. （可选）在项目中创建标准的 extends 配置（见场景 2）
3. Rebuild 容器
4. 验证工作区路径正确

---

### 场景 4：你使用的是脚本辅助（open-project.sh / open-here.sh）

**v1.x 行为**：
- 脚本会检测 CLI 版本
- 多重回退策略（CLI open → GitHub extends → file: extends）
- 使用 Python 计算相对路径

**v2.0.0 改进**：
- ✅ 简化为单一策略：生成 extends 配置
- ✅ 移除 Python 依赖（使用 bash `realpath`）
- ✅ 更清晰的用户提示

**迁移步骤**：
1. 更新脚本（`git pull`）
2. 继续使用相同的命令：
   ```bash
   scripts/open-project.sh /path/to/project
   scripts/open-here.sh
   ```
3. 脚本会自动使用新的简化逻辑

**脚本输出变化**：
```bash
# v1.x 输出
[universal-devcontainer] Config: /path/to/config.json
[universal-devcontainer] Workspace: /path/to/project
[universal-devcontainer] Dev Containers CLI 'open' not available. Using fallback...

# v2.0.0 输出
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Universal Dev Container - Project Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Project: my-project
  Path:    /path/to/project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Detected GitHub repository: owner/repo
✓ Created .devcontainer/devcontainer.json
  Strategy: extends github:owner/repo

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Next Steps:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. Opening project in VS Code...
  2. When prompted, click 'Reopen in Container'
  3. Wait for container to build (first time only)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 破坏性变更清单

### 配置文件

| 文件 | v1.x | v2.0.0 | 迁移操作 |
|------|------|--------|---------|
| `.devcontainer/devcontainer.json` | 包含 workspaceMount/workspaceFolder | 已移除这两个属性 | 无需操作（自动升级） |
| `.devcontainer/devcontainer.local.json` | 用于覆盖 workspace 配置 | 不再需要 | **删除此文件** |
| 项目级 `.devcontainer/devcontainer.json` | 使用 `file:` 相对路径 | 推荐使用 `github:` | 可选更新 |

### 脚本

| 脚本 | v1.x | v2.0.0 | 迁移操作 |
|------|------|--------|---------|
| `open-project.sh` | 80 行，CLI 检测 + Python | 84 行，纯 bash | 无需操作（兼容旧用法） |
| `open-here.sh` | 60 行，CLI 检测 + Python | 66 行，纯 bash | 无需操作（兼容旧用法） |

### 环境变量

无变更，所有环境变量保持兼容。

---

## 常见问题

### Q1: 升级后容器无法启动

**可能原因**：旧的 `.devcontainer/devcontainer.local.json` 仍然存在

**检查**：
```bash
ls -la /path/to/universal-devcontainer/.devcontainer/*.local.json
```

**解决**：
```bash
rm /path/to/universal-devcontainer/.devcontainer/devcontainer.local.json
```

### Q2: 工作区路径不正确

**症状**：容器中 `pwd` 显示的是 `/workspaces/universal-devcontainer` 而非你的项目路径

**可能原因**：
1. 使用了旧的 local override 文件
2. 项目级配置有误

**解决**：
1. 删除 local override：`rm .devcontainer/devcontainer.local.json`
2. 检查项目级配置的 `extends` 路径
3. Rebuild 容器

### Q3: extends 找不到配置文件（"missing image information"）

**v1.x 常见问题**，v2.0.0 已修复。

**如果仍遇到**：
1. 确保已更新 universal-devcontainer（`git pull`）
2. 推荐使用 `github:owner/repo` 而非 `file:` 路径
3. 检查网络连接（GitHub extends 需要网络）

### Q4: 脚本报错 "realpath: command not found"

**系统**：某些旧版 macOS 或精简 Linux

**解决**：
```bash
# macOS
brew install coreutils

# Ubuntu/Debian
sudo apt install coreutils

# 或使用 Python 替代（脚本内置检测）
# 无需手动处理
```

### Q5: 我想继续使用旧版本

**为什么不推荐**：
- v1.x 有多个已知问题（重复挂载、工作区混淆等）
- v2.0.0 已全部修复且向后兼容

**如果坚持使用 v1.x**：
```bash
git checkout <旧版本 commit hash>
```

**推荐的 v1.x 最后一个稳定版本**：
```bash
git checkout 1b0861e  # 最后一个 v1.x 版本
```

---

## 回滚指南

如果升级后遇到无法解决的问题，可以临时回滚：

### 临时回滚到 v1.x

```bash
cd /path/to/universal-devcontainer
git checkout 1b0861e  # v1.x 最后一个版本
```

### 恢复到 v2.0.0

```bash
git checkout main
```

### 报告问题

如果需要回滚，请在 GitHub 提交 issue，帮助我们改进 v2.0.0：

```
标题：[Migration Issue] 简述问题
内容：
- 从哪个版本升级：v1.x
- 遇到的问题：
- 环境信息：VS Code 版本、Docker 版本、操作系统
- 错误日志：
```

---

## 验证升级成功

升级完成后，运行以下检查清单：

### ✅ 基础检查

```bash
# 1. 检查配置仓库版本
cd /path/to/universal-devcontainer
git log -1 --oneline
# 应显示 v2.0.0 的 commit

# 2. 检查是否有旧的 override 文件
ls -la .devcontainer/*.local.json
# 应该显示 "No such file or directory"

# 3. 检查 .gitignore
cat .gitignore | grep local.json
# 应显示：.devcontainer/*.local.json
```

### ✅ 功能检查

```bash
# 1. 打开一个项目容器
scripts/open-project.sh /path/to/test/project

# 2. 容器启动后，验证工作区
pwd
# 应显示 /workspaces/test-project（项目名称）

# 3. 验证工具
node -v
python3 --version
claude /help

# 4. 验证防火墙
sudo iptables -L OUTPUT -n | grep DROP
# 应看到默认 DROP 规则
```

### ✅ 项目级配置检查

如果你的项目有 `.devcontainer/devcontainer.json`：

```bash
cat /path/to/your/project/.devcontainer/devcontainer.json
# 检查 extends 字段格式
```

推荐格式：
```json
{
  "name": "project-name",
  "extends": "github:Joe-oss9527/universal-devcontainer"
}
```

---

## 获取帮助

如果迁移过程中遇到问题：

1. **查阅文档**
   - [README.md](../README.md) — 快速开始指南
   - [DEVCONTAINERS_KNOWN_ISSUES.md](DEVCONTAINERS_KNOWN_ISSUES.md) — 已解决问题（历史记录）

2. **故障排查**
   - 检查 Docker 日志：VS Code → "Dev Containers: Show Container Log"
   - 检查配置解析：VS Code → "Dev Containers: Inspect Configuration"

3. **提交 Issue**
   - GitHub: https://github.com/Joe-oss9527/universal-devcontainer/issues
   - 提供详细的环境信息和错误日志

4. **社区讨论**
   - GitHub Discussions（如有）
   - 相关技术社区

---

## 总结

v2.0.0 升级步骤：

1. ✅ `git pull` 更新仓库
2. ✅ 删除 `.devcontainer/devcontainer.local.json`（如果有）
3. ✅ （可选）更新项目级配置为 `github:` extends
4. ✅ Rebuild 容器
5. ✅ 验证工作正常

**预期收益**：
- 🎉 所有已知问题已修复
- 🎉 更简单的使用流程
- 🎉 更清晰的文档
- 🎉 更少的代码和复杂度

欢迎使用 v2.0.0！如有问题，随时提交 issue。
