#!/usr/bin/env bash
# install.sh — Automated harness setup from this template
# Run from the cloned template directory:
#   bash scripts/install.sh
set -euo pipefail

TEMPLATE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║  Claude Code Harness — Install       ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── Prerequisites ─────────────────────────────────────────────────
echo "→ Checking prerequisites..."

command -v claude >/dev/null 2>&1 || {
  echo "✗ Claude Code not found. Install: npm install -g @anthropic-ai/claude-code"
  exit 1
}
echo "  ✓ Claude Code: $(claude --version 2>/dev/null | head -1)"

command -v git >/dev/null 2>&1 || { echo "✗ git not found"; exit 1; }
echo "  ✓ git: $(git --version)"

[ -n "${ANTHROPIC_API_KEY:-}" ] || {
  echo "  ⚠ ANTHROPIC_API_KEY not set. Add to ~/.zshrc or ~/.bashrc:"
  echo "    export ANTHROPIC_API_KEY='sk-ant-...'"
}

echo ""

# ── Create ~/.claude/ structure ───────────────────────────────────
echo "→ Creating ~/.claude/ structure..."
mkdir -p "$CLAUDE_DIR"/{skills,agents,commands,hooks}

# Memory directory (path varies by OS)
MEMORY_PATH=$(python3 -c "import os; p=os.path.expanduser('~'); print(p.replace('/','-').lstrip('-'))" 2>/dev/null || echo "Users-$(whoami)")
MEMORY_DIR="$CLAUDE_DIR/projects/-$MEMORY_PATH/memory"
mkdir -p "$MEMORY_DIR"
echo "  ✓ Structure created"
echo "  ✓ Memory dir: $MEMORY_DIR"
echo ""

# ── CLAUDE.md ─────────────────────────────────────────────────────
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  echo "→ CLAUDE.md already exists — skipping (edit manually if needed)"
else
  cp "$TEMPLATE_DIR/global/CLAUDE.md.example" "$CLAUDE_DIR/CLAUDE.md"
  echo "→ CLAUDE.md created — IMPORTANT: edit this file with your profile"
  echo "  File: $CLAUDE_DIR/CLAUDE.md"
fi
echo ""

# ── settings.json ─────────────────────────────────────────────────
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  echo "→ settings.json already exists — skipping"
else
  echo "→ Choose settings profile:"
  echo "  [1] fast  — unrestricted Bash, zero friction (recommended for solo devs)"
  echo "  [2] safe  — allowlist-based, adds security hook (recommended for teams)"
  read -r -p "  Choice [1/2]: " SETTINGS_CHOICE

  case "$SETTINGS_CHOICE" in
    2)
      cp "$TEMPLATE_DIR/global/settings.safe.json.example" "$CLAUDE_DIR/settings.json"
      echo "  ✓ settings.safe.json installed"
      ;;
    *)
      cp "$TEMPLATE_DIR/global/settings.fast.json.example" "$CLAUDE_DIR/settings.json"
      echo "  ✓ settings.fast.json installed"
      ;;
  esac
fi
echo ""

# ── Security hook (for safe profile) ─────────────────────────────
if [ -f "$CLAUDE_DIR/hooks/protect-files.sh" ]; then
  echo "→ protect-files.sh already exists — skipping"
else
  cp "$TEMPLATE_DIR/global/hooks/protect-files.sh" "$HOOKS_DIR/protect-files.sh"
  chmod +x "$HOOKS_DIR/protect-files.sh"
  echo "  ✓ protect-files.sh installed"
fi

if [ -f "$HOOKS_DIR/protect-paths.sh" ]; then
  echo "→ protect-paths.sh already exists — skipping"
else
  cp "$TEMPLATE_DIR/global/hooks/protect-paths.sh" "$HOOKS_DIR/protect-paths.sh"
  chmod +x "$HOOKS_DIR/protect-paths.sh"
  echo "  ✓ protect-paths.sh installed"
fi
echo ""

# ── Agents ────────────────────────────────────────────────────────
echo "→ Installing agents..."
AGENTS_INSTALLED=0
for agent in "$TEMPLATE_DIR/agents/"*.md; do
  name=$(basename "$agent")
  if [ ! -f "$CLAUDE_DIR/agents/$name" ]; then
    cp "$agent" "$CLAUDE_DIR/agents/$name"
    AGENTS_INSTALLED=$((AGENTS_INSTALLED+1))
  fi
done
echo "  ✓ $AGENTS_INSTALLED agents installed (explorer, planner, implementer, reviewer, verifier)"
echo ""

