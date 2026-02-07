# Dev Container VPN/Proxy Setup Guide

## Overview

This guide explains how to configure the Dev Container to use your host machine's VPN or proxy services. This is useful when you need to access network resources through a corporate VPN or proxy.

## Solution Overview

We use **Plan A (Recommended, Cross-platform)**: Pass the host machine's proxy through to the container as an HTTP(S)/SOCKS proxy.

### How It Works

1. The host runs a proxy client (e.g., Clash, V2Ray, Surge, etc.)
2. The container accesses the host via the `host.docker.internal` alias
3. Applications inside the container connect to the host proxy via proxy environment variables
4. The firewall automatically allows the proxy port, enabling container access to the proxy service

### Platform Support

- **macOS / Windows (Docker Desktop)**: `host.docker.internal` is available by default
- **Linux (Docker Engine >= 20.10)**: Requires `--add-host=host.docker.internal:host-gateway` mapping

## Quick Start

### Step 1: Configure Proxy Environment Variables on the Host

Set the following environment variables in the host machine's (**not inside the container**) terminal or shell configuration:

```bash
# HTTP/HTTPS proxy (common ports: 7890, 8080, 8888)
export HOST_PROXY_URL=http://host.docker.internal:7890

# SOCKS proxy (optional, common port: 1080)
export ALL_PROXY=socks5h://host.docker.internal:1080

# NO_PROXY: addresses that bypass the proxy (optional)
export NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local
```

**Notes**:
- Replace the port numbers (e.g., `7890`) with your proxy software's actual listening port
- Common proxy software ports:
  - Clash: HTTP 7890, SOCKS 7891
  - V2Ray: HTTP/SOCKS 1080
  - Surge: HTTP 6152, SOCKS 6153
  - Shadowsocks: SOCKS 1080

**Recommended**: Add these environment variables to your shell configuration file (e.g., `~/.zshrc` or `~/.bashrc`) so they are set automatically on every terminal launch:

```bash
# Add to ~/.zshrc or ~/.bashrc
echo 'export HOST_PROXY_URL=http://host.docker.internal:7890' >> ~/.zshrc
echo 'export ALL_PROXY=socks5h://host.docker.internal:1080' >> ~/.zshrc
echo 'export NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local' >> ~/.zshrc

# Reload the configuration
source ~/.zshrc
```

### Step 2: Start the Dev Container

After configuring environment variables, rebuild and start the Dev Container in VS Code:

1. Open the VS Code Command Palette (Cmd/Ctrl + Shift + P)
2. Run: `Dev Containers: Rebuild Container`

The proxy configuration will take effect automatically after the container starts.

### Step 3: (Optional) Configure Package Manager Proxies

If you want apt, npm, pip, git, and other tools to also use the proxy, run inside the container:

```bash
bash .devcontainer/setup-proxy.sh
```

This script automatically configures proxy settings for the following tools:
- APT (Debian/Ubuntu package manager)
- npm / yarn
- pip (Python package manager)
- git
- wget

### Step 4: Verify Proxy Configuration

Run the following commands inside the container to verify the proxy is working:

```bash
# 1. Check environment variables
env | grep -i proxy

# 2. Test proxy port connectivity
nc -vz host.docker.internal 7890

# 3. Test actual network access (if your proxy allows access to Google)
curl -I https://www.google.com

# 4. View firewall rules (should show the proxy port is allowed)
sudo iptables -S OUTPUT | grep -i proxy
```

## Configuration Details

### devcontainer.json Configuration

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

**Configuration notes**:
- **`build.args`**: **[New]** Passes proxy configuration to the Docker build stage, used for network access when installing features (Python, Node, GitHub CLI, etc.)
- `--add-host=host.docker.internal:host-gateway`: Enables `host.docker.internal` on Linux systems
- `${localEnv:HOST_PROXY_URL}`: Reads the proxy URL from host environment variables
- `remoteEnv`: Sets environment variables for VS Code and its child processes (terminals, tasks, etc.)
- `containerEnv`: Sets environment variables for the entire container process environment

### Automatic Firewall Allowance

`init-firewall.sh` automatically parses proxy environment variables and adds the proxy host and port to the allowlist:

```bash
allow_proxy_from_env() {
  # Extract proxy address from HTTP(S)_PROXY or ALL_PROXY
  PROXY_RAW="${HTTP_PROXY:-${HTTPS_PROXY:-${ALL_PROXY:-}}}"
  # Parse host and port
  # Add proxy IP and port to the iptables allowlist
}
```

This ensures the container can access the proxy service even when the firewall denies outbound connections by default.

## FAQ

### Q1: How should I configure my proxy software?

