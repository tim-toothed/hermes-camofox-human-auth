# Native Windows mode (experimental)

This branch leaves the Docker/noVNC distribution unchanged. It adds a separate native Windows path for local human authentication.

## Install

Prerequisites:

- Windows 10/11;
- Node.js/npm;
- Git;
- Hermes Agent available as `hermes`.

From the repository root:

```powershell
.\scripts\install-native.ps1
```

The installer clones Camofox into `vendor/camofox-browser`, applies only `patches/server-native-headed.patch`, installs npm dependencies, and configures Hermes to use the native API at `http://127.0.0.1:9377`.

## Run modes

Normal automation:

```powershell
.\scripts\start-native.ps1 -DisplayMode headless
```

Local interactive authentication:

```powershell
.\scripts\start-native.ps1 -DisplayMode headed
```

`headed` opens a normal Camoufox window in the logged-in Windows desktop. The user enters passwords, OTP/MFA codes, OAuth confirmations, or CAPTCHA answers directly into that window. Hermes does not receive those secrets.

## Persistence

Both modes use the same profile directory:

```text
data/profiles
```

After authentication, stop the headed process and restart in headless mode. Cookies and localStorage remain available to the headless process.

## Current scope

This first native iteration deliberately does not change the Docker scripts, Docker Compose file, noVNC skill, or Docker plugin. Automatic in-process auth handoff (headless → headed → headless) is the next layer; the current branch first validates that Camoufox can run visibly on Windows with the same persistent profile.
