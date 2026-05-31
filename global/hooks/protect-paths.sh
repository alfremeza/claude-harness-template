#!/usr/bin/env bash
# protect-paths.sh — PreToolUse safety hook for Edit and Write operations
# Blocks writes to sensitive file paths (.env, credentials, keys, etc.)
# Used with settings.safe.json (matcher: "Edit|Write").
#
# Claude Code passes tool input via stdin as JSON:
# { "tool_input": { "file_path": "..." } }
# Exit 2 = block the tool call. Exit 0 = allow.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', '') or d.get('input', {}).get('file_path', ''))
" 2>/dev/null || echo "")

# If no file path found, allow (not an Edit/Write on a file)
[ -z "$FILE_PATH" ] && exit 0

# ── Sensitive file paths — block edit and write ───────────────────
SENSITIVE_PATTERNS=(
  "\.env$"
  "\.env\."
  "id_rsa"
  "id_ed25519"
  "\.pem$"
  "\.key$"
  "credentials\.json"
  "secrets\."
  "\.secret"
  "private_key"
  "service_account"
  "\.pfx$"
  "\.p12$"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if echo "$FILE_PATH" | grep -qiE "$pattern"; then
    echo "BLOCK: Writing to sensitive file path ($FILE_PATH). Edit manually if intentional." >&2
    exit 2
  fi
done

# ── Allow ─────────────────────────────────────────────────────────
exit 0
