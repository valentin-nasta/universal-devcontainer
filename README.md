# Universal Dev Container — Claude Code Development Environment

> Reusable Dev Container configuration with integrated Claude Code, firewall, and proxy support.
> **bypassPermissions** is enabled by default — use only with **trusted repositories** in **isolated environments**.

## What Is This?

A pre-configured development container environment that includes:
- **Claude Code** — AI programming assistant (login and permissions pre-configured)
- **Development Tools** — Node.js (LTS), Python 3.12, GitHub CLI
- **Network Security** — Allowlist-based outbound firewall
- **Proxy Support** — VPN/corporate proxy pass-through
- **Reusable** — One configuration for all your projects

## Prerequisites

- VS Code >= 1.105 + Dev Containers extension >= 0.427
- Docker Desktop running
- (Optional) `npm i -g @devcontainers/cli` — for script-based workflows

**Restricted network / proxy environments**: Read the [Proxy Setup Guide](docs/PROXY_SETUP.md) first

---

## Quick Start

**Core concept**: This repository provides a reusable Dev Container configuration that dynamically mounts your project via `workspaceMount` and directly reuses the host machine's Claude login state.

### Method 1: Using the Script (Easiest)

```bash
# 1. Install and log in to Claude Code on the host (one-time setup)
npm i -g @anthropic-ai/claude-code
claude login

# 2. Open the container for any project
/path/to/universal-devcontainer/scripts/open-project.sh /path/to/your/project

# Or from the current directory
cd /path/to/your/project
/path/to/universal-devcontainer/scripts/open-project.sh .

# Or clone directly from a Git repository and start developing
/path/to/universal-devcontainer/scripts/open-project.sh https://github.com/owner/repo.git
```

**How it works**:
1. The script sets the `PROJECT_PATH` environment variable to point to your project
2. Opens the universal-devcontainer directory (not your project directory)
3. VS Code prompts "Reopen in Container"
4. After the container starts, your project is mounted at `/workspace`

### Method 2: Manually Set Environment Variables

If you prefer not to use the script:

```bash
# 1. Set the project path (required)
export PROJECT_PATH=/path/to/your/project

# 2. Ensure Claude Code is installed and logged in on the host (one-time setup)
npm i -g @anthropic-ai/claude-code
claude login

# 3. Open the universal-devcontainer directory in VS Code
code /path/to/universal-devcontainer

# 4. In VS Code: Dev Containers: Reopen in Container
```

### Method 3: Developing the Container Itself

If you want to develop universal-devcontainer itself inside the container, also provide `PROJECT_PATH` (or use the script):

```bash
# Option 1: Using the script (recommended)
/path/to/universal-devcontainer/scripts/open-project.sh /path/to/universal-devcontainer

# Option 2: Manually set the environment variable
export PROJECT_PATH=/path/to/universal-devcontainer
code /path/to/universal-devcontainer
# In VS Code: Dev Containers: Reopen in Container
```

Note: For compatibility and predictable behavior, this configuration uses "Plan A" — mounting only occurs when `PROJECT_PATH` is set.

Container path conventions:
- Your external project: `/workspace`
- This repository (tools and scripts): `/universal`

---

## Verify Installation

After the container starts, open a terminal to verify:

```bash
# Verify host login was automatically reused
claude /doctor

# Check Claude Code
claude /help
/permissions          # Should show bypassPermissions

# Check development tools
node -v               # LTS version
python3 --version     # 3.12.x (Ubuntu 24.04)
gh --version          # GitHub CLI

# Check proxy (if configured)
env | grep -i proxy
nc -vz host.docker.internal 1082  # Test host proxy connectivity
```

---

## Environment Variables

### Login and Organization Configuration (Optional)

By default, as long as you have run `claude login` on the host, the container will copy the login configuration from the host's `~/.claude/settings.json` to the container during initialization. Generally, **no additional environment variables are needed**.

To override the login method or use API Key mode, you can set:

| Variable | Description | Example |
|----------|-------------|---------|
| `CLAUDE_LOGIN_METHOD` | Login method: `console`/`claudeai`/`apiKey` | `console` |
| `ANTHROPIC_API_KEY` | API Key (required for `apiKey` method) | `sk-ant-xxx...` |

Set on the host (the container reads them automatically):

```bash
# Option 1: Environment variables
export CLAUDE_LOGIN_METHOD=console
export ANTHROPIC_API_KEY=sk-ant-...

# Option 2: VS Code settings.json
// ~/.config/Code/User/settings.json
{
  "dev.containers.defaultEnv": {
    "CLAUDE_LOGIN_METHOD": "console",
    "ANTHROPIC_API_KEY": "sk-ant-..."
  }
}
```

### Optional Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `CLAUDE_ORG_UUID` | Force a specific organization | - | `org-xxx...` |
| `HOST_PROXY_URL` | Host HTTP/HTTPS proxy | - | `http://host.docker.internal:7890` |
| `ALL_PROXY` | Host SOCKS proxy | - | `socks5h://host.docker.internal:1080` |
| `NO_PROXY` | Addresses that bypass the proxy | - | `localhost,127.0.0.1,.local` |
| `EXTRA_ALLOW_DOMAINS` | Additional firewall allowlist domains | - | `"gitlab.com myapi.com"` |
| `ALLOW_SSH_ANY` | Allow any SSH connections | `0` | `1` |
| `STRICT_PROXY_ONLY` | Proxy-only access (strict mode) | `1` | `0` |
| `ENABLE_CLAUDE_SANDBOX` | Claude sandbox mode | - | `1` |

**Detailed proxy configuration**: See [docs/PROXY_SETUP.md](docs/PROXY_SETUP.md)

## Security & Credential Sharing

This configuration shares host login information via **read-only mount + one-time copy**:

1. **No login required inside the container**: On first creation, the container reads the login configuration from the host's `~/.claude/settings.json` and copies it to `/home/vscode/.claude/settings.json` inside the container.
2. **Session expiry handling**: If you see a token expiry prompt, run `claude login` in the host terminal, then execute "Rebuild Without Cache" in VS Code to recreate the container with the latest login state.
3. **No write-back to host config**: The container's `bootstrap-claude.sh` only writes to the container's own `/home/vscode/.claude/settings.json` and never modifies the host's `~/.claude`, reducing the risk of accidental credential changes.

---

## Mode Switching

The default is **bypass mode** (no manual confirmation). For a more secure mode, manually edit `~/.claude/settings.json`:

```jsonc
{
  "permissions": {
    // More secure: requires confirmation for edits
    "defaultMode": "acceptEdits",
    // Optional: completely disable bypass mode (stricter enterprise policy)
    "disableBypassPermissionsMode": "disable"
  }
}
```

---

## Firewall Allowlist

The container **denies all outbound connections** by default, allowing only HTTPS (443) connections to the following domains:

**Base allowlist**:
- `registry.npmjs.org` / `npmjs.org` — npm packages
- `github.com` / `api.github.com` / `objects.githubusercontent.com` — GitHub
- `claude.ai` / `api.anthropic.com` / `console.anthropic.com` — Claude Code
- DNS servers (UDP/TCP 53)
- GitHub SSH (port 22, unless `ALLOW_SSH_ANY=1`)

**Extended allowlist**:

```bash
export EXTRA_ALLOW_DOMAINS="gitlab.mycompany.com registry.internal.net"
```

The firewall will additionally allow these domains.

**Strict proxy mode** (`STRICT_PROXY_ONLY=1`):
- Only allows DNS and proxy ports
- All external access must go through the proxy
- Suitable for restricted networks with high security requirements

---

## Built-in Features

### Pre-installed Plugins
- `commit-commands` — Commit helpers
- `pr-review-toolkit` — PR review
- `security-guidance` — Security guidance

