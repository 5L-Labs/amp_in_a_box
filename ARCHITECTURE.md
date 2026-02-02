# Architecture

This document describes the technical architecture of Amp in a Box.

## System Overview

Amp in a Box uses a sidecar container pattern to provide network-level security for Amp CLI. The Amp container cannot access the internet directly—all traffic is routed through a Squid proxy that enforces allowlist/blocklist rules.

```
┌──────────────────────────────────────────────────────────────────────┐
│                            Host System                                │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                    Shared Docker Network                         │ │
│  │                    (network_mode: service:proxy)                 │ │
│  │                                                                  │ │
│  │  ┌──────────────────────────┐  ┌──────────────────────────────┐ │ │
│  │  │     amp-container        │  │      amp-proxy               │ │ │
│  │  │                          │  │      (Squid Sidecar)         │ │ │
│  │  │  ┌────────────────────┐  │  │                              │ │ │
│  │  │  │     Amp CLI        │  │  │  ┌────────────────────────┐  │ │ │
│  │  │  │                    │──┼──┼─▶│   Squid Proxy          │  │ │ │
│  │  │  │  - Agent runtime   │  │  │  │                        │  │ │ │
│  │  │  │  - Tool execution  │  │  │  │  - Port 3128           │  │ │ │
│  │  │  │  - File I/O        │  │  │  │  - SSL bump (MITM)     │  │ │ │
│  │  │  └────────────────────┘  │  │  │  - Domain filtering    │  │ │ │
│  │  │                          │  │  │  - Access logging      │  │ │ │
│  │  │  Volume Mounts:          │  │  └────────────┬───────────┘  │ │ │
│  │  │  - Project directory     │  │               │              │ │ │
│  │  │  - Amp config/cache      │  │  Volume Mounts:              │ │ │
│  │  │  - Git credentials       │  │  - allowlist.txt             │ │ │
│  │  └──────────────────────────┘  │  - blocklist.txt             │ │ │
│  │                                 │  - Log directory             │ │ │
│  │                                 └──────────────┬───────────────┘ │ │
│  └─────────────────────────────────────────────────┼────────────────┘ │
│                                                    │                  │
└────────────────────────────────────────────────────┼──────────────────┘
                                                     ▼
                                              ┌──────────────┐
                                              │   Internet   │
                                              │  (Filtered)  │
                                              └──────────────┘
```

## Components

### 1. Proxy Container (amp-proxy)

**Purpose**: Network gateway and traffic filter

**Technology**: Squid Proxy

**Responsibilities**:
- Intercept all outbound HTTP/HTTPS traffic
- Validate requests against allowlist
- Block requests matching blocklist
- Log all connection attempts
- Handle SSL/TLS connections (CONNECT method)

**Configuration Files**:
- `allowlist.txt` - Permitted domains
- `blocklist.txt` - Explicitly denied domains

### 2. Amp Container

**Purpose**: Isolated runtime for Amp CLI

**Responsibilities**:
- Run Amp CLI agent
- Execute tools (file I/O, shell commands, etc.)
- Access project files via volume mount

**Network Configuration**:
- Uses proxy container's network namespace (`network_mode: service:amp-proxy`)
- HTTP_PROXY/HTTPS_PROXY environment variables set to localhost:3128
- Cannot bypass proxy due to network namespace sharing

## Data Flow

### Allowed Request Flow

```
1. Amp CLI makes HTTPS request to api.anthropic.com
2. Request goes to localhost:3128 (Squid proxy in same network namespace)
3. Squid checks allowlist → anthropic.com is allowed
4. Squid establishes tunnel to api.anthropic.com:443
5. Response flows back through tunnel
6. Request logged: TCP_TUNNEL/200
```

### Blocked Request Flow

```
1. Amp CLI (or executed code) tries to access malicious-site.com
2. Request goes to localhost:3128
3. Squid checks allowlist → domain not found
4. Squid returns HTTP 403 Forbidden
5. Request logged: TCP_DENIED/403
```

## File System Access

| Path | Access | Purpose |
|------|--------|---------|
| `/home/user/project` | Read/Write | Project being worked on |
| `~/.config/amp` | Read/Write | Amp configuration |
| `~/.local/share/amp` | Read/Write | Amp threads and history |
| `~/.cache/amp` | Read/Write | Amp cache and logs |
| `/etc/ampcode` | Read | Managed settings |

## Security Boundaries

### What's Protected

1. **Network exfiltration**: Code executed by Amp cannot send data to unauthorized servers
2. **Supply chain attacks**: npm/pip packages cannot phone home to non-allowlisted domains
3. **Credential theft**: Stolen credentials cannot be exfiltrated

### What's NOT Protected

1. **Local file system**: Amp has full access to mounted volumes
2. **Allowed domains**: Traffic to allowlisted domains is not inspected
3. **Host system**: The host is protected by Docker, not this project

## Logging

### Proxy Access Log Format

```
timestamp duration client status bytes method host destination
```

Example:
```
1769979363.463 3 192.168.100.10 TCP_DENIED/403 3402 GET http://blocked.com/
```

### Log Location

```
~/.local/log/amp-proxy/access.log
```

## Extending

### Adding New Allowed Services

1. Identify required domains (check proxy logs for TCP_DENIED)
2. Add to `allowlist.txt`
3. Restart proxy container

### Custom Squid Configuration

For advanced use cases, mount a custom `squid.conf`:

```yaml
volumes:
  - ./custom-squid.conf:/etc/squid/squid.conf
```
