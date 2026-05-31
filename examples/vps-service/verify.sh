#!/usr/bin/env bash
# Quality gate for VPS-deployed Python service
# Checks: pytest, service status, required env vars
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
ENV_FILE="$REPO_ROOT/.env"

echo "=== Service Name — Quality Gate ==="
echo ""

# ── Load .env if exists ──────────────────────────────────────────
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# ── Python tests (pytest + venv) ─────────────────────────────────
echo "→ Tests: pytest..."
if [ -d "$REPO_ROOT/venv" ]; then
  PYTHON="$REPO_ROOT/venv/bin/python3"
else
  PYTHON="python3"
fi

if "$PYTHON" -m pytest "$REPO_ROOT/tests" --tb=short -q 2>&1; then
  echo "✓ Tests OK"
  PASS=$((PASS+1))
else
  echo "✗ Tests FAILED"
  FAIL=$((FAIL+1))
fi
echo ""

# ── Systemd service status ────────────────────────────────────────
SERVICE_NAME="your-service-name"  # ← change this
echo "→ Service: $SERVICE_NAME..."
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
  echo "✓ Service running"
  PASS=$((PASS+1))
else
  echo "✗ Service is DOWN — run: systemctl restart $SERVICE_NAME"
  FAIL=$((FAIL+1))
fi
echo ""

# ── Required environment variables ───────────────────────────────
echo "→ Environment variables..."
REQUIRED_VARS=(
  "ANTHROPIC_API_KEY"
  "BOT_TOKEN"
  # Add your required vars here
)
ENV_OK=true
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "  ✗ Missing: $var"
    ENV_OK=false
    FAIL=$((FAIL+1))
  fi
done
if $ENV_OK; then
  echo "✓ All env vars set"
  PASS=$((PASS+1))
fi
echo ""

# ── Python syntax check (main entry points) ──────────────────────
echo "→ Syntax check..."
SYNTAX_OK=true
for f in main.py claude_service.py; do
  if [ -f "$REPO_ROOT/$f" ]; then
    if ! "$PYTHON" -m py_compile "$REPO_ROOT/$f" 2>&1; then
      echo "  ✗ Syntax error in $f"
      SYNTAX_OK=false
      FAIL=$((FAIL+1))
    fi
  fi
done
if $SYNTAX_OK; then
  echo "✓ Syntax OK"
  PASS=$((PASS+1))
fi
echo ""

# ── Result ────────────────────────────────────────────────────────
echo "================================="
if [ "$FAIL" -eq 0 ]; then
  echo "✓ Quality Gate PASSED ($PASS/$((PASS)) checks)"
  exit 0
else
  echo "✗ Quality Gate FAILED ($FAIL failed, $PASS passed)"
  exit 1
fi
