# Hermes Camofox Human Auth

## Goal

Ship a reproducible, cross-platform distribution that starts the patched Camofox Docker backend with noVNC, routes Hermes browser tools to it, and gives the agent a deterministic human-in-the-loop authentication handoff: detect an authentication challenge, provide a protected noVNC URL, wait for the user, and verify that the same persistent session is authenticated.

## Architecture

- The repository is a distribution/integration layer around a pinned Camofox source tree. It does not modify Hermes core.
- Docker Compose owns the Camofox service, noVNC ports, and the persistent `/root/.camofox` volume.
- The installer applies a small, auditable patch set to the pinned Camofox checkout or builds a published image in CI.
- Hermes is configured with `CAMOFOX_URL=http://127.0.0.1:9378`, shared `CAMOFOX_USER_ID`, shared `CAMOFOX_SESSION_KEY`, and `CAMOFOX_ADOPT_EXISTING_TAB=true`.
- A user plugin exposes local status and noVNC URL metadata; the skill controls the conversational authentication workflow.
- Credentials never enter the agent prompt, repository, registry, skill, or logs.

## Auth workflow contract

1. The browser skill creates or adopts a tab for the requested site.
2. The agent takes an accessibility snapshot and classifies authentication markers conservatively.
3. If authentication is required, the agent calls the local status helper, returns the noVNC URL, and explicitly tells the user to enter credentials, OTP/MFA, OAuth approvals, and CAPTCHA answers only in noVNC.
4. The agent does not type, inspect, or repeat secrets.
5. After the user says authentication is complete, the agent polls the same tab and verifies a post-authentication marker before continuing.
6. If the session remains ambiguous, the agent asks the user to confirm only the visible state, never a secret.

## Planned files

- `docker-compose.yml`: local-only API/noVNC bindings and persistent volume.
- `.env.example`: non-secret defaults plus a placeholder for the local VNC password.
- `scripts/install.ps1`: Windows installer, Docker prerequisite checks, image build/up, Hermes configuration.
- `scripts/install.sh`: Linux/macOS equivalent.
- `scripts/status.ps1`: health and noVNC checks without secret output.
- `hermes_plugin/plugin.yaml`: user plugin manifest.
- `hermes_plugin/__init__.py`: local status/noVNC helper tool, no core changes.
- `skills/camofox-vnc-auth/SKILL.md`: reusable human-auth handoff behavior.
- `docs/auth-flow.md`: operator-visible contract and troubleshooting.
- `.github/workflows/build-image.yml`: optional CI image build.

## Acceptance checks

- Fresh Windows install works with Docker Desktop and no pre-existing Camofox directory.
- `CAMOFOX_URL` points to the Docker service, not the native `9377` instance.
- `/health` reports `browserConnected: true` after the browser starts.
- `/vnc.html` returns HTTP 200 and `x11vnc` is attached to the active Xvfb display.
- Creating `https://example.com` yields a visible noVNC browser tab.
- A generic authentication challenge produces a noVNC handoff and does not request secrets in chat.
- After user authentication, the same persistent session reaches a post-authentication page.
- Re-running the installer is idempotent and preserves the Docker volume.
- No secret values are committed or printed.

## Open decisions

- Whether to publish GHCR images or build locally from the pinned source.
- Whether remote noVNC access is supplied through an existing VPN/authenticated reverse proxy; the default remains loopback-only.
- Whether the status helper should be a standalone plugin tool or only an installer/skill helper. Prefer the smallest plugin surface unless the auth loop needs structured status.
