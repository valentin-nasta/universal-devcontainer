# Dev Container VPN/代理配置指南

## 概述

本指南介绍如何配置 Dev Container 使用宿主机的 VPN 或代理服务。这对于需要通过公司 VPN 或代理访问网络资源的场景非常有用。

## 方案说明

我们采用 **方案 A（推荐，跨平台）**：将宿主机代理作为 HTTP(S)/SOCKS 代理透传给容器。

### 工作原理

1. 宿主机运行代理客户端（如 Clash、V2Ray、Surge 等）
2. 通过 `host.docker.internal` 别名让容器访问宿主机
3. 容器内的应用通过代理环境变量连接到宿主机代理
4. 防火墙自动放行代理端口，允许容器访问代理服务

### 平台支持

- **macOS / Windows (Docker Desktop)**: `host.docker.internal` 默认可用
- **Linux (Docker Engine ≥ 20.10)**: 需要通过 `--add-host=host.docker.internal:host-gateway` 映射

## 快速开始

### 步骤 1: 在宿主机配置代理环境变量

在宿主机（**非容器内**）的终端或 shell 配置文件中设置以下环境变量：

```bash
# HTTP/HTTPS 代理（常见端口：7890、8080、8888）
export HOST_PROXY_URL=http://host.docker.internal:7890

# SOCKS 代理（可选，常见端口：1080）
export ALL_PROXY=socks5h://host.docker.internal:1080

# NO_PROXY：不走代理的地址（可选）
export NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local
```

**注意**：
- 端口号（如 `7890`）应替换为你的代理软件实际监听的端口
- 常见代理软件端口：
  - Clash: HTTP 7890, SOCKS 7891
  - V2Ray: HTTP/SOCKS 1080
  - Surge: HTTP 6152, SOCKS 6153
  - Shadowsocks: SOCKS 1080

**推荐做法**：将这些环境变量添加到你的 shell 配置文件中（如 `~/.zshrc` 或 `~/.bashrc`），这样每次启动终端都会自动设置：

```bash
# 添加到 ~/.zshrc 或 ~/.bashrc
echo 'export HOST_PROXY_URL=http://host.docker.internal:7890' >> ~/.zshrc
echo 'export ALL_PROXY=socks5h://host.docker.internal:1080' >> ~/.zshrc
echo 'export NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local' >> ~/.zshrc

# 重新加载配置
source ~/.zshrc
```

### 步骤 2: 启动 Dev Container

环境变量配置好后，直接在 VS Code 中重新构建并启动 Dev Container：

1. 打开 VS Code 命令面板（Cmd/Ctrl + Shift + P）
2. 执行命令：`Dev Containers: Rebuild Container`

容器启动后，代理配置会自动生效。

### 步骤 3: （可选）配置包管理器代理

如果你希望 apt、npm、pip、git 等工具也使用代理，在容器内执行：

```bash
bash .devcontainer/setup-proxy.sh
```

这个脚本会自动配置以下工具的代理设置：
- APT (Debian/Ubuntu 包管理器)
- npm / yarn
- pip (Python 包管理器)
- git
- wget

### 步骤 4: 验证代理配置

在容器内执行以下命令验证代理是否工作：

```bash
# 1. 检查环境变量
env | grep -i proxy

# 2. 测试代理端口连接
nc -vz host.docker.internal 7890

# 3. 测试实际网络访问（如果你的代理允许访问 Google）
curl -I https://www.google.com

# 4. 查看防火墙规则（应该看到代理端口被允许）
sudo iptables -S OUTPUT | grep -i proxy
```

## 配置详解

### devcontainer.json 配置

```json
{
  "build": {
    "dockerfile": "Dockerfile",
    "args": {
      "HTTP_PROXY": "${localEnv:HOST_PROXY_URL}",
      "HTTPS_PROXY": "${localEnv:HOST_PROXY_URL}",
      "NO_PROXY": "${localEnv:NO_PROXY}"
    }
  },
  "runArgs": [
    "--cap-add=NET_ADMIN",
    "--add-host=host.docker.internal:host-gateway"
  ],
  "remoteEnv": {
    "HTTP_PROXY": "${localEnv:HOST_PROXY_URL}",
    "HTTPS_PROXY": "${localEnv:HOST_PROXY_URL}",
    "ALL_PROXY": "${localEnv:ALL_PROXY}",
    "NO_PROXY": "${localEnv:NO_PROXY}"
  },
  "containerEnv": {
    "HTTP_PROXY": "${localEnv:HOST_PROXY_URL}",
    "HTTPS_PROXY": "${localEnv:HOST_PROXY_URL}",
    "ALL_PROXY": "${localEnv:ALL_PROXY}",
    "NO_PROXY": "${localEnv:NO_PROXY}"
  }
}
```

