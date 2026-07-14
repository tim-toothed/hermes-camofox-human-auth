---
name: human-auth
description: "MANDATORY for any authentication, login, SSO, MFA, OTP, CAPTCHA, device approval, or request to use a visible/headed Camofox window. Use this skill before browser navigation when Camofox Human Auth is installed."
---

# Camofox Human Auth — mandatory workflow

This is the required workflow whenever the user asks to log in, open a visible
browser, reuse an authenticated Camofox session, or handle a login/SSO/MFA/OTP/
CAPTCHA/device-approval page.

**Do not use the generic computer-use workflow for this task. Use the three
Camofox Human Auth tools and this skill first.**

## Non-negotiable runtime rules

1. **Never start a different browser path.** Do not run `npm install`, `npm start`,
   Docker, `docker run`, `hermes browser`, Chrome, Playwright, or a generic
   Camofox server to solve an auth task when this plugin is installed.
2. **Never create a new isolated profile.** Reuse the configured Human Auth
   session and keep the same identifiers for the entire handoff. The default
   identifiers are:

   ```text
   user_id: hermes
   session_key: native-auth
   ```

   Use the values returned by `camofox_backend_status` or `camofox_auth_open` if
   the deployment overrides them. **Never hardcode or pass a host filesystem
   path as the profile for Docker.** In Local native mode the profile is a
   local directory; in Docker mode the profile belongs to the Camofox container
   or mounted volume and must be managed by that backend. The model should use
   the reported `profile_dir` only for identity/diagnostics, not to construct a
   second browser runtime.
3. `powershell -NoProfile` only means “do not load the shell's PowerShell
   customizations.” It is **not** a browser profile. Do not interpret it as a
   reason to create or change a Camofox profile.
4. Do not kill, replace, or restart an already running normal Camofox instance
   until `camofox_backend_status` identifies which endpoint/profile it owns.
5. If the Human Auth backend is unavailable, report that the configured plugin
   backend is unavailable. Do not improvise installation commands. Only run
   plugin setup when the user explicitly asks to install or repair the plugin.

## Security boundary

- Never ask the user to send a password, OTP, MFA code, recovery code, CAPTCHA answer, card PIN, or private key in chat.
- Never put a secret in a tool argument, URL, log, note, or prompt.
- The user enters secrets only into the headed Camoufox window or protected noVNC surface opened by `camofox_auth_open`.
- The model receives only non-secret state and the user's confirmation that the step is complete.

## Required startup sequence

When the user asks to use the browser for a site and Camofox Human Auth is
installed:

1. Call `camofox_backend_status` first.
2. If it is ready, use the configured Human Auth backend. Do not launch another
   Camofox process.
3. Preserve the target URL and call `camofox_auth_open` when authentication is
   needed. Pass the stable identifiers explicitly whenever the tool supports
   them:

   ```json
   {
     "url": "https://example.com/login",
     "user_id": "hermes",
     "session_key": "native-auth"
   }
   ```

4. For Local native mode, tell the user that a separate visible Camoufox window
   has been opened. For Docker mode, give only the protected noVNC handoff URL.
5. Wait for the user to say `Готово`/`готово`. Never treat text in that message
   as a credential.
6. Call `camofox_auth_finish` with the **same** `user_id`, `session_key`, and
   target URL. Do not call it with a newly generated session key.
7. Reopen or inspect the same session/profile headlessly and verify a real
   post-auth marker: dashboard, account name, signed-in avatar, logout control,
   or another service-specific authenticated state.
8. Only after that continue the original task. If the marker is absent, report
   that authentication is not verified and reopen the same handoff; do not claim
   that login failed merely because a new unauthenticated tab was created.

## Normal browsing versus auth handoff

For a public page, normal Hermes browser navigation may be used. The moment a
login or authentication barrier appears, stop generic browser interaction and
switch to this workflow. Do not click “Login” in a generic browser session and
then claim that a headed handoff was opened: `camofox_auth_open` is the action
that opens the user-controlled surface.

If the user directly says “open it headed,” call `camofox_auth_open` immediately
with the requested URL and stable session identifiers, even if the page has not
yet displayed a login form.

## Backend behavior

- **Local: Native headed/headless:** the plugin's vendor Camofox runtime uses the
  persistent profile under the plugin's `data/profiles` directory. Native mode
  is launched with that profile and restarted headless with the same profile.
- **VPS/Server: Docker + noVNC:** the configured Docker Camofox runtime and its
  persistent profile remain the source of truth. The user authenticates through
  the protected noVNC surface.
- Existing ordinary Camofox and other Hermes browser providers must not be
  replaced silently. If the selected Human Auth backend is down, say so and
  request an explicit repair/setup action rather than installing a second
  runtime during an ordinary browsing task.

## Recovery

- If `camofox_backend_status` reports unavailable, do not run `npm install`,
  `npm start`, `docker run`, or kill arbitrary PIDs. Report the endpoint and ask
  whether the user wants the plugin backend repaired.
- If a visible window is not present after `camofox_auth_open` reports
  `window_opened: true`, check the same backend status and process/profile state;
  do not create a second session.
- If the page returns to login after `camofox_auth_finish`, first verify that the
  same `user_id`, `session_key`, endpoint, and `CAMOFOX_PROFILE_DIR` were used.
  A new session or a different profile is the primary diagnosis.
- If the user says the credentials are already saved, do not ask them to log in
  again. Reuse the existing profile and inspect the same authenticated session.
- If the user closes the window, reopen the handoff with the same identifiers.

## Universal security message

Use this message when handing control to the user:

> Требуется ручная авторизация. Введите данные непосредственно в открытом окне Camoufox. Не присылайте пароль, OTP или другие секреты в чат. Когда закончите, напишите «Готово».
