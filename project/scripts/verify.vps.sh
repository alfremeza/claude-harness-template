#!/usr/bin/env bash
# verify.vps.sh — Quality gate for VPS-deployed services
# Adapt: SERVICE_NAME, REQUIRED_VARS, REPO_ROOT path on VPS.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0

# ── Configure these for your service ─────────────────────────────
SERVICE_NAME="your-service-name"          # ← systemd service name
REQUIRED_VARS=("ANTHROPIC_API_KEY")       # ← add your required vars
# ─────────────────────────────────────────────────────────────────

echo "=== $(basename "$REPO_ROOT") — Quality Gate (VPS) ==="
echo ""

# ── Load .env ─────────────────────────────────────────────────────
[ -f "$REPO_ROOT/.env" ] && set -a && source "$REPO_ROOT/.env" && set +a 2>/dev/null || true

# ── Tests: pytest ─────────────────────────────────────────────────
if find "$REPO_ROOT" -name "test_*.py" -not -path "*/venv/*" | grep -q . 2>/dev/null; then
  echo "→ Tests: pytest..."
  if [ -f "$REPO_ROOT/venv/bin/python3" ]; then
    PYTHON="$REPO_ROOT/venv/bin/python3"
  else
    PYTHON="python3"
  fi

  if "$PYTHON" -m pytest "$REPO_ROOT" --ignore="$REPO_ROOT/venv" --tb=short -q 2>&1; then
    echo "✓ Tests OK"; PASS=$((PASS+1))
  else
    echo "✗ Tests FAILED"; FAIL=$((FAIL+1))
  fi
  echo ""
fi

# ── Systemd service status ────────────────────────────────────────
echo "→ Service: $SERVICE_NAME..."
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
  echo "✓ Service running"; PASS=$((PASS+1))
else
  STATUS=$(systemctl is-active "$SERVICE_NAME" 2>/dev/null || echo "unknown")
  echo "✗ Service $STATUS — check: journalctl -u $SERVICE_NAME -n 20"
  FAIL=$((FAIL+1))
fi
echo ""

# ── Required environment variables ───────────────────────────────
if [ ${#REQUIRED_VARS[@]} -gt 0 ]; then
  echo "→ Environment variables..."
  ENV_OK=true
  for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
      echo "  ✗ Missing: $var (check .env)"; ENV_OK=false; FAIL=$((FAIL+1))
    fi
  done
  $ENV_OK && echo "✓ Env vars OK" && PASS=$((PASS+1))
  echo ""
fi

# ── Syntax check ─────────────────────────────────────────────────
echo "→ Syntax check..."
SYNTAX_OK=true
while IFS= read -r -d '' pyfile; do
  if ! python3 -m py_compile "$pyfile" 2>&1; then
    echo "  ✗ Syntax error: $pyfile"; SYNTAX_OK=false; FAIL=$((FAIL+1))
  fi
done < <(find "$REPO_ROOT" -name "*.py" -not -path "*/venv/*" -not -path "*/__pycache__/*" -print0)
$SYNTAX_OK && echo "✓ Syntax OK" && PASS=$((PASS+1))
echo ""

# ── Result ────────────────────────────────────────────────────────
echo "================================="
TOTAL=$((PASS+FAIL))
[ "$FAIL" -eq 0 ] && echo "✓ PASSED ($PASS/$TOTAL)" && exit 0
echo "✗ FAILED ($FAIL/$TOTAL failed)" && exit 1