**Key settings**:
1. **Allow connections from LAN**: Most proxy software only listens on `127.0.0.1` by default; you need to change it to listen on `0.0.0.0` or enable LAN connections
2. **Note the port numbers**: Record the HTTP and SOCKS proxy port numbers for setting environment variables

**Common proxy software configuration**:

- **Clash**: Set `allow-lan: true` in the configuration file
- **V2Ray**: Set the listen address to `0.0.0.0` in Inbounds
- **Surge**: Check "Allow connections from LAN" in "Proxy Settings"

### Q2: What if the container cannot connect to the proxy?

**Diagnostic steps**:

```bash
# 1. Check if host environment variables are correctly set
echo $HOST_PROXY_URL

# 2. Check if environment variables are passed into the container
env | grep -i proxy

# 3. Test if host.docker.internal is reachable
ping -c 3 host.docker.internal

# 4. Test if the proxy port is open
nc -vz host.docker.internal 7890

# 5. Check firewall rules
sudo iptables -S OUTPUT
```

**Common causes**:
- Host proxy software is not running or port configuration is wrong
- Proxy software has not enabled "Allow LAN connections"
- Incorrect port numbers
- Linux system has not properly mapped `host.docker.internal`

### Q3: What if apt doesn't support SOCKS proxy?

APT only supports HTTP/HTTPS proxies. If your VPN only provides a SOCKS proxy, there are two solutions:

1. **Recommended**: Configure your proxy software to enable both HTTP and SOCKS ports simultaneously
2. Use `proxychains` or `redsocks` for protocol conversion

### Q4: What if certain domains should not go through the proxy?

Use the `NO_PROXY` environment variable:

```bash
export NO_PROXY=localhost,127.0.0.1,.example.com,.internal
```

- Supports wildcard domains (e.g., `.example.com` matches all subdomains)
- Multiple entries are comma-separated
- Do not add protocol prefixes

### Q5: How to temporarily disable the proxy?

**Method 1**: Unset the environment variables on the host, then rebuild the container

```bash
unset HOST_PROXY_URL
unset ALL_PROXY
# Then run "Rebuild Container" in VS Code
```

**Method 2**: Temporarily unset environment variables inside the container

```bash
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
```

Note: Method 2 only applies to the current shell session.

### Q6: What if there are network errors during container build?

If you encounter network errors during the **build stage** (e.g., installing Python, Node, and other features):

```
E: Failed to fetch http://ports.ubuntu.com/...
500 reading HTTP response body: unexpected EOF
```

**Cause**: Missing proxy configuration during build. The Docker build stage cannot directly use runtime environment variables.

**Solution**:

1. **Ensure host environment variables are set** (before launching VS Code):
   ```bash
   export HOST_PROXY_URL=http://host.docker.internal:7890
   export NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local
   ```

2. **Dockerfile is configured with build arguments** (already included in the project):
   ```dockerfile
   ARG HTTP_PROXY
   ARG HTTPS_PROXY
   ARG NO_PROXY
   ENV http_proxy=${HTTP_PROXY}
   ENV https_proxy=${HTTPS_PROXY}
   # ...
   ```

3. **devcontainer.json is configured with build.args** (already included in the project):
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

4. **Rebuild the container**:
   - VS Code Command Palette -> `Dev Containers: Rebuild Container`

**Verification**: The build logs should show the proxy being used correctly, with no more network timeouts or 500 errors.

## Advanced Configuration

### Manage Proxy Configuration with Environment Files

You can create a `.env.proxy` file to manage proxy settings:

```bash
# .env.proxy
HOST_PROXY_URL=http://host.docker.internal:7890
ALL_PROXY=socks5h://host.docker.internal:1080
NO_PROXY=localhost,127.0.0.1,host.docker.internal,.local
```

Then in your shell configuration:

```bash
# ~/.zshrc
if [ -f ~/.env.proxy ]; then
  export $(grep -v '^#' ~/.env.proxy | xargs)
fi
```

### Configure Different Proxies for Different Projects

Use VS Code workspace settings:

```json
// .vscode/settings.json
{
  "terminal.integrated.env.linux": {
    "HTTP_PROXY": "http://host.docker.internal:7890",
    "HTTPS_PROXY": "http://host.docker.internal:7890"
}
}
```

## Host-side Bypass (localhost Callback - Must Read)

