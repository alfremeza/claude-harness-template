#!/usr/bin/env bash
# verify.minimal.sh — Minimum viable quality gate for projects without tests yet.
# Checks syntax only. Use this as a starting point, then add real tests.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0

echo "=== $(basename "$REPO_ROOT") — Quality Gate (Minimal) ==="
echo "⚠ No tests configured. Add tests and upgrade to verify.python.sh or verify.node.sh"
echo ""

# ── Python syntax (if Python project) ────────────────────────────
PY_FILES=$(find "$REPO_ROOT" -name "*.py" -not -path "*/venv/*" -not -path "*/__pycache__/*" 2>/dev/null | head -20)
if [ -n "$PY_FILES" ]; then
  echo "→ Python syntax..."
  PYTHON=$([ -f "$REPO_ROOT/venv/bin/python3" ] && echo "$REPO_ROOT/venv/bin/python3" || echo "python3")
  SYNTAX_OK=true
  while IFS= read -r pyfile; do
    if ! "$PYTHON" -m py_compile "$pyfile" 2>&1; then
      echo "  ✗ $pyfile"; SYNTAX_OK=false; FAIL=$((FAIL+1))
    fi
  done <<< "$PY_FILES"
  $SYNTAX_OK && echo "✓ Python syntax OK" && PASS=$((PASS+1))
  echo ""
fi

# ── Node/TypeScript (if Node project) ────────────────────────────
if [ -f "$REPO_ROOT/package.json" ] || [ -f "$REPO_ROOT/frontend/package.json" ]; then
  FRONTEND=$([ -d "$REPO_ROOT/frontend" ] && echo "$REPO_ROOT/frontend" || echo "$REPO_ROOT")
  echo "→ TypeScript (if configured)..."
  cd "$FRONTEND"
  if grep -q '"type-check"' package.json 2>/dev/null; then
    if npm run type-check 2>&1; then
      echo "✓ TypeScript OK"; PASS=$((PASS+1))
    else
      echo "✗ TypeScript errors"; FAIL=$((FAIL+1))
    fi
  else
    echo "⚠ No type-check script in package.json"
  fi
  echo ""
fi

# ── Result ────────────────────────────────────────────────────────
echo "================================="
TOTAL=$((PASS+FAIL))
[ "$FAIL" -eq 0 ] && echo "✓ PASSED ($PASS/$TOTAL) — upgrade to real tests soon" && exit 0
echo "✗ FAILED ($FAIL/$TOTAL failed)" && exit 1
