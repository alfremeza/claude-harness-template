#!/usr/bin/env bash
# smoke-test.sh — Verify harness installation is complete and working
# Run after install.sh to confirm everything is in place.
# Usage: bash scripts/smoke-test.sh
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
BRAIN_DIR="$HOME/.claude-brain"
PASS=0; FAIL=0

echo ""
echo "╔══════════════════════════════════════╗"
echo "║  Claude Harness — Smoke Test         ║"
echo "╚══════════════════════════════════════╝"
echo ""

check() {
  local label="$1"; local cmd="$2"
  if eval "$cmd" > /dev/null 2>&1; then
    echo "  ✓ $label"; PASS=$((PASS+1))
  else
    echo "  ✗ $label"; FAIL=$((FAIL+1))
  fi
}

# ── Claude Code ───────────────────────────────────────────────────
echo "→ Claude Code"
check "claude installed"     "command -v claude"
check "ANTHROPIC_API_KEY set" "[ -n \"\${ANTHROPIC_API_KEY:-}\" ]"
echo ""

# ── Global config ─────────────────────────────────────────────────
echo "→ Global config"
check "CLAUDE.md exists"      "[ -f '$CLAUDE_DIR/CLAUDE.md' ]"
check "settings.json exists"  "[ -f '$CLAUDE_DIR/settings.json' ]"
check "settings has hooks"    "grep -q 'SessionStart' '$CLAUDE_DIR/settings.json'"
echo ""

# ── Security hooks ────────────────────────────────────────────────
echo "→ Security hooks"
check "protect-files.sh installed"  "[ -x '$CLAUDE_DIR/hooks/protect-files.sh' ]"
check "protect-paths.sh installed"  "[ -x '$CLAUDE_DIR/hooks/protect-paths.sh' ]"
check "protect-files uses exit 2"   "grep -q 'exit 2' '$CLAUDE_DIR/hooks/protect-files.sh'"
check "protect-paths uses exit 2"   "grep -q 'exit 2' '$CLAUDE_DIR/hooks/protect-paths.sh'"
check "protect-paths covers Read"   "grep -q 'Read' '$CLAUDE_DIR/settings.json'"
echo ""

# ── Agents ────────────────────────────────────────────────────────
echo "→ Agents"
for agent in explorer planner implementer reviewer verifier; do
  check "$agent.md installed" "[ -f '$CLAUDE_DIR/agents/$agent.md' ]"
done
echo ""

# ── Commands ──────────────────────────────────────────────────────
echo "→ Commands"
for cmd in onboard-project memory-review harness-check; do
  check "$cmd.md installed" "[ -f '$CLAUDE_DIR/commands/$cmd.md' ]"
done
echo ""

# ── Skill ─────────────────────────────────────────────────────────
echo "→ Skill"
check "harness-engineering skill" "[ -f '$CLAUDE_DIR/skills/harness-engineering/SKILL.md' ]"
echo ""

# ── Memory system ─────────────────────────────────────────────────
echo "→ Memory system"
MEMORY_DIR=$(ls -d "$CLAUDE_DIR/projects/"*/memory 2>/dev/null | head -1)
check "memory directory exists"  "[ -d '$MEMORY_DIR' ]"
check "MEMORY.md index exists"   "[ -f '$MEMORY_DIR/MEMORY.md' ]"
echo ""

# ── Brain repo ────────────────────────────────────────────────────
echo "→ Brain repo (~/.claude-brain)"
check "~/.claude-brain exists"   "[ -d '$BRAIN_DIR' ]"
check "git initialized"          "git -C '$BRAIN_DIR' rev-parse --git-dir"
check "memory synced"            "[ -d '$BRAIN_DIR/memory' ]"
HAS_REMOTE=$(git -C "$BRAIN_DIR" remote -v 2>/dev/null | wc -l | tr -d ' ')
if [ "$HAS_REMOTE" -gt 0 ]; then
  echo "  ✓ remote configured"; PASS=$((PASS+1))
else
  echo "  ⚠ no remote — add one: git -C ~/.claude-brain remote add origin <url>"
fi
echo ""

# ── Hook behavior tests ───────────────────────────────────────────
echo "→ Hook behavior (unit tests)"

# protect-files.sh should block rm -rf
BLOCK_TEST=$(echo '{"tool_input":{"command":"rm -rf /tmp/test"}}' | \
  bash "$CLAUDE_DIR/hooks/protect-files.sh" 2>&1; echo "exit:$?")
if echo "$BLOCK_TEST" | grep -q "exit:2"; then
  echo "  ✓ protect-files blocks rm -rf"; PASS=$((PASS+1))
else
  echo "  ✗ protect-files did NOT block rm -rf"; FAIL=$((FAIL+1))
fi

# protect-files.sh should allow normal commands
ALLOW_TEST=$(echo '{"tool_input":{"command":"ls -la"}}' | \
  bash "$CLAUDE_DIR/hooks/protect-files.sh" 2>&1; echo "exit:$?")
if echo "$ALLOW_TEST" | grep -q "exit:0"; then
  echo "  ✓ protect-files allows ls -la"; PASS=$((PASS+1))
else
  echo "  ✗ protect-files blocked ls -la (false positive)"; FAIL=$((FAIL+1))
fi

# protect-paths.sh should block .env reads
BLOCK_ENV=$(echo '{"tool_input":{"file_path":"/project/.env"}}' | \
  bash "$CLAUDE_DIR/hooks/protect-paths.sh" 2>&1; echo "exit:$?")
if echo "$BLOCK_ENV" | grep -q "exit:2"; then
  echo "  ✓ protect-paths blocks .env read"; PASS=$((PASS+1))
else
  echo "  ✗ protect-paths did NOT block .env read"; FAIL=$((FAIL+1))
fi

# protect-paths.sh should allow normal files
ALLOW_FILE=$(echo '{"tool_input":{"file_path":"/project/main.py"}}' | \
  bash "$CLAUDE_DIR/hooks/protect-paths.sh" 2>&1; echo "exit:$?")
if echo "$ALLOW_FILE" | grep -q "exit:0"; then
  echo "  ✓ protect-paths allows main.py"; PASS=$((PASS+1))
else
  echo "  ✗ protect-paths blocked main.py (false positive)"; FAIL=$((FAIL+1))
fi
echo ""

# ── Result ────────────────────────────────────────────────────────
TOTAL=$((PASS+FAIL))
echo "╔══════════════════════════════════════╗"
if [ "$FAIL" -eq 0 ]; then
  echo "║  ✓ ALL CHECKS PASSED ($PASS/$TOTAL)          ║"
  echo "╚══════════════════════════════════════╝"
  echo ""
  echo "Next: open Claude Code and run /harness-check"
  exit 0
else
  echo "║  ✗ $FAIL/$TOTAL CHECKS FAILED                ║"
  echo "╚══════════════════════════════════════╝"
  echo ""
  echo "Fix the failing checks above, then re-run: bash scripts/smoke-test.sh"
  exit 1
fi
