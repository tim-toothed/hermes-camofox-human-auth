# Camofox Human Auth

**Human-in-the-Loop Authentication for Hermes Agent.**

AI models must not enter passwords, one-time codes, MFA codes, CAPTCHA answers,
or other authentication secrets. The user enters them directly into a temporary
visible browser window or private noVNC session instead.

Camofox Human Auth opens a Camofox browser for the user, waits for the manual
authentication step, and then continues the original task without exposing any
secret to the model. Cookies, sessions, and the authenticated browser profile
remain stored in Camofox for later use.

It works for any website or service: login, registration, SSO/OAuth, MFA/2FA,
OTP, CAPTCHA, device approval, phone/email verification, and similar flows.

## Install

Install the plugin directly from GitHub:

```powershell
hermes plugins install --enable tim-toothed/hermes-camofox-human-auth
```

Then run the one-time setup:

```powershell
hermes camofox-human-auth setup
```

The setup detects the operating system and asks:

```text
Choose Camofox backend:
1. Local: Native headed/headless
2. VPS/Server: Docker + noVNC
```

The setup does not silently replace an existing Hermes browser provider. If no
provider is configured, or another provider is active, Hermes explicitly asks
whether Camofox should be configured.

## Local and server backends

### Local: Native headed/headless

Use this on a local Windows, macOS, or Linux computer. The plugin opens a
normal visible Camoufox window for manual authentication and then returns to
headless automation.

### VPS/Server: Docker + noVNC

Use this on a remote server or VPS. Docker provides the browser runtime and
noVNC provides the private interactive screen for the user.

The standard Camofox/Camoufox setup is primarily headless and Linux-oriented.
This plugin adds the missing human-authentication handoff for local Windows and
macOS systems while retaining Docker + noVNC for remote Linux servers.

## How authentication works

```text
Hermes/Camofox opens a page headless
        ↓
A login or other human-auth step is required
        ↓
Camofox opens a headed window or private noVNC session
        ↓
The user enters secrets directly in the browser
        ↓
The model receives only: “authentication completed”
        ↓
The authenticated persistent profile is verified
        ↓
Automation continues headless
```

Passwords, OTPs, MFA codes, CAPTCHA answers, and private keys are never passed
as tool arguments or sent in chat.

## Requirements

- Hermes Agent with the `hermes` command available;
- Camofox Browser backend;
- Node.js and Git for the native backend;
- Docker Desktop/Engine for the VPS/Server backend.

Camofox Browser is the API/server layer. **Camoufox** is the browser engine it
uses underneath.

## Existing browser configuration

The plugin does not automatically switch `browser.cloud_provider` or replace
Chromium, Browserbase, Browser Use, or another configured provider. Existing
Camofox settings are preserved. If Camofox is not configured, setup asks for
explicit permission before adding it.

The bundled Hermes skill is registered automatically as:

```text
camofox-human-auth:human-auth
```

No separate skill installation is required.
