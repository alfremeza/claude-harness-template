#!/usr/bin/env bash
# verify.python.sh — Quality gate for Python projects (pytest + syntax check)
# Adapt: set SERVICE_NAME and REQUIRED_VARS for your project.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0

echo "=== $(basename "$REPO_ROOT") — Quality Gate (Python) ==="
echo ""

# ── Python interpreter: prefer venv ──────────────────────────────
if [ -f "$REPO_ROOT/venv/bin/python3" ]; then
  PYTHON="$REPO_ROOT/venv/bin/python3"
elif [ -f "$REPO_ROOT/.venv/bin/python3" ]; then
  PYTHON="$REPO_ROOT/.venv/bin/python3"
else
  PYTHON="python3"
fi

# ── Tests: pytest ─────────────────────────────────────────────────
if [ -d "$REPO_ROOT/tests" ] || find "$REPO_ROOT" -name "test_*.py" -not -path "*/venv/*" | grep -q .; then
  echo "→ Tests: pytest..."
  if "$PYTHON" -m pytest "$REPO_ROOT" --ignore="$REPO_ROOT/venv" --ignore="$REPO_ROOT/.venv" --tb=short -q 2>&1; then
    echo "✓ Tests OK"; PASS=$((PASS+1))
  else
    echo "✗ Tests FAILED"; FAIL=$((FAIL+1))
  fi
else
  echo "⚠ No tests found — consider adding tests"
fi
echo ""

# ── Syntax check: main entry points ──────────────────────────────
echo "→ Syntax check..."
SYNTAX_OK=true
while IFS= read -r -d '' pyfile; do
  if ! "$PYTHON" -m py_compile "$pyfile" 2>&1; then
    echo "  ✗ Syntax error: $pyfile"
    SYNTAX_OK=false
    FAIL=$((FAIL+1))
  fi
done < <(find "$REPO_ROOT" -name "*.py" -not -path "*/venv/*" -not -path "*/.venv/*" -not -path "*/__pycache__/*" -print0)
if $SYNTAX_OK; then echo "✓ Syntax OK"; PASS=$((PASS+1)); fi
echo ""

# ── Environment variables ─────────────────────────────────────────
# Add required env vars for your project:
# REQUIRED_VARS=("ANTHROPIC_API_KEY" "DATABASE_URL" "BOT_TOKEN")
REQUIRED_VARS=()   # ← populate this

if [ ${#REQUIRED_VARS[@]} -gt 0 ]; then
  echo "→ Environment variables..."
  [ -f "$REPO_ROOT/.env" ] && set -a && source "$REPO_ROOT/.env" && set +a 2>/dev/null || true
  ENV_OK=true
  for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
      echo "  ✗ Missing: $var"; ENV_OK=false; FAIL=$((FAIL+1))
    fi
  done
  $ENV_OK && echo "✓ Env vars OK" && PASS=$((PASS+1))
  echo ""
fi

# ── Result ────────────────────────────────────────────────────────
echo "================================="
TOTAL=$((PASS+FAIL))
[ "$FAIL" -eq 0 ] && echo "✓ PASSED ($PASS/$TOTAL)" && exit 0
echo "✗ FAILED ($FAIL/$TOTAL failed)" && exit 1