**配置说明**：
- **`build.args`**: **[新增]** 传递代理配置到 Docker 构建阶段，用于安装 features（Python、Node、GitHub CLI 等）时的网络访问
- `--add-host=host.docker.internal:host-gateway`: 让 Linux 系统也能使用 `host.docker.internal`
- `${localEnv:HOST_PROXY_URL}`: 从宿主机环境变量读取代理 URL
- `remoteEnv`: 为 VS Code 及其子进程（终端、任务等）设置环境变量
- `containerEnv`: 为整个容器进程环境设置环境变量

### 防火墙自动放行

`init-firewall.sh` 会自动解析代理环境变量，并将代理主机和端口加入白名单：

```bash
allow_proxy_from_env() {
  # 从 HTTP(S)_PROXY 或 ALL_PROXY 提取代理地址
  PROXY_RAW="${HTTP_PROXY:-${HTTPS_PROXY:-${ALL_PROXY:-}}}"
  # 解析主机和端口
  # 将代理 IP 和端口加入 iptables 白名单
}
```

这样即使防火墙默认拒绝出站连接，容器也能访问代理服务。

## 常见问题

### Q1: 我的代理软件应该如何配置？

**关键设置**：
1. **允许来自局域网的连接**：大多数代理软件默认只监听 `127.0.0.1`，需要改为监听 `0.0.0.0` 或允许局域网连接
2. **记住端口号**：记下 HTTP 和 SOCKS 代理的端口号，用于设置环境变量

**常见代理软件配置**：

- **Clash**: 在配置文件中设置 `allow-lan: true`
- **V2Ray**: 在 Inbounds 中设置监听地址为 `0.0.0.0`
- **Surge**: 在 "代理设置" 中勾选 "允许来自局域网的连接"

### Q2: 容器无法连接到代理怎么办？

**诊断步骤**：

```bash
# 1. 检查宿主机环境变量是否正确设置
echo $HOST_PROXY_URL

# 2. 在容器内检查环境变量是否传入
env | grep -i proxy

# 3. 测试 host.docker.internal 是否可达
ping -c 3 host.docker.internal

# 4. 测试代理端口是否开放
nc -vz host.docker.internal 7890

# 5. 检查防火墙规则
sudo iptables -S OUTPUT
```

**常见原因**：
- 宿主机代理软件未运行或端口配置错误
- 代理软件未开启 "允许局域网连接"
- 端口号设置错误
- Linux 系统未正确映射 `host.docker.internal`

### Q3: apt 不支持 SOCKS 代理怎么办？

APT 只支持 HTTP/HTTPS 代理。如果你的 VPN 只提供 SOCKS 代理，有两个解决方案：

1. **推荐**：配置代理软件同时开启 HTTP 和 SOCKS 端口
2. 使用 `proxychains` 或 `redsocks` 进行协议转换

### Q4: 某些域名不应该走代理怎么办？

使用 `NO_PROXY` 环境变量：

```bash
export NO_PROXY=localhost,127.0.0.1,.example.com,.internal
```

- 支持通配符域名（如 `.example.com` 匹配所有子域名）
- 多个条目用逗号分隔
- 不要添加协议前缀

### Q5: 如何临时禁用代理？

**方法 1**：在宿主机取消设置环境变量后重建容器

```bash
unset HOST_PROXY_URL
unset ALL_PROXY
# 然后在 VS Code 中执行 "Rebuild Container"
```

**方法 2**：在容器内临时取消环境变量

```bash
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
```

注意：方法 2 只对当前 shell 会话有效。

### Q6: 构建容器时出现网络错误怎么办？

如果在 **构建阶段**（如安装 Python、Node 等 features）遇到网络错误：

```
E: Failed to fetch http://ports.ubuntu.com/...
500 reading HTTP response body: unexpected EOF
```

**原因**：这是构建时代理配置缺失导致的。Docker 构建阶段无法直接使用运行时的环境变量。

**解决方案**：

1. **确保已设置宿主机环境变量**（在启动 VS Code 之前）：
   ```bash
   export HOST_PROXY_URL=http://host.docker.internal:7890
   export NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local
   ```

2. **Dockerfile 已配置构建参数**（项目已包含）：
   ```dockerfile
   ARG HTTP_PROXY
   ARG HTTPS_PROXY
   ARG NO_PROXY
   ENV http_proxy=${HTTP_PROXY}
   ENV https_proxy=${HTTPS_PROXY}
   # ...
   ```