**Plugin troubleshooting**: If `/doctor` shows plugins "not found in marketplace":

```bash
# Re-run the bootstrap script
bash .devcontainer/bootstrap-claude.sh

# Verify
claude /plugins marketplaces        # Should show claude-code-plugins
claude /plugins search commit-commands
```

### Custom Commands and Skills
- `/review-pr <PR-number>` — Analyze a GitHub PR
- `reviewing-prs` skill — Code review AI skill

### Port Forwarding
Default forwarded ports: `3000`, `5173`, `8000`, `9003`

### Pre-installed Tools
- **Development tools**: Node.js (LTS), Python 3.12, GitHub CLI
- **System tools**: git, curl, jq, iptables, dnsutils, netcat

---

## Directory Structure

```
universal-devcontainer/
├── .devcontainer/
│   ├── devcontainer.json       # Main config (mounts /workspace and /universal via binds)
│   ├── Dockerfile              # Base image
│   ├── bootstrap-claude.sh     # Claude Code setup
│   ├── init-firewall.sh        # Firewall rules
│   └── setup-proxy.sh          # Proxy configuration
├── scripts/
│   └── open-project.sh         # Mount external project into container (sets PROJECT_PATH)
├── .claude/
│   └── settings.local.json     # Project-level permission configuration
└── docs/
    └── PROXY_SETUP.md          # Detailed proxy setup guide
```

---

## Troubleshooting

### Login Troubleshooting (Browser Authorization / localhost Callback)
- Symptom: Clicking Authorize on the authorization page keeps spinning.
- Quick checks:
  - VS Code left panel "PORTS" tab — check if a container port (e.g., 41521) appears, mapped to `localhost:<same-port>`.
  - Directly access `http://127.0.0.1:<port>/` from the host browser or terminal — should return 404 (meaning the callback server is alive).
  - Host proxy bypass must include: `localhost, 127.0.0.1, ::1, host.docker.internal` (to avoid proxy/IPv6 interference).
- Detailed steps and common proxy examples (Shadowrocket/Clash/Surge/SwitchyOmega/PAC): See the "Host-side Bypass (localhost Callback - Must Read)" section in docs/PROXY_SETUP.md.

### Quick Fix: Opening a Project ("Workspace does not exist")
- Recommended launch method: `scripts/open-project.sh /path/to/your/project` (opens a separate VS Code process per project, ensuring `PROJECT_PATH` is inherited).
- Manual method: From a terminal, run `export PROJECT_PATH=/path/to/your/project && code /path/to/universal-devcontainer` (do not launch VS Code from the Dock).
- After changes, rebuild: VS Code -> "Dev Containers: Rebuild Without Cache".
- macOS path sharing: Docker Desktop -> Settings -> Resources -> File Sharing must include the project's parent directory (e.g., `/Users`).
- Quick checks:
  - Host: `echo $PROJECT_PATH`, `test -d "$PROJECT_PATH" && echo OK || echo MISSING`
  - Inside container: Check the startup banner (MOTD) or `grep ' /workspace ' /proc/mounts` to verify the mount; script paths are at `/universal/.devcontainer/...`.

### Problem: Container Cannot Access the Internet

**Checklist**:
1. Is the firewall blocking a domain you need? -> Add it to `EXTRA_ALLOW_DOMAINS`
2. Are you on a restricted network? -> Configure `HOST_PROXY_URL`, see [docs/PROXY_SETUP.md](docs/PROXY_SETUP.md)
3. Docker file sharing permissions (macOS): Docker Desktop -> Resources -> File Sharing must include `/Users`

### Problem: Claude Code Plugins Not Found

```bash
# Check marketplace configuration
claude /plugins marketplaces

# Re-run bootstrap
bash .devcontainer/bootstrap-claude.sh

# Check network
curl -I https://api.github.com
```

### Problem: Path Permission Errors (macOS/Linux)

