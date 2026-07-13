# Camofox Human Auth

**Camofox Human Auth** is a universal Hermes plugin for manual
authentication in **Camofox Browser**, the API/server layer powered by the
**Camoufox** anti-detect browser engine.

The plugin requires a Camofox backend. It does not support arbitrary browser
providers by itself and never changes `browser.cloud_provider` automatically.
If Hermes is configured for Chromium, Browserbase, Browser Use, or another
provider, the setup must report that the human-auth flow is unavailable until
the user explicitly configures Camofox.


## Installation

Run the platform setup script:

### Windows

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Get-ChildItem -Recurse -Filter "*.ps1" | Unblock-File
.\scripts\setup.ps1
```

### macOS/Linux

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
```

The installer detects the host OS and asks exactly:

```text
Choose Camofox backend:
1. Local: Native headed/headless
2. VPS/Server: Docker + noVNC
```

The selected backend is saved as `CAMOFOX_BACKEND` in the Hermes environment.
Docker installation is never performed silently by the native setup path.

## Bundled skill

The plugin registers the read-only skill as:

```text
camofox-human-auth:human-auth
```

It covers any user-controlled authentication or registration flow: login,
SSO/OAuth, MFA/2FA, OTP, CAPTCHA, phone/email verification, device approval,
consent screens, and similar blockers. It is not marketplace-specific.

## Secret boundary

The user enters passwords, OTPs, CAPTCHA values, and other secrets directly in
the headed browser or private noVNC surface. Those values are never tool
arguments or chat messages.

## Native handoff API

The native Camofox patch adds an admin-key-protected endpoint:

```text
POST /admin/display-mode
x-admin-key: <local CAMOFOX_ADMIN_KEY>
{"mode":"headed"}
{"mode":"headless"}
```

Switching mode restarts the browser process with the same persistent profile.
The plugin recreates only the non-secret URL/session state after the restart.
