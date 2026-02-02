# AGENTS.md

Instructions for AI coding agents working on this project.

## Project Overview

This is **Amp in a Box** - a Docker-based sandboxing solution for running Amp CLI with network filtering via a Squid proxy sidecar.

## Key Files

| File | Purpose |
|------|---------|
| `allowlist.txt` | Domains Amp is allowed to access |
| `blocklist.txt` | Domains explicitly blocked |
| `envfile` | Environment variables for containers |
| `ARCHITECTURE.md` | Technical architecture documentation |

## Domain List Format

Both `allowlist.txt` and `blocklist.txt` use this format:
- One domain per line
- Lines starting with `#` are comments
- Prefix with `.` for wildcard subdomains (e.g., `.github.com` matches `api.github.com`)

## Common Tasks

### Adding a new allowed domain

Edit `allowlist.txt`:
```
newdomain.com
.newdomain.com
```

### Checking blocked requests

Review proxy logs in `~/.local/log/amp-proxy/access.log` for `TCP_DENIED/403` entries.

## Code Conventions

- Use plain text files for configuration (no YAML/JSON complexity)
- Keep documentation in Markdown
- Shell scripts should be POSIX-compatible where possible

## Testing

Currently no automated tests. Manual testing:
1. Start the sandbox
2. Verify Amp can reach allowed domains
3. Verify blocked domains return 403
