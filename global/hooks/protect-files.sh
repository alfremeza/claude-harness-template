#!/usr/bin/env bash
# protect-files.sh — PreToolUse safety hook for Bash commands
# Blocks dangerous operations on sensitive files and destructive commands.
# Used with settings.safe.json.
#
# Claude Code passes the tool input via stdin as JSON:
# { "tool": "Bash", "input": { "command": "..." } }

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('input',{}).get('command',''))" 2>/dev/null || echo "")

# ── Sensitive files — block read and write ────────────────────────
SENSITIVE_PATTERNS=(
  "\.env"
  "\.env\."
  "id_rsa"
  "id_ed25519"
  "\.pem"
  "\.key"
  "credentials\.json"
  "secrets\."
  "api_key"
  "private_key"
  "ANTHROPIC_API_KEY"
  "BOT_TOKEN"
  "DATABASE_URL"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "BLOCK: Command touches sensitive file pattern ($pattern). Use explicit permission if intentional." >&2
    exit 1
  fi
done

# ── Destructive commands — always block ───────────────────────────
DESTRUCTIVE_PATTERNS=(
  "rm -rf"
  "rm -r /"
  "git reset --hard"
  "git push --force"
  "git push -f"
  "drop table"
  "DROP TABLE"
  "truncate"
  "TRUNCATE"
  "format"
  "mkfs"
  "> /dev/"
  "dd if="
)

for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qF "$pattern"; then
    echo "BLOCK: Destructive command pattern detected ($pattern). Run manually if intentional." >&2
    exit 1
  fi
done

# ── Dangerous pipe patterns ───────────────────────────────────────
if echo "$COMMAND" | grep -qE "curl.*(sh|bash|python)|wget.*(sh|bash|python)|\| bash|\| sh|\| python"; then
  echo "BLOCK: Piping remote content to shell interpreter is not allowed." >&2
  exit 1
fi

# ── Allow ─────────────────────────────────────────────────────────
exit 0
