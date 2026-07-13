# Camofox Human Auth installed

**Camofox Human Auth** uses **Camofox Browser**, the API/server layer powered by the **Camoufox** browser engine.

It requires the Camofox backend. It does not automatically replace or switch an existing Hermes browser provider.

```text
camofox-human-auth:human-auth
```

Run the one-time backend setup from anywhere:

```powershell
hermes camofox-human-auth setup
```

It detects the operating system and asks:

```text
Choose Camofox backend:
1. Local: Native headed/headless
2. VPS/Server: Docker + noVNC
```

The setup preserves an existing Hermes browser provider by default. If no provider is configured, or a different provider is active, it explicitly asks whether to configure/switch to Camofox; answering `N` leaves the current provider unchanged. Restart Hermes after setup.

The plugin is universal: it handles login, registration, SSO/OAuth, MFA/2FA, OTP, CAPTCHA, device approval, and other manual authentication steps for any site. Never send passwords or codes in chat; enter them only in the headed browser or private noVNC surface.
