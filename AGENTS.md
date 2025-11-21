# Repository Guidelines

This repository provides a universal Dev Container for day‑to‑day development with Claude Code, outbound firewalling, and proxy support. Keep changes minimal, reproducible, and security‑conscious.

## Project Structure & Module Organization
- `.devcontainer/` — core container config (`devcontainer.json`, `Dockerfile`, `init-firewall.sh`, `bootstrap-claude.sh`, `setup-proxy.sh`)
- `scripts/` — host‑side helpers (e.g., `open-project.sh`)
- `docs/` — user documentation (e.g., `PROXY_SETUP.md`)

Container mount conventions:
- External project → `/workspace`
- This repo (tools/scripts) → `/universal`

## Build, Test, and Development Commands
- Open any project with this container:
  - `scripts/open-project.sh /path/to/your/project`
- Rebuild container (pick up image/config changes):
  - VS Code: “Dev Containers: Rebuild Without Cache”
- Validate networking inside container:
  - `sudo bash /universal/.devcontainer/init-firewall.sh` (reapply rules)
  - `bash /universal/.devcontainer/setup-proxy.sh` (configure package managers)

## Open Project Workflow & Troubleshooting
- Preferred: `scripts/open-project.sh /path/to/your/project` — launches a fresh VS Code instance (per‑project `--user-data-dir`) so the shell’s `PROJECT_PATH` is preserved. This avoids `code` forwarding to an existing VS Code process (which drops env) and fixes “Workspace does not exist”.
- Alternative: from a terminal (not Dock) `export PROJECT_PATH=/path/to/your/project && code /path/to/universal-devcontainer`.
- Mounts: repo → `/universal`, project → `/workspace`. Container scripts use absolute `/universal/...` paths; image guarantees `/workspace` exists.
- Preflight: host `initializeCommand` fails fast when `PROJECT_PATH` is missing/invalid. On macOS ensure Docker Desktop File Sharing includes the project’s parent (e.g., `/Users`).
- Quick checks: `echo $PROJECT_PATH`; `test -d "$PROJECT_PATH"`; inside container run the banner (opens on each terminal) or `grep ' /workspace ' /proc/mounts` to verify bind status; rebuild without cache after config changes.

## Coding Style & Naming Conventions
- Bash: `set -euo pipefail`, favor POSIX sh where practical, 2‑space indents, lower‑kebab script names.
- JSON: compact, stable key order, double quotes, no trailing commas.
- Docs: concise Markdown; prefer imperative voice and runnable snippets.

## Testing Guidelines
- Static checks (host): `jq empty .devcontainer/devcontainer.json`; `bash -n scripts/*.sh .devcontainer/*.sh`
- Optional: `shellcheck` for shell scripts if available.
- Runtime smoke tests (container):
  - Banner shows on terminal open with PROJECT_PATH and mount status.
  - `claude /help`, `node -v`, `python3 --version`, `gh --version` succeed.
  - `sudo iptables -S OUTPUT | head` lists rules; allowlisted domains resolve.

## Commit & Pull Request Guidelines
- Use Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `devcontainer:`, `firewall:`, `scripts:` (e.g., `feat(motd): show mount status`).
- PRs should include: motivation, before/after behavior, testing steps, and screenshots/logs for failures (especially container startup, firewall, proxy).
- Keep changes surgical; avoid unrelated refactors.

## Security & Configuration Tips
- Default mode favors convenience; do not broaden firewall domains without need.
- Strict proxy mode: `STRICT_PROXY_ONLY` now defaults to `1`, meaning all outbound traffic must go via the configured proxy. For temporary direct allowlists, set it to `0` on the host and rebuild.
- Claude credentials/config are imported from a read-only bind mount of the host `~/.claude` directory into the container’s `/home/vscode/.claude/settings.json`; `bootstrap-claude.sh` only writes to the container copy (e.g., bypassPermissions, plugins) and does not modify the host config.
- Never commit secrets; `.env*` and `secrets/**` must remain protected.
- macOS: ensure Docker Desktop File Sharing includes your project’s parent (e.g., `/Users`).
- If networking is restricted, set `HOST_PROXY_URL`/`ALL_PROXY` and rebuild.
