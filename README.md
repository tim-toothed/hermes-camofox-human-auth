# Camofox Human Auth

Universal human-controlled authentication for Hermes through **Camofox Browser**,
the API/server layer powered by the **Camoufox** browser engine.

The plugin requires a Camofox backend. It does not automatically switch an
existing Hermes browser provider; users with Chromium, Browserbase, Browser
Use, or another provider are warned and must explicitly configure Camofox.


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

## Install the unified plugin

Run the setup script from this repository. It detects the operating system and asks:

```text
Choose Camofox backend:
1. Local: Native headed/headless
2. VPS/Server: Docker + noVNC
```

Windows:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Get-ChildItem -Recurse -Filter "*.ps1" | Unblock-File
.\scripts\setup.ps1
```

macOS/Linux:

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
```

Install the one plugin package:

```powershell
hermes plugins install --enable tim-toothed/hermes-camofox-human-auth
```

The plugin bundles and registers the universal skill as `camofox-human-auth:human-auth`; a separate `hermes skills install` command is not required.

The Docker files in this repository remain the VPS/Server backend and are not modified by the native setup path.

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
