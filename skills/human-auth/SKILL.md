---
name: human-auth
description: Universal user-controlled authentication handoff for Camofox. Use for login, registration, SSO, OAuth, MFA/2FA, OTP, CAPTCHA, device confirmation, phone/email verification, consent screens, or any site action that requires secrets or human approval.
---

# Universal Camofox Human Auth handoff

This skill uses **Camofox Browser**, the server/API layer powered by the
**Camoufox** browser engine. It requires a configured Camofox backend. It does
not switch Hermes' existing browser provider automatically.

## Security boundary

- Never ask the user to send a password, OTP, MFA code, recovery code, CAPTCHA answer, card PIN, or private key in chat.
- Never put a secret in a tool argument, URL, log, note, or prompt.
- The user must enter secrets directly into the browser surface opened by `camofox_auth_open`.
- Treat authentication as incomplete until a post-authentication marker is visible.

## When to hand off

Use the handoff when:

- a login or registration form blocks the requested task;
- SSO/OAuth requires a browser confirmation;
- MFA/2FA/OTP is required;
- a CAPTCHA or anti-bot challenge appears;
- a device/browser approval is required;
- the user explicitly asks to authenticate manually;
- the platform cannot be accessed safely through another supported mechanism.

Do not use the handoff merely because a public page is slow or because a login link exists but is not required for the task.

## Procedure

1. Navigate or inspect the current Camofox page and identify the exact auth blocker.
2. Preserve the current URL and the purpose of the original task.
3. Call `camofox_backend_status` if backend state is unknown.
4. Call `camofox_auth_open` with only the URL and non-secret session identifiers.
5. Tell the user which local browser window or noVNC page to use:

   > Требуется ручная авторизация. Введите данные непосредственно в открытом окне браузера. Не присылайте пароль, OTP или другие секреты в чат. Когда закончите, напишите «Готово».

6. Wait for the user to say `Готово`. Do not treat any value in that message as a credential.
7. Re-snapshot the same session/page and verify a meaningful post-auth marker: account dashboard, signed-in avatar/menu, account identifier, logout control, or another service-specific authenticated state.
8. If the marker is absent, explain what visible non-secret step remains and keep the user in control. Do not ask for the secret itself.
9. After successful verification, call `camofox_auth_finish` with the non-secret URL/session identifiers.
10. Continue the original task in headless mode and report only the outcome needed by the user.

## Backend behavior

- `Local: Native headed/headless`: `camofox_auth_open` opens a native desktop Camoufox window. The user types into that window. The browser is relaunched headless after verification using the same persistent profile.
- `VPS/Server: Docker + noVNC`: `camofox_auth_open` returns the protected noVNC URL. The user completes auth there. Never expose raw VNC/noVNC publicly without an authenticated private transport.

## Recovery

- If the window is not visible, call `camofox_backend_status` and report the backend health; do not request credentials in chat.
- If the user closes the window, reopen the handoff without asking for secrets.
- If authentication succeeded but the original tab disappeared during a native restart, reopen the saved non-secret URL and verify the persistent account state.
- If the service reports an account-choice or consent screen, the user may complete it manually; it is still part of the same handoff.
