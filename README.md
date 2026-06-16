# Feishu Bot Deploy Skill

Codex skill for deploying Feishu/Lark bots and Feishu Open Platform apps end to
end.

Use it when a task involves:

- Feishu bot deployment
- Feishu Open Platform app setup
- Lark callback configuration
- OpenClaw or Hermes Feishu channel setup
- `feishu-chatgpt-agent-shell` deployment
- A reusable Codex-run Feishu bot deployment workflow

## What It Enforces

- Codex does safe executable work directly instead of handing routine steps back
  to the user.
- Feishu Open Platform setup defaults to Codex's in-app Browser.
- App Secret, tokens, cookies, and private keys are never printed.
- App creation alone is not considered complete.
- Completion requires live health/probe checks and a real Feishu message loop,
  or a concrete platform/permission blocker.
- Final proof should be redacted: masked chat/message ids, no full credentials,
  no raw private user prompts, and no full agent responses in logs.

## What "Real Bot" Means

This repo is not just a checklist for creating a Feishu app. A bot is considered
real only after:

1. the local service runs,
2. Feishu can verify the public callback URL,
3. required message permissions/events are enabled and published,
4. a real Feishu message reaches the service,
5. a real reply is delivered back to Feishu,
6. for agent bots, one text-only domain prompt reaches the agent path instead of
   only returning a static help or echo response.

If login, QR scan, CAPTCHA, tenant policy, or admin approval blocks the flow,
Codex should record the exact blocker instead of pretending deployment is done.

## Install

Copy or symlink this folder into your Codex skills directory:

```bash
ln -s "$(pwd)" ~/.codex/skills/feishu-bot-deploy
```

Or copy it directly:

```bash
cp -R "$(pwd)" ~/.codex/skills/feishu-bot-deploy
```

## Files

- `SKILL.md`: the skill instructions and deployment gates.
- `scripts/preflight.sh`: a no-secret local preflight helper.
- `scripts/preflight.ps1`: Windows PowerShell preflight helper.
- `.env.example`: redacted environment contract for target bot projects.
- `references/deploy-runbook.md`: step-by-step runbook for Codex-driven deploys.
- `LICENSE`: MIT license.

## Preflight

Windows:

```powershell
.\scripts\preflight.ps1 C:\path\to\bot-project
```

macOS/Linux:

```bash
./scripts/preflight.sh /path/to/project
```

The helper checks local project shape, common config files, OpenClaw presence,
port `18080`, `/health`, and git status. It does not print secrets.

## Codex Handoff Prompt

After installing the skill, hand a local bot project to Codex with a prompt like:

```text
Use the Feishu Bot Deploy skill to make this Feishu bot real.
Do the safe local work yourself. Use the in-app Browser for Feishu Open Platform.
Stop only for QR/CAPTCHA/admin approval/tenant policy blockers.
Do not print secrets. Completion requires health + callback verification + one
real Feishu message, reply, and agent-path smoke prompt when the bot wraps an
agent.
```

For the full procedure, see `references/deploy-runbook.md`.

## Notes

This repository intentionally does not include Feishu credentials, `.env`
files, screenshots, browser profiles, or tenant-specific deployment data.
