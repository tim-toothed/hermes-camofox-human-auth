---
name: camofox-vnc-auth
description: "Use when browsing through Camofox may require interactive website authentication. Detect login pages, hand the user a protected noVNC URL, never handle secrets, and verify the same persistent session after login."
version: 0.1.0
author: Timur / Hermes community
license: MIT
metadata:
  hermes:
    tags: [browser, camofox, novnc, authentication, human-in-the-loop]
    related_skills: [hermes-agent]
---

# Camofox noVNC Human Authentication

## Overview

This skill defines the safe handoff between Hermes browsing and a human-operated noVNC session. Camofox remains the browser backend; noVNC is only the visual interface for entering credentials, MFA codes, OTPs, OAuth approvals, and CAPTCHAs.

## When to Use

Use when a page shows login, registration, phone/email verification, MFA, OTP, CAPTCHA, OAuth approval, SSO, or another interactive authentication challenge. Do not use it to ask for or transmit credentials in chat.

## Workflow

1. **Check the backend.** Call `camofox_vnc_status` if available. Require `api_ok: true`; `ready: false` is acceptable before the first tab is created. Retain the returned `novnc_url`.
2. **Open the target.** Navigate/create the target tab using the normal Camofox browser tools. Keep the same user/session identity for the whole task.
3. **Classify the snapshot.** Treat visible login controls, password/OTP fields, MFA prompts, CAPTCHA/challenge text, OAuth consent screens, and redirects to known authentication paths as authentication markers. A public landing page with a login link is not yet authenticated; follow the link before deciding.
4. **Handoff.** Tell the user: `Требуется авторизация. Откройте <novnc_url> и самостоятельно введите логин, пароль, OTP/MFA-код, подтвердите OAuth и решите CAPTCHA. Не присылайте эти данные в чат. После завершения напишите «Готово».` Do not type or inspect secret fields.
5. **Wait.** Do not claim success until the user says they finished. Do not poll aggressively while the user is entering credentials.
6. **Verify.** After `Готово`, take a fresh snapshot of the same tab. Confirm an authenticated URL or post-login page marker, disappearance of the authentication controls, or another clear success state. If still on the challenge, provide the same noVNC URL and ask the user to finish; never ask what their code or password is.
7. **Continue.** Once verified, perform the original browsing task in the same persistent session. For external side effects, follow the user's normal confirmation requirements.

## Security boundaries

- Never request, repeat, store, or type passwords, phone numbers, OTP/MFA codes, recovery codes, API keys, cookies, or CAPTCHA answers.
- Never expose VNC/noVNC on a public interface by default. The installer binds ports to loopback; remote use requires the operator's private VPN or authenticated tunnel.
- Do not paste full SSO URLs containing tokens into chat or logs. Treat them as sensitive navigation state.
- Do not report `authenticated` from an HTTP 200 alone; verify the page state.
- Do not export or inspect browser storage state as a substitute for the human handoff.

## Completion criteria

Authentication is complete only when the same Camofox tab shows a post-login page marker and no longer presents the authentication challenge. The original browsing task is complete only after the requested page/data/action has been verified in that same session.

## Common Pitfalls

1. **Black noVNC screen:** create/navigate a tab first; an idle X display may contain no useful browser page.
2. **Wrong backend:** verify `CAMOFOX_URL` points to the Docker API port, normally `9378`, not the native `9377` service.
3. **False login success:** a public landing page or HTTP 200 is not authentication.
4. **Challenge loop:** refresh the snapshot after the user says `Готово`; do not assume a redirect completed the flow.
5. **Secret leakage:** never use chat as the credential transport; noVNC is the only login surface.

## Verification Checklist

- [ ] Camofox API health is OK.
- [ ] noVNC URL is loopback/private and reachable by the user.
- [ ] Authentication challenge was detected from a fresh snapshot.
- [ ] User entered secrets only in noVNC.
- [ ] Same tab was re-snapshotted after user confirmation.
- [ ] Post-authentication marker is visible.
- [ ] Original browsing task continued in the persistent session.
