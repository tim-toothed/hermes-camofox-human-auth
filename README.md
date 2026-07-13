# Hermes Camofox + noVNC

Reproducible local Camofox Docker distribution for Hermes Agent with interactive, human-managed authentication through noVNC.

## What this solves

- one repeatable setup instead of manually patching Camofox;
- Docker persistence for cookies and browser state;
- noVNC only on loopback by default;
- Hermes browser tools routed to the Docker backend;
- a reusable skill that detects login pages, gives the user the noVNC URL, and verifies the same session after authentication.

## Prerequisites

- Windows 10/11: Docker Desktop with WSL2, Git, PowerShell 5.1+;
- Linux/macOS: Docker Engine/Desktop, Git, POSIX shell;
- Hermes Agent installed and available as `hermes`.

## Install

```powershell
Copy-Item .env.example .env
# Edit .env and set a local VNC_PASSWORD.
.\scripts\install.ps1
```

The installer clones the pinned Camofox source into `vendor/camofox-browser`, applies the audited patches, downloads the required binaries, builds the image, starts Docker Compose, and configures Hermes to use `http://127.0.0.1:9378`.

Install the helper plugin and skill in Hermes (after publishing):

```powershell
hermes plugins install https://github.com/tim-toothed/hermes-camofox-human-auth/tree/main/hermes_plugin
hermes skills install https://raw.githubusercontent.com/tim-toothed/hermes-camofox-human-auth/main/skills/camofox-vnc-auth/SKILL.md
```

The plugin adds `camofox_vnc_status`, which reports API availability and the noVNC URL. The skill controls the safe human-authentication handoff.

## Runtime

- Camofox API: `http://127.0.0.1:9378`
- noVNC: `http://127.0.0.1:6089/vnc.html`
- persistent Docker volume: `camofox-data`

```powershell
.\scripts\status.ps1
.\scripts\stop.ps1
.\scripts\start.ps1
```

## Auth behavior

When Camofox snapshots show a login/SSO/MFA/CAPTCHA page, Hermes tells the user to open the noVNC URL and enter secrets there. Hermes never receives or stores those secrets. After the user says `Готово`, Hermes snapshots the same tab and proceeds only after a post-login dashboard/account marker is visible.

## Security

Ports are bound to `127.0.0.1` only. Do not change them to `0.0.0.0` unless the host is protected by a private VPN or an authenticated tunnel. Do not commit `.env`, browser profiles, cookies, storage state, or VNC passwords.

## Repository status

The public repository contains the reproducible local integration package. The GitHub Actions workflow builds the image and runs smoke checks; GHCR publishing and clean-machine installation remain optional follow-up work.
