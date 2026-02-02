# Amp in a Box - Project Overview

## Summary

A Docker-based sandboxing solution for running Amp CLI with network filtering via a Squid proxy sidecar. Provides defense-in-depth security by routing all network traffic through an allowlist-based proxy.

## Tech Stack

- **Containerization:** Docker, Docker Compose
- **Proxy:** Squid
- **Build System:** Makefile
- **CI/CD:** GitHub Actions
- **Registry:** GitHub Container Registry (ghcr.io)
- **Configuration:** Plain text files (allowlist.txt, blocklist.txt)

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Docker Compose Stack               │
│  ┌─────────────────┐    ┌─────────────────────┐ │
│  │  amp-sandbox    │───▶│     amp-proxy       │ │
│  │  (Amp CLI)      │    │     (Squid)         │ │
│  └─────────────────┘    └──────────┬──────────┘ │
└────────────────────────────────────┼────────────┘
                                     ▼
                              Internet (Filtered)
```

## Key Design Decisions

1. **Sidecar pattern** - Separate containers for Amp and proxy
2. **Allowlist-first** - Only explicitly allowed domains are accessible
3. **Configurable paths** - WORKDIR variable for non-standard home directories
4. **Minimal exposure** - Only mount what Amp needs

## Conventions

- Plain text config files (no YAML/JSON for domain lists)
- POSIX-compatible shell scripts
- Makefile-driven workflows
- MIT License

## Current State

Initial setup with:
- Domain allowlist/blocklist
- Documentation (README, ARCHITECTURE, AGENTS.md)

## Active Changes

- `container-build-system` - Adding Dockerfile, Makefile, GitHub Actions
