#!/usr/bin/env bash
# protect-paths.sh — PreToolUse safety hook for Read, Edit, Write, and MultiEdit
# Blocks access to sensitive file paths (.env, credentials, keys, etc.)
# Used with settings.safe.json (matcher: "Read|Edit|Write|MultiEdit").
#
# Claude Code passes tool input via stdin as JSON:
# { "tool_input": { "file_path": "..." } }   ← Read, Edit, Write
# { "tool_input": { "edits": [{"file_path": "..."}] } }  ← MultiEdit
# Exit 2 = block the tool call. Exit 0 = allow.

set -euo pipefail

INPUT=$(cat)

# Extract file path — handle Read/Edit/Write and MultiEdit formats
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
ti = d.get('tool_input', d.get('input', {}))
# Read/Edit/Write: file_path is a top-level key
fp = ti.get('file_path', '')
# MultiEdit: edits is an array of {file_path, ...}
if not fp:
    edits = ti.get('edits', [])
    if edits and isinstance(edits, list):
        fp = edits[0].get('file_path', '')
print(fp)
" 2>/dev/null || echo "")

# If no file path found, allow
[ -z "$FILE_PATH" ] && exit 0

# ── Sensitive file paths — block read and write ───────────────────
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
    echo "BLOCK: Access to sensitive file path ($FILE_PATH). Open manually if intentional." >&2
    exit 2
  fi
done

# ── Allow ─────────────────────────────────────────────────────────
exit 0
