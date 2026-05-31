#!/usr/bin/env bash
# verify.fullstack.sh — Quality gate for full-stack projects (Python backend + Node frontend)
# Adapt: BACKEND_DIR, FRONTEND_DIR, venv path, test commands.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$REPO_ROOT/backend"    # ← adjust if different
FRONTEND_DIR="$REPO_ROOT/frontend"  # ← adjust if different
PASS=0; FAIL=0

echo "=== $(basename "$REPO_ROOT") — Quality Gate (Full-stack) ==="
echo ""

# ── Backend: pytest ───────────────────────────────────────────────
if [ -d "$BACKEND_DIR" ]; then
  echo "→ Backend: pytest..."
  if [ -f "$BACKEND_DIR/venv/bin/python3" ]; then
    PYTHON="$BACKEND_DIR/venv/bin/python3"
  else
    PYTHON="python3"
  fi

  if "$PYTHON" -m pytest "$BACKEND_DIR" --tb=short -q 2>&1; then
    echo "✓ Backend OK"; PASS=$((PASS+1))
  else
    echo "✗ Backend FAILED"; FAIL=$((FAIL+1))
  fi
  echo ""
fi

# ── Frontend: vitest/jest ─────────────────────────────────────────
if [ -d "$FRONTEND_DIR" ]; then
  echo "→ Frontend: tests..."
  cd "$FRONTEND_DIR"

  if grep -q '"vitest"' package.json 2>/dev/null; then
    TEST_CMD="npm run test:unit -- --run"
  elif grep -q '"jest"' package.json 2>/dev/null; then
    TEST_CMD="npm test -- --watchAll=false"
  else
    TEST_CMD="npm test"
  fi

  if $TEST_CMD 2>&1; then
    echo "✓ Frontend tests OK"; PASS=$((PASS+1))
  else
    echo "✗ Frontend tests FAILED"; FAIL=$((FAIL+1))
  fi
  echo ""

  # TypeScript
  if grep -q '"type-check"' package.json 2>/dev/null; then
    echo "→ TypeScript..."
    if npm run type-check 2>&1; then
      echo "✓ TypeScript OK"; PASS=$((PASS+1))
    else
      echo "✗ TypeScript errors"; FAIL=$((FAIL+1))
    fi
    echo ""
  fi
fi

# ── Result ────────────────────────────────────────────────────────
echo "================================="
TOTAL=$((PASS+FAIL))
[ "$FAIL" -eq 0 ] && echo "✓ PASSED ($PASS/$TOTAL)" && exit 0
echo "✗ FAILED ($FAIL/$TOTAL failed)" && exit 1
