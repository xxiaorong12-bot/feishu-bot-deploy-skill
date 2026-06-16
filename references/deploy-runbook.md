# Feishu Bot Deployment Runbook

Use this runbook when Codex needs to turn a local Feishu/Lark bot project into a live bot.

## Target State

A deployment is only complete when all of these are true:

1. Local service has a health endpoint.
2. Public HTTPS callback URL reaches the local or hosted service.
3. Feishu Open Platform callback verification succeeds.
4. Required bot events and permissions are enabled.
5. App version is published after callback/permission changes.
6. A test chat or DM can mention/send to the bot.
7. A real Feishu message reaches the service.
8. The service sends a real reply back to Feishu with app credentials, or records why tenant policy blocks it.
9. If the bot wraps an agent, a text-only domain prompt reaches the agent path and returns a non-static answer.

If any item is blocked by login, QR scan, CAPTCHA, tenant policy, or admin approval, record the exact blocker and stop.

## One-Command Local Preflight

Windows:

```powershell
.\scripts\preflight.ps1 C:\path\to\bot-project
```

macOS/Linux:

```bash
./scripts/preflight.sh /path/to/bot-project
```

The preflight is no-secret. It checks project shape, expected config files, port `18080`, `/health`, OpenClaw presence, and git state.

## Environment Contract

Copy `.env.example` into the bot project and fill the local `.env`:

```text
APP_PORT=18080
FEISHU_CALLBACK_PATH=/lark/events
PUBLIC_BASE_URL=https://your-public-url.example
FEISHU_APP_ID=cli_xxx
FEISHU_APP_SECRET=...
FEISHU_VERIFICATION_TOKEN=...
FEISHU_ENCRYPT_KEY=...
```

Never commit `.env`. Never print full secrets in chat, logs, docs, or screenshots.

## Codex Browser Steps

Use the in-app Browser for `https://open.feishu.cn/app`.

1. Verify the tenant before creating or editing the app.
2. Create or reuse an enterprise self-built app.
3. Enable bot capability in the app feature settings.
4. Copy only safe identifiers into notes: app name and masked app id.
5. Reveal App Secret only long enough to write it to `.env`.
6. Configure callback URL:

```text
${PUBLIC_BASE_URL}${FEISHU_CALLBACK_PATH}
```

7. Set verification token and encrypt key if the app requires them.
8. Subscribe to message-received events.
9. Grant message receive/send permissions required by the bot, including the ability to reply to or send messages in the target chat.
10. Publish a new app version.

## Local Runtime Pattern

For a Python/FastAPI-style service:

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install --upgrade pip setuptools wheel
.\.venv\Scripts\pip install -e ".[dev]"
.\.venv\Scripts\python -m pytest -q
.\.venv\Scripts\python -m your_bot_package
```

For a package with an existing CLI, prefer its documented start command.

## Tunnel Pattern

Use one of:

- Cloudflare Tunnel
- ngrok
- existing HTTPS domain
- hosted deployment platform

Local health success is not enough. Feishu must be able to reach the public callback URL.

## Smoke Checks

Health:

```powershell
curl.exe http://127.0.0.1:18080/health
```

Callback URL:

```powershell
curl.exe https://your-public-url.example/health
```

Real message:

1. Add the bot to a test chat where tenant policy allows it.
2. Send a text-only command such as `/help`.
3. Confirm the service log records the event.
4. Confirm the service obtains a tenant access token from `FEISHU_APP_ID` and `FEISHU_APP_SECRET`.
5. Confirm Feishu receives the reply through the app message API. Use an incoming-webhook reply only as a temporary fallback after the target chat is confirmed.
6. For an agent bot, send one real domain prompt, for example `I need help choosing a college major` or the project's own safest text-only smoke question.
7. Confirm the reply is produced by the agent path, not just a static help message or echo.
8. Save safe proof: timestamp, masked chat id, masked message id, health status, and a short redacted result summary.

## Final Report Template

```text
Deployed/updated:
- ...

Local service:
- http://127.0.0.1:18080/health -> ...

Public callback:
- https://.../lark/events -> callback verified / blocked by ...

Feishu app:
- app id: cli_***1234
- permissions: message receive/send ...
- version: published / waiting for admin

Message loop:
- inbound message id: om_***1234
- reply delivered: yes/no
- agent-path prompt verified: yes/no/not applicable

Blockers:
- ...
```