# ── Commands ──────────────────────────────────────────────────────
echo "→ Installing commands..."
CMDS_INSTALLED=0
for cmd in "$TEMPLATE_DIR/commands/"*.md; do
  name=$(basename "$cmd")
  if [ ! -f "$CLAUDE_DIR/commands/$name" ]; then
    cp "$cmd" "$CLAUDE_DIR/commands/$name"
    CMDS_INSTALLED=$((CMDS_INSTALLED+1))
  fi
done
echo "  ✓ $CMDS_INSTALLED commands installed"
echo ""

# ── Skill ─────────────────────────────────────────────────────────
echo "→ Installing harness-engineering skill..."
mkdir -p "$CLAUDE_DIR/skills/harness-engineering"
cp "$TEMPLATE_DIR/skills/harness-engineering/SKILL.md" \
   "$CLAUDE_DIR/skills/harness-engineering/SKILL.md"
echo "  ✓ Skill installed — invoke with /harness-engineering"
echo ""

# ── Memory index ──────────────────────────────────────────────────
if [ ! -f "$MEMORY_DIR/MEMORY.md" ]; then
  cat > "$MEMORY_DIR/MEMORY.md" << 'EOF'
# Memory Index

(Memories will be added automatically by Claude as you work)
EOF
  echo "→ Memory index created: $MEMORY_DIR/MEMORY.md"
else
  echo "→ Memory index already exists — skipping"
fi
echo ""

# ── Git brain repo (~/.claude-brain/) ────────────────────────────
BRAIN_DIR="$HOME/.claude-brain"
echo "→ Git brain repo setup ($BRAIN_DIR)..."
mkdir -p "$BRAIN_DIR"
cd "$BRAIN_DIR"

if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "  ✓ Brain repo already initialized at $BRAIN_DIR"
else
  git init

  cat > "$BRAIN_DIR/.gitignore" << 'EOF'
.DS_Store
*.log
*.tmp
*.pyc
__pycache__/
EOF

  echo "# Claude Brain — private memory sync" > "$BRAIN_DIR/README.md"
  echo "  ✓ Git initialized at $BRAIN_DIR"
fi

# Copy Claude memory + config into brain dir (never secrets)
echo "  → Syncing memory and config..."
mkdir -p "$BRAIN_DIR/memory"

# Copy MEMORY.md and all memory files
if [ -d "$MEMORY_DIR" ]; then
  cp -r "$MEMORY_DIR/." "$BRAIN_DIR/memory/"
  echo "  ✓ Memory files synced"
fi

# Copy CLAUDE.md (global config — no secrets)
[ -f "$CLAUDE_DIR/CLAUDE.md" ] && cp "$CLAUDE_DIR/CLAUDE.md" "$BRAIN_DIR/CLAUDE.md"

# Copy settings.json (hooks config — no secrets, no tokens)
[ -f "$CLAUDE_DIR/settings.json" ] && cp "$CLAUDE_DIR/settings.json" "$BRAIN_DIR/settings.json"

# Initial commit
cd "$BRAIN_DIR"
git add . 2>/dev/null || true
git diff --cached --quiet 2>/dev/null || git commit -m "init: harness brain setup" 2>/dev/null || true

echo ""
echo "  ⚠ NEXT STEP: Create a PRIVATE repo on GitHub and connect:"
echo "    1. Go to https://github.com/new → name it: yourname-brain (private!)"
echo "    2. Run:"
echo "       cd ~/.claude-brain"
echo "       git remote add origin https://github.com/YOURUSER/YOURNAME-brain.git"
echo "       git push -u origin main"
echo ""
echo "  What goes in ~/.claude-brain/ (safe to sync):"
echo "    ✓ memory/     — project state, feedback, references"
echo "    ✓ CLAUDE.md   — your global profile"
echo "    ✓ settings.json — hooks config"
echo "    ✗ .env files  — never"
echo "    ✗ API keys    — never"
echo "    ✗ credentials — never"
echo ""

# ── Summary ───────────────────────────────────────────────────────
echo "╔══════════════════════════════════════╗"
echo "║  Installation complete               ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Edit $CLAUDE_DIR/CLAUDE.md with your profile, stack, and projects"
echo "  2. Create your brain repo on GitHub (private) and push"
echo "  3. Add your first project: run /onboard-project in Claude Code"
echo "  4. Invoke /harness-check to verify everything is working"
echo ""
echo "Docs: https://github.com/alfremeza/claude-harness-template"