3. **devcontainer.json 已配置 build.args**（项目已包含）：
   ```json
   {
     "build": {
       "args": {
         "HTTP_PROXY": "${localEnv:HOST_PROXY_URL}",
         "HTTPS_PROXY": "${localEnv:HOST_PROXY_URL}",
         "NO_PROXY": "${localEnv:NO_PROXY}"
       }
     }
   }
   ```

4. **重建容器**：
   - VS Code 命令面板 → `Dev Containers: Rebuild Container`

**验证**：在构建日志中应该看到代理被正确使用，不再出现网络超时或 500 错误。

## 进阶配置

### 使用环境文件管理代理配置

可以创建一个 `.env.proxy` 文件管理代理配置：

```bash
# .env.proxy
HOST_PROXY_URL=http://host.docker.internal:7890
ALL_PROXY=socks5h://host.docker.internal:1080
NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local
```

然后在 shell 配置中：

```bash
# ~/.zshrc
if [ -f ~/.env.proxy ]; then
  export $(grep -v '^#' ~/.env.proxy | xargs)
fi
```

### 为不同项目配置不同代理

使用 VS Code 的工作区设置：

```json
// .vscode/settings.json
{
  "terminal.integrated.env.linux": {
    "HTTP_PROXY": "http://host.docker.internal:7890",
    "HTTPS_PROXY": "http://host.docker.internal:7890"
}
}
```

## 宿主机绕行（localhost 回调必读）

某些登录流程（如 Claude Code 的浏览器授权）会使用本地回调：浏览器跳转到 `http://localhost:<端口>/callback`，而回调服务实际跑在“容器内”，依赖 VS Code 端口转发把容器端口映射到宿主机相同端口。因此，必须确保“宿主机浏览器访问 localhost”不会经过代理，且不会被 IPv6/解析差异干扰。

### 推荐绕行清单（添加到宿主机/代理客户端）

- localhost
- 127.0.0.1
- ::1
- host.docker.internal
- 可选：`*.local`
- 可选直连内网段：`127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10`

说明：`::1` 是 IPv6 的 localhost。很多浏览器会优先尝试 `::1`，未绕行会导致请求被代理接管或连接失败，从而出现“授权页一直转圈”。

### macOS 系统代理（系统设置）

路径：系统设置 → 网络 → 选择当前网络 → 详情 → 代理

- 如启用“自动发现代理/自动配置代理/HTTP(S) 代理”，在“忽略这些主机与域的代理设置”填入：
  - `localhost, 127.0.0.1, ::1, host.docker.internal, *.local`
- 能力允许时，关闭“自动发现/自动配置代理”，避免 PAC 覆盖本地绕行；或确保 PAC 对上述目标返回 `DIRECT`。

### Shadowrocket（规则示例）

在使用的配置文件中添加以下规则（顺序靠前）：

```
DOMAIN-SUFFIX,claude.ai,PROXY
DOMAIN-SUFFIX,anthropic.com,PROXY
DOMAIN,localhost,DIRECT
DOMAIN,host.docker.internal,DIRECT
DOMAIN-SUFFIX,local,DIRECT
IP-CIDR,127.0.0.0/8,DIRECT,no-resolve
IP-CIDR,10.0.0.0/8,DIRECT,no-resolve
IP-CIDR,172.16.0.0/12,DIRECT,no-resolve
IP-CIDR,192.168.0.0/16,DIRECT,no-resolve
IP-CIDR,100.64.0.0/10,DIRECT,no-resolve
IP-CIDR,::1/128,DIRECT,no-resolve
```

应用/重载规则后再重试授权。

### Clash / ClashX（规则示例）

在 `rules:` 中加入（放在较前位置）：

```
- DOMAIN,localhost,DIRECT
- DOMAIN,host.docker.internal,DIRECT
- DOMAIN-SUFFIX,local,DIRECT
- IP-CIDR,127.0.0.0/8,DIRECT,no-resolve
- IP-CIDR,10.0.0.0/8,DIRECT,no-resolve
- IP-CIDR,172.16.0.0/12,DIRECT,no-resolve
- IP-CIDR,192.168.0.0/16,DIRECT,no-resolve
- IP-CIDR,100.64.0.0/10,DIRECT,no-resolve
- IP-CIDR,::1/128,DIRECT,no-resolve
```

如使用 TUN/增强模式，也可在 bypass/排除清单增加上述条目。

### Surge（规则示例）

