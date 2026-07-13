# Human authentication handoff

The integration deliberately separates three concerns:

1. **Camofox** owns the persistent browser profile and normal browsing API.
2. **noVNC** gives the human a visual authentication surface; it does not send credentials to Hermes.
3. **The skill** tells Hermes when to hand off and how to verify the result.

## Detection

The skill treats authentication as a state-classification problem from a fresh accessibility snapshot, not as an HTTP status check. Login links are followed before the handoff is reported, and a public landing page is not considered authenticated.

## Handoff message

The canonical message is:

> Требуется авторизация. Откройте `<noVNC URL>` и самостоятельно введите логин, пароль, OTP/MFA-код, подтвердите OAuth и решите CAPTCHA. Не присылайте эти данные в чат. После завершения напишите «Готово».

## Completion

After the user says `Готово`, Hermes re-snapshots the same tab and checks for a post-authentication page marker. Only then does it continue the original task in the persistent session.

## Remote access

The default URL is loopback-only and works on the machine running Docker. For a user on another computer, configure an existing private VPN or authenticated reverse proxy and set `CAMOFOX_NOVNC_PUBLIC_URL` locally. Never publish raw VNC/noVNC directly to the Internet.