Some login flows (such as Claude Code's browser authorization) use local callbacks: the browser redirects to `http://localhost:<port>/callback`, while the callback server actually runs inside the container, relying on VS Code port forwarding to map the container port to the same host port. Therefore, you must ensure that "host browser access to localhost" does not go through the proxy and is not affected by IPv6/resolution differences.

### Recommended Bypass List (Add to Host/Proxy Client)

- localhost
- 127.0.0.1
- ::1
- host.docker.internal
- Optional: `*.local`
- Optional direct internal network ranges: `127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 100.64.0.0/10`

Note: `::1` is IPv6 localhost. Many browsers will try `::1` first; if not bypassed, the request may be intercepted by the proxy or fail to connect, resulting in "authorization page keeps spinning".

### macOS System Proxy (System Settings)

Path: System Settings -> Network -> Select current network -> Details -> Proxies

- If "Auto Proxy Discovery/Auto Proxy Configuration/HTTP(S) Proxy" is enabled, add the following to "Bypass proxy settings for these Hosts & Domains":
  - `localhost, 127.0.0.1, ::1, host.docker.internal, *.local`
- If possible, disable "Auto Discovery/Auto Configuration Proxy" to avoid PAC overriding local bypass; or ensure the PAC returns `DIRECT` for the above targets.

### Shadowrocket (Rule Examples)

Add the following rules (near the top) in the active profile:

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

Apply/reload rules, then retry authorization.

### Clash / ClashX (Rule Examples)

Add the following to `rules:` (near the top):

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

If using TUN/Enhanced mode, also add the above entries to the bypass/exclusion list.

### Surge (Rule Examples)

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

### SwitchyOmega (Browser Extension)

- In the Bypass List (or "Direct Connection" rules) of the active Profile, add:
  - `localhost, 127.0.0.1, ::1, host.docker.internal, *.local`

### PAC File (Example Snippet)

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
  return 'PROXY your-proxy:port'; // Replace as needed
}
```

### Verification Steps

- Host: `curl -v http://localhost:<port>/` should not show "Proxy CONNECT ...", and should connect directly to `127.0.0.1:<port>` (seeing 404 is fine).
- VS Code -> Ports panel: Select "Open in Browser" for the port; should open a 404 page; then clicking Authorize on the authorization page should complete the redirect in one go.
- If packet capture/browser DevTools shows it tries `::1` first and fails before falling back, `::1` is not in the bypass list; add it and retry.

## Anti-Ban Special Configuration (STRICT_PROXY_ONLY)

To prevent IP leaks that could lead to Claude account bans, this configuration enables **strict proxy mode** by default and recommends setting explicit rules for Claude-related domains in your proxy client.

### 1. In-Container Mechanism

`devcontainer.json` sets the following via `containerEnv`:

```json
{
  "STRICT_PROXY_ONLY": "${localEnv:STRICT_PROXY_ONLY:1}"
}
```

When `STRICT_PROXY_ONLY=1`:

- The firewall only allows DNS and proxy ports (derived from `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY`)
- No direct connection allowlist for any external domains (including `claude.ai` / `anthropic.com`)
- All external access must go through the proxy

To temporarily allow a small direct connection allowlist, set on the host:

```bash
export STRICT_PROXY_ONLY=0
```

Then rebuild the container in VS Code.

### 2. Host Proxy (Shadowrocket Example)

In the **host proxy client**, you need to ensure Claude-related domains are forced through the proxy while keeping `localhost` for login callbacks as a direct connection. Using Shadowrocket as an example (append to existing rules):

```text
DOMAIN-SUFFIX,claude.ai,PROXY        # Claude website and services
DOMAIN-SUFFIX,anthropic.com,PROXY    # Anthropic-related domains
DOMAIN,localhost,DIRECT              # Local callback
IP-CIDR,127.0.0.0/8,DIRECT,no-resolve
```

Where:

- `claude.ai` / `anthropic.com` must be explicitly set to use a proxy node (US nodes recommended); do not rely on "auto-select" or generic configuration modes.
- `localhost` / `127.0.0.0/8` must remain direct connection to work with VS Code port forwarding for login callbacks.

For more platform examples (Clash/Surge/SwitchyOmega/PAC) for localhost bypass, see the "Host-side Bypass (localhost Callback - Must Read)" section above.

## References

- [Docker Official Documentation - Networking](https://docs.docker.com/network/)
- [VS Code Dev Containers - Environment Variables](https://code.visualstudio.com/remote/advancedcontainers/environment-variables)
- [Docker host.docker.internal Documentation](https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host)

## Troubleshooting Logs

If you encounter issues, please collect the following information:

```bash
# Host information
docker --version
docker info | grep -i os

# Environment variables
env | grep -i proxy

# In-container tests
docker exec -it <container-name> bash -c 'env | grep -i proxy'
docker exec -it <container-name> bash -c 'nc -vz host.docker.internal 7890'

# Firewall rules
docker exec -it <container-name> bash -c 'sudo iptables -S OUTPUT'
```