```bash
# Ensure parent directories are traversable
chmod o+rx /Users/<username>
chmod o+rx /Users/<username>/developer
chmod o+rx /Users/<username>/developer/<project>
```

### Problem: extends Cannot Find Configuration File

**Symptom**: Error "missing image information"

**Solutions**:
- **Option 1**: Use `github:owner/repo` instead of `file:relative-path`
- **Option 2**: Verify the relative path is correct (from project root to config file)
- **Option 3**: Use Method 1 (VS Code UI flow), which doesn't require extends

### Problem: Authorization Page Keeps Spinning (OAuth localhost Callback)

**Symptom**: Opening `https://claude.ai/oauth/authorize?...redirect_uri=http://localhost:<random-port>/callback` and clicking Authorize results in the page loading indefinitely.

**Root cause**: The callback server listens on `127.0.0.1:<random-port>` inside the container, while the browser on the host accesses `localhost:<random-port>`. Without port forwarding, the host's loopback cannot reach the container, and the callback request fails.

**Solutions**:
- Built-in: `devcontainer.json` enables dynamic port auto-forwarding (`portsAttributes.otherPortsAttributes` + `remote.autoForwardPorts=true`). When a callback port starts listening, VS Code automatically forwards the container port to the same host port; typically no manual action is needed.
- If it still fails:
  - Note the port number in the authorization URL (e.g., `63497`), then manually forward that port in the VS Code "PORTS" panel.
  - Or, inside the container, verify the listener with `ss -lntp | grep <port>` before forwarding.
  - Workaround: Set `CLAUDE_LOGIN_METHOD=console` and provide `ANTHROPIC_API_KEY` to use console/API Key login, bypassing the browser callback.

---

## Security Notice

- **Bypass mode** has no manual confirmation — use only with **trusted projects**
- The firewall denies all outbound connections by default; only allowlisted domains are accessible
- Sensitive files are protected: `.env*`, `secrets/**`, `id_rsa`, `id_ed25519`
- The container requires `--cap-add=NET_ADMIN` for firewall management

For a more secure mode: follow the configuration examples above.

---

## Common Use Cases

### Scenario 1: Quick Trial (Temporary Project)
-> Use **Method 1** (UI flow), no files to create

### Scenario 2: Team Collaboration Project
-> Use **Method 2** (project config), commit `.devcontainer/devcontainer.json` to the repository

### Scenario 3: Multiple Personal Projects
-> Use **Method 3** (script-based), quickly generate config for each project

### Scenario 4: Enterprise Restricted Network
-> Configure proxy first (see [docs/PROXY_SETUP.md](docs/PROXY_SETUP.md)), then use any method

---

## Changelog

### v2.0.0 (Simplified Version) — 2025-01

**Breaking changes** (improved usability):
- Use **workspaceMount** for dynamic project mounting (no longer depends on extends)
- Simplified script logic (from 71 lines down to 65 lines)
- Removed all unstable extends-related code
- One container serves all projects

---

## References

- [VS Code Dev Containers Official Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [Dev Container Specification](https://containers.dev/)
- [Claude Code Documentation](https://code.claude.com/docs)

## License

MIT License — See the `LICENSE` file for details

### Problem: "Workspace does not exist" on Startup

**Cause**: The host VS Code process did not inherit `PROJECT_PATH`, or Docker Desktop has not shared the path, causing the `/workspace` mount to fail.

**Solutions**:
- Recommended: Use the script to launch: `scripts/open-project.sh <your-project-path>` (the script starts an independent VS Code instance that inherits environment variables).
- Or configure in VS Code user settings:
  ```jsonc
  {
    "dev.containers.defaultEnv": { "PROJECT_PATH": "/path/to/your/project" }
  }
  ```
- macOS: Docker Desktop -> Settings -> Resources -> File Sharing, ensure it includes `/Users` or your project's parent directory.
- If it still fails, verify first: `echo $PROJECT_PATH && test -d "$PROJECT_PATH" && echo OK || echo MISSING`.