```
DOMAIN,localhost,DIRECT
DOMAIN,host.docker.internal,DIRECT
DOMAIN-SUFFIX,local,DIRECT
IP-CIDR,127.0.0.0/8,DIRECT
IP-CIDR,10.0.0.0/8,DIRECT
IP-CIDR,172.16.0.0/12,DIRECT
IP-CIDR,192.168.0.0/16,DIRECT
IP-CIDR,100.64.0.0/10,DIRECT
IP-CIDR6,::1/128,DIRECT
```

### SwitchyOmega（浏览器扩展）

- 在使用的 Profile 的 Bypass List（或“直接连接”规则）加入：
  - `localhost, 127.0.0.1, ::1, host.docker.internal, *.local`

### PAC 文件（示例片段）

```javascript
function FindProxyForURL(url, host) {
  if (
    isPlainHostName(host) ||
    host == 'localhost' ||
    shExpMatch(host, '127.0.0.1') ||
    host == '::1' ||
    dnsDomainIs(host, '.local') ||
    host == 'host.docker.internal' ||
    isInNet(dnsResolve(host), '127.0.0.0', '255.0.0.0') ||
    isInNet(dnsResolve(host), '10.0.0.0', '255.0.0.0') ||
    isInNet(dnsResolve(host), '172.16.0.0', '255.240.0.0') ||
    isInNet(dnsResolve(host), '192.168.0.0', '255.255.0.0') ||
    isInNet(dnsResolve(host), '100.64.0.0', '255.192.0.0')
  ) {
    return 'DIRECT';
  }
  return 'PROXY your-proxy:port'; // 按需替换
}
```

### 验证步骤

- 宿主机：`curl -v http://localhost:<端口>/` 不应出现 “Proxy CONNECT …”，应直接连到 `127.0.0.1:<端口>`（看到 404 也算成功）。
- VS Code → Ports 面板：对该端口选择 “Open in Browser”，可打开 404 页面；随后在授权页点击 Authorize 应一次完成跳转。
- 若抓包/浏览器 DevTools 显示先连 `::1` 失败再回退，说明 `::1` 未纳入绕行；补充后重试。

## 🛡️ 防封号特别配置（STRICT_PROXY_ONLY）

为防止 IP 泄露导致 Claude 封号，本配置默认启用 **严格代理模式**，并推荐在代理客户端中对 Claude 相关域名做显式规则。

### 1. 容器内机制

`devcontainer.json` 中通过 `containerEnv` 设置了：

```json
{
  "STRICT_PROXY_ONLY": "${localEnv:STRICT_PROXY_ONLY:1}"
}
```

当 `STRICT_PROXY_ONLY=1` 时：

- 防火墙只放行 DNS 和代理端口（由 `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` 解析得到）
- 不再对任何外部域名（包括 `claude.ai` / `anthropic.com`）做直连白名单
- 所有外网访问必须走代理

如需暂时允许少量直连白名单，可以在宿主机设置：

```bash
export STRICT_PROXY_ONLY=0
```

然后在 VS Code 中重建容器。

### 2. 宿主机代理（以 Shadowrocket 为例）

在 **宿主机代理客户端** 中，既要确保 Claude 相关域名强制走代理，又要保证登录回调的 `localhost` 直连。以 Shadowrocket 为例（在现有规则基础上追加）：

```text
DOMAIN-SUFFIX,claude.ai,PROXY        # Claude 网站与服务
DOMAIN-SUFFIX,anthropic.com,PROXY    # Anthropic 相关域名
DOMAIN,localhost,DIRECT              # 本地回调
IP-CIDR,127.0.0.0/8,DIRECT,no-resolve
```

其中：

- `claude.ai` / `anthropic.com` 必须显式指定走代理节点（建议选择美国节点），不要依赖“自动选择”或泛用配置模式。
- `localhost` / `127.0.0.0/8` 必须保持直连，以配合 VS Code 端口转发完成登录回调。

更多平台（Clash/Surge/SwitchyOmega/PAC）的 localhost 绕行示例，见上文“宿主机绕行（localhost 回调必读）”一节。

## 参考资料

- [Docker 官方文档 - Networking](https://docs.docker.com/network/)
- [VS Code Dev Containers - Environment Variables](https://code.visualstudio.com/remote/advancedcontainers/environment-variables)
- [Docker host.docker.internal 说明](https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host)

## 故障排除日志

如果遇到问题，请收集以下信息：

```bash
# 宿主机信息
docker --version
docker info | grep -i os

# 环境变量
env | grep -i proxy

# 容器内测试
docker exec -it <container-name> bash -c 'env | grep -i proxy'
docker exec -it <container-name> bash -c 'nc -vz host.docker.internal 7890'

# 防火墙规则
docker exec -it <container-name> bash -c 'sudo iptables -S OUTPUT'
```
