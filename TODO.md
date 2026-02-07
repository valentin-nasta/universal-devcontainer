# TODO — Future Optimization Plan

> v2.0.0 core features are complete. Below are future optimization directions.

---

## Priority Categories

- **High Priority** — Important and urgent
- **Medium Priority** — Important but not urgent
- **Low Priority** — Nice to have

---

## Medium Priority: Release & Distribution

### Publish as a Dev Container Template
**Goal**: Publish this configuration to the containers.dev official registry

**Benefits**:
- Users can discover and use it directly through the VS Code UI
- Better visibility and credibility
- Follows the officially recommended distribution method

**Steps**:
1. [ ] Research the [Dev Container Template specification](https://containers.dev/templates)
2. [ ] Create a `devcontainer-template.json` metadata file
3. [ ] Prepare examples and option configurations
4. [ ] Submit to the [devcontainers/templates](https://github.com/devcontainers/templates) repository
5. [ ] Or publish to your own OCI registry

**References**:
- https://containers.dev/templates
- https://github.com/devcontainers/template-starter

**Estimated effort**: 2-3 days

---

### Package Claude Code Settings as a Feature
**Goal**: Extract Claude Code installation and configuration into a standalone Dev Container Feature

**Benefits**:
- Greater reusability (other projects can reference it independently)
- More modular design
- Follows Dev Container ecosystem best practices
- Users can combine Features as needed

**Steps**:
1. [ ] Research the [Dev Container Features specification](https://containers.dev/features)
2. [ ] Create Feature directory structure:
   ```
   features/
   └── claude-code/
       ├── devcontainer-feature.json
       ├── install.sh
       └── README.md
   ```
3. [ ] Migrate `bootstrap-claude.sh` logic to the Feature
4. [ ] Support configurable options:
   - Claude login method
   - Permission mode (bypass/safe)
   - Pre-installed plugin list
5. [ ] Test Feature independence
6. [ ] Publish to Feature registry or OCI

**References**:
- https://containers.dev/implementors/features/
- https://github.com/devcontainers/feature-starter

**Estimated effort**: 3-5 days

---

### Consider Packaging Firewall Configuration as a Standalone Feature
**Goal**: Extract firewall setup into an optional Feature

**Benefits**:
- Users can choose whether to enable the firewall
- More flexible security policies
- Reduced main configuration complexity

**Steps**:
1. [ ] Create `features/firewall/` Feature
2. [ ] Support configuration options:
   - Allowlist domains
   - Strict proxy mode
   - SSH policy
3. [ ] Provide preset templates (permissive/standard/strict)
4. [ ] Test integration with the main configuration

**Estimated effort**: 2-3 days

---

## Medium Priority: CI/CD and Testing

### Add CI Tests to Validate Configuration
**Goal**: Automated testing to ensure the configuration always works

**Test scenarios**:
1. [ ] **JSON syntax validation**
   - `devcontainer.json` is properly formatted
   - All JSON files are parseable

2. [ ] **Configuration merge tests**
   - Test that the `extends` mechanism works correctly
   - Verify GitHub extends are accessible

3. [ ] **Container build tests**
   - Successfully build the container image
   - All Features install correctly
   - Development tools are available (Node.js, Python, GitHub CLI)

4. [ ] **Script tests**
   - Bash syntax checking
   - Script execution tests (simulated environment)
   - Error handling validation

5. [ ] **Claude Code integration tests**
   - Claude CLI is installed
   - Configuration files are correctly generated
   - Plugins are available

6. [ ] **Firewall tests**
   - iptables rules are correctly applied
   - Allowlisted domains are accessible
   - Non-allowlisted domains are blocked

**CI platform choice**:
- [ ] GitHub Actions (recommended)
- [ ] Or GitLab CI

**Workflow example**:
```yaml
name: Test Dev Container Config
on: [push, pull_request]

jobs:
  test-config:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate JSON
        run: |
          jq empty .devcontainer/devcontainer.json

      - name: Build Container
        uses: devcontainers/ci@v0.3
        with:
          configFile: .devcontainer/devcontainer.json
          runCmd: |
            node -v
            python3 --version
            gh --version

      - name: Test Scripts
        run: |
          bash -n scripts/*.sh
```

**Estimated effort**: 3-4 days

---

## Low Priority: Documentation and Examples

### Create Video Tutorials
**Goal**: Record quick-start video tutorials

**Content**:
- [ ] Demos of the 3 usage methods
- [ ] Common troubleshooting
- [ ] Proxy configuration demo

**Platforms**:
- YouTube / Bilibili
- Embed in README

**Estimated effort**: 1-2 days

---

### Add More Usage Examples
**Goal**: Provide example configurations for common frameworks

**Framework coverage**:
- [ ] React / Next.js
- [ ] Vue / Nuxt
- [ ] Node.js / Express
- [ ] Python / FastAPI / Django
- [ ] Go projects
- [ ] Rust projects

**Example structure**:
```
examples/
├── react-app/
│   └── .devcontainer/devcontainer.json
├── python-fastapi/
│   └── .devcontainer/devcontainer.json
└── nodejs-express/
    └── .devcontainer/devcontainer.json
```

**Estimated effort**: 2-3 days

---

## Low Priority: Feature Enhancements

### Support More Claude Code Modes
**Goal**: Provide more preset permission modes

**Modes**:
- [ ] `ultra-safe` — All operations require confirmation
- [ ] `dev` — Development mode (current bypass)
- [ ] `review` — Review mode (read-only + comments)
- [ ] `custom` — Custom mode generator

**Implementation**:
- Provide an interactive configuration wizard (directly edit `~/.claude/settings.json`)

**Estimated effort**: 1-2 days

---

### Add Project Template Generator
**Goal**: Quickly generate common project structures

**Features**:
```bash
scripts/create-project.sh my-app --template react-ts
# Auto-creates:
# - Project directory structure
# - .devcontainer/devcontainer.json
# - package.json / base files
# - Opens the container
```

**Estimated effort**: 2-3 days

---

### Support Multi-Container Configuration
**Goal**: Support frontend/backend separation, databases, and other multi-container scenarios

**Example**:
```yaml
# docker-compose.yml
services:
  app:
    # Main development container
  db:
    image: postgres:15
  redis:
    image: redis:7
```

**Estimated effort**: 3-4 days

---

## Low Priority: Performance Optimization

### Optimize Container Startup Speed
**Goal**: Reduce first-build time

**Approaches**:
- [ ] Use pre-built images (publish to Docker Hub / GHCR)
- [ ] Optimize Dockerfile layer caching
- [ ] Install tools on-demand (via Features)

**Expected improvement**:
- First build: 10 minutes -> 3 minutes
- Subsequent starts: 30 seconds -> 10 seconds

**Estimated effort**: 2-3 days

---

### Add Incremental Update Mechanism
**Goal**: Update configuration inside the container without rebuilding

**Features**:
```bash
# Run inside the container
update-config.sh
# Automatically pulls latest config, updates plugins, etc.
```

**Estimated effort**: 1-2 days

---

## High Priority: Security and Compliance

### Security Audit
**Goal**: Ensure the configuration follows security best practices

**Checklist**:
- [ ] Minimize container privileges (evaluate NET_ADMIN necessity)
- [ ] Sensitive file protection mechanisms
- [ ] Firewall rule review
- [ ] Dependency package security scanning

**Tools**:
- Trivy / Snyk
- Docker Bench for Security

**Estimated effort**: 2-3 days

---

### Add Compliance Configuration
**Goal**: Support enterprise compliance requirements

**Features**:
- [ ] GDPR data protection mode
- [ ] Audit logging
- [ ] Enterprise forced proxy mode
- [ ] Offline work mode

**Estimated effort**: 3-5 days

---

## Monitoring and Analytics

### Add Usage Analytics (Optional)
**Goal**: Understand usage patterns (privacy-friendly)

**Data collection** (anonymous, opt-out):
- [ ] Methods used (UI/extends/script)
- [ ] Common errors
- [ ] Feature usage frequency

**Privacy protection**:
- Fully anonymous
- Local-first
- Clear opt-out mechanism

**Estimated effort**: 2-3 days

---

## Internationalization

### Multi-language Documentation
**Goal**: Support English and Chinese documentation

**Scope**:
- [ ] README.md (English version)
- [ ] Script output internationalization

**Estimated effort**: 1-2 days

---

## Dependencies and Tools

### Add Common Tool Presets
**Goal**: Provide optional tool collection installations

**Tool sets**:
- [ ] `devtools` — Development tools (lazygit, httpie, jq)
- [ ] `database` — Database clients (pgcli, mycli, redis-cli)
- [ ] `cloud` — Cloud tools (aws-cli, gcloud, azure-cli)
- [ ] `kubernetes` — K8s tools (kubectl, helm, k9s)

**Implementation**:
- As optional Features
- Or controlled via environment variables

**Estimated effort**: 2-3 days

---

## Community and Ecosystem

### Build Community
**Goal**: Build a user and contributor community

**Platforms**:
- [ ] GitHub Discussions
- [ ] Discord / Slack channel
- [ ] Chinese tech communities (Juejin, SegmentFault)

**Estimated effort**: Ongoing

---

### Contributing Guidelines
**Goal**: Attract open-source contributions

**Documentation**:
- [ ] CONTRIBUTING.md
- [ ] CODE_OF_CONDUCT.md
- [ ] Issue/PR templates

**Estimated effort**: 1 day

---

## Milestone Roadmap

### v2.1.0 (Q1 2025)
- [ ] CI/CD testing
- [ ] Publish as Dev Container Template
- [ ] English documentation

### v2.2.0 (Q2 2025)
- [ ] Claude Code Feature
- [ ] Firewall Feature
- [ ] Performance optimization (pre-built images)

### v3.0.0 (Q3 2025)
- [ ] Multi-container support
- [ ] Project template generator
- [ ] Complete example library

---

## Ideas Collection

**Uncategorized ideas** (pending evaluation):
- [ ] VS Code extension (one-click setup)
- [ ] Web UI configuration generator
- [ ] Automated migration tool (migrate from other configs to this one)
- [ ] Integrate more AI tools (Copilot, Cursor, etc.)
- [ ] Support Codespaces and Gitpod

---

## Notes

**Recorded date**: 2025-01-11
**Version**: After v2.0.0 release

**Decision principles**:
1. **Simplicity first** — Maintain the current simplicity
2. **Modular** — New features should be optional
3. **Backwards compatible** — Avoid breaking changes
4. **Community-driven** — Adjust priorities based on user feedback

**Updating this document**:
- Check off [ ] when completing tasks
- Add new ideas to the corresponding section
- Periodically review priorities

---

## Related Resources

- [Dev Containers Specification](https://containers.dev/)
- [Features Development Guide](https://containers.dev/implementors/features/)
- [Templates Development Guide](https://containers.dev/templates)
- [Claude Code Documentation](https://code.claude.com/docs)
- [GitHub Actions Documentation](https://docs.github.com/actions)

---

**Contributing**: Feel free to discuss these optimization items in issues, or submit PRs to implement them!
