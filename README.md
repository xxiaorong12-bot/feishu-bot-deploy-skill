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

## Preflight

```bash
./scripts/preflight.sh /path/to/project
```

The helper checks local project shape, common config files, OpenClaw presence,
port `18080`, `/health`, and git status. It does not print secrets.

## Notes

This repository intentionally does not include Feishu credentials, `.env`
files, screenshots, browser profiles, or tenant-specific deployment data.
