#!/usr/bin/env bash
set -euo pipefail

project_dir="${1:-$PWD}"

if [[ ! -d "$project_dir" ]]; then
  echo "project_dir: missing: $project_dir"
  exit 2
fi

cd "$project_dir"

echo "project_dir: $(pwd)"

if command -v python3 >/dev/null 2>&1; then
  echo "python3: $(python3 --version 2>&1)"
else
  echo "python3: missing"
fi

if command -v openclaw >/dev/null 2>&1; then
  echo "openclaw: $(openclaw --version 2>&1 | head -n 1)"
else
  echo "openclaw: missing"
fi

for path in .env .env.example pyproject.toml package.json; do
  if [[ -e "$path" ]]; then
    echo "$path: present"
  else
    echo "$path: missing"
  fi
done

if [[ -f pyproject.toml ]] && grep -q "feishu-chatgpt-agent-shell" pyproject.toml; then
  echo "track: feishu-chatgpt-agent-shell"
elif [[ -d feishu-chatgpt-agent-shell ]]; then
  echo "track: nested feishu-chatgpt-agent-shell"
else
  echo "track: custom-or-openclaw"
fi

if [[ -f .env ]]; then
  app_port="$(awk -F= '/^APP_PORT=/{gsub(/[\"\047]/,"",$2); print $2; exit}' .env)"
else
  app_port=""
fi
app_port="${app_port:-18080}"

if command -v lsof >/dev/null 2>&1; then
  if lsof -nP -iTCP:"$app_port" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "port_$app_port: listening"
  else
    echo "port_$app_port: not-listening"
  fi
else
  echo "lsof: missing"
fi

if command -v curl >/dev/null 2>&1; then
  if curl -fsS "http://127.0.0.1:${app_port}/health" >/dev/null 2>&1; then
    echo "health: ok http://127.0.0.1:${app_port}/health"
  else
    echo "health: unavailable http://127.0.0.1:${app_port}/health"
  fi
else
  echo "curl: missing"
fi

if command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "git_root: $(git rev-parse --show-toplevel)"
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "git_status: dirty"
  else
    echo "git_status: clean"
  fi
fi
