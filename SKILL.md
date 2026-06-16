---
name: feishu-bot-deploy
description: >
  Deploy Feishu/Lark bots and Feishu Open Platform apps end to end with Codex.
  Use when the user asks for 飞书机器人部署, 飞书智能体, 飞书开放平台配置,
  Lark bot callbacks, OpenClaw-to-Feishu setup, or packaging a reusable Feishu
  bot deployment workflow.
metadata:
  short-description: Codex-run Feishu bot deployment
---

# Feishu Bot Deploy

Use this skill when a Feishu/Lark bot should be deployed, repaired, verified, or
turned into a reusable Codex-run deployment path.

## Operating Rules

- Do the safe executable work directly. Do not hand routine browser clicks,
  local config edits, service restarts, or verification steps back to the user.
- Read `/Users/evander/.codex/user-collaboration/README.md` and the relevant
  rule files before non-trivial work. For Feishu setup, `RULES.md` and
  `COMMUNICATION.md` are relevant.
- Use Codex's in-app Browser for Feishu Open Platform work by default. Keep it
  hidden unless login, QR scan, CAPTCHA, or the user's explicit watch request
  requires visibility.
- Never print App Secret, tokens, cookies, private keys, or full webhook secrets.
  Write secrets only to local `.env`, local config, keychain, or the official
  console surface.
- Treat Feishu tenant policy limits such as disabled external-group bot use or
  disabled external-user DMs as platform blockers, not local code failures.
- Do not claim deployment is complete until a live health/probe check and a real
  Feishu message loop have been verified, or until a concrete blocker is proven.

## Choose The Deployment Track

1. OpenClaw/Hermes channel deployment:
   - Use when the user wants an existing local agent to receive or send Feishu
     messages.
   - Start with live facts:
     `openclaw --version`,
     `openclaw agents list`,
     `openclaw channels list --all`,
     `openclaw channels capabilities --channel feishu`,
     `openclaw channels status --channel feishu --json`.
   - Prefer the official `@openclaw/feishu` channel/plugin before writing a
     custom bridge.

2. `feishu-chatgpt-agent-shell` deployment:
   - Use when the repo contains the shell template or the user wants a
     ChatGPT/agent wrapper behind a Feishu bot.
   - Expected local endpoints are `/health`, `/lark/events`, and optional
     debug routes from the template.

3. Custom app deployment:
   - Use when the repo has its own Feishu callback service. Locate the callback,
     config, health endpoint, and start command before changing anything.

## Preflight

Run the helper when useful:

Windows:

```powershell
.\scripts\preflight.ps1 C:\path\to\project
```

macOS/Linux:

```bash
/Users/evander/.codex/skills/feishu-bot-deploy/scripts/preflight.sh [project_dir]
```

For the full deploy sequence, read `references/deploy-runbook.md` when a task
requires a complete live deployment, callback setup, or final evidence report.

Then confirm:

- Current project root and target deployment track.
- Existing `.env`, `.env.example`, config loader, callback path, health path,
  and start command.
- Local runtime dependencies and test command.
- Port availability and any already-running service.
- Public HTTPS callback plan: Cloudflare Tunnel, ngrok, existing public domain,
  or platform-hosted deployment.
- Feishu region/control plane. Default for this machine is China Feishu:
  `https://open.feishu.cn`.

## Feishu Open Platform Setup

Use Codex Browser to open:

```text
https://open.feishu.cn/app
```

Complete the console work in this order:

1. Verify login and tenant. Pause only for QR, CAPTCHA, missing permission, or
   administrator approval.
2. Create or reuse an enterprise self-built app.
3. Enable the `机器人` capability.
4. Capture App ID from the console or URL.
5. Reveal App Secret only long enough to write it into local config. Do not
   echo it into chat or logs.
6. Configure event callback to the public HTTPS URL plus the local callback path,
   commonly `/lark/events`.
7. Set or record the verification token/encrypt key as required by the app.
8. Subscribe to message-received events needed by the project.
9. Grant permissions for receiving messages, sending bot messages, uploading
   images/files, or any project-specific APIs.
10. Create and publish a version after changing permissions, callbacks, events,
    or bot capability.

## Local Config And Runtime

For Python/FastAPI shell projects, the typical sequence is:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip setuptools wheel
pip install -e ".[dev]"
pytest -q
feishu-chatgpt-agent run
```

For OpenClaw/Hermes channel projects:

- Install or enable the Feishu channel/plugin if missing.
- Write local Feishu credentials through the official config path.
- Restart the gateway or channel service.
- Bind the intended agent to the Feishu channel.
- Check bindings before sending a live message.

For any project:

- Keep `.env.example` redacted.
- Keep real secrets only in `.env` or a local private config path.
- Restart the service after config changes.
- Verify the running service, not just source files.

## Verification Gates

Deployment is complete only when the applicable gates pass:

- Local health endpoint returns configured state without exposing secrets.
- Feishu credential/token probe succeeds, or channel probe succeeds.
- Feishu callback URL verification succeeds in the Open Platform console.
- App version is published after current callback/permission changes.
- Bot is added to a test chat or DM where tenant policy allows it.
- A real message is sent from Feishu and the local service receives it.
- A real reply is delivered back to Feishu.
- Final evidence includes a message id, channel probe output, or equivalent
  runtime proof.

For OpenClaw, prefer these proof points:

```bash
openclaw channels status --channel feishu --probe --json
openclaw agents bindings
```

For the shell template, prefer:

```bash
curl http://127.0.0.1:18080/health
```

and one real Feishu event/reply with `feishu_message_id`.

## Failure Shields

- Wrong browser context: verify Codex Browser login/tenant before creating or
  editing apps.
- Secret leakage: never paste full credentials into the final answer, command
  output summaries, docs, or memory.
- Partial setup: app creation alone is not deployment. Require callback,
  permissions, publish, restart, probe, bind, and real message proof.
- Stale service: after editing config, restart and check the live endpoint.
- Missing public HTTPS callback: local `/health` success is not enough for
  Feishu inbound events.
- Tenant policy blocker: report the exact console switch or error text and stop
  at the blocker.
- Expensive generation side effects: when testing image/video agents, prefer a
  text-only smoke route first unless the user asked for real production output.

## Final Response Shape

Keep the final answer short and evidence-based:

- What was deployed or updated.
- Local service URL and public callback URL if available.
- Feishu app identity with only safe identifiers, such as app id prefix/suffix.
- Verification evidence: health status, probe result, binding, callback status,
  and real Feishu message id.
- Blockers, if any, with exact next human action such as QR scan or admin
  approval.

Do not include secrets.
