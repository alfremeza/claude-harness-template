#!/usr/bin/env bash
# verify.node.sh — Quality gate for Node/TypeScript projects
# Adapt: set your test and type-check commands.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0

echo "=== $(basename "$REPO_ROOT") — Quality Gate (Node/TypeScript) ==="
echo ""

cd "$REPO_ROOT"

# ── Tests: Jest or Vitest ─────────────────────────────────────────
echo "→ Tests..."
# Detect test runner
if grep -q '"vitest"' package.json 2>/dev/null; then
  TEST_CMD="npm run test:unit -- --run"
elif grep -q '"jest"' package.json 2>/dev/null; then
  TEST_CMD="npm test -- --watchAll=false"
else
  TEST_CMD="npm test"
fi

if $TEST_CMD 2>&1; then
  echo "✓ Tests OK"; PASS=$((PASS+1))
else
  echo "✗ Tests FAILED"; FAIL=$((FAIL+1))
fi
echo ""

# ── TypeScript: type check ────────────────────────────────────────
if grep -q '"type-check"' package.json 2>/dev/null; then
  echo "→ TypeScript type check..."
  if npm run type-check 2>&1; then
    echo "✓ TypeScript OK"; PASS=$((PASS+1))
  else
    echo "✗ TypeScript errors"; FAIL=$((FAIL+1))
  fi
  echo ""
fi

# ── Lint ──────────────────────────────────────────────────────────
if grep -q '"lint"' package.json 2>/dev/null; then
  echo "→ Lint..."
  if npm run lint 2>&1; then
    echo "✓ Lint OK"; PASS=$((PASS+1))
  else
    echo "⚠ Lint warnings (non-blocking)"
  fi
  echo ""
fi

# ── Result ────────────────────────────────────────────────────────
echo "================================="
TOTAL=$((PASS+FAIL))
[ "$FAIL" -eq 0 ] && echo "✓ PASSED ($PASS/$TOTAL)" && exit 0
echo "✗ FAILED ($FAIL/$TOTAL failed)" && exit 1
