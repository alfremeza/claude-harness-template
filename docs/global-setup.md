# Global Harness Setup — Step by Step

This guide takes you from zero to a fully configured Claude Code harness. Follow in order.

---

## Step 1 — Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

Verify:
```bash
claude --version
```

Set your API key (get it from console.anthropic.com):
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
# Add to ~/.zshrc or ~/.bashrc to persist
```

---

## Step 2 — Create the ~/.claude/ directory structure

Claude Code auto-creates `~/.claude/` on first run. After that, build this structure:

```
~/.claude/
├── CLAUDE.md              ← your global identity (Step 3)
├── settings.json          ← hooks and permissions (Step 4)
├── skills/                ← auto-created by Claude Code
├── agents/                ← auto-created by Claude Code
├── commands/              ← auto-created by Claude Code
└── projects/
    └── -Users-yourname/
        └── memory/        ← you create this (Step 6)
            └── MEMORY.md
```

```bash
mkdir -p ~/.claude/projects/$(echo $HOME | tr '/' '-' | sed 's/^-//')/memory
```

---

## Step 3 — Write your CLAUDE.md

This is the most important file. It's loaded at the start of every session. Keep it tight — every line costs tokens every turn.

```bash
nano ~/.claude/CLAUDE.md
```

Use this structure (copy from `global/CLAUDE.md.example` and fill in):

```markdown
# [Your Name] — Global Context

## Who I am
- [Role and field]
- [Years of experience]
- [Technical level and specializations]

## How to respond — ALWAYS
- [Language preference]
- [Format: bullets / paragraphs / code-first]
- Direct and practical. Answer first, explain after.
- No obvious disclaimers. Don't repeat what I said.
- If you don't know, say so — don't invent.

## Active tool stack
- [Your main tools and platforms]

## Active projects
| Project | Status |
|---|---|
| [Project A] | Operational |
| [Project B] | In development |

## Goals that guide decisions
1. [Most important goal — shapes tradeoffs]
2. [Secondary goal]

## Domain-specific rules
- [Any non-obvious rules the AI must follow]
- Never send identifiable user data to external APIs without explicit instruction.
- [Required fields in any outputs you generate]
```

**What makes a good CLAUDE.md:**
- ✅ Who you are (role + experience level — shapes how Claude explains things)
- ✅ Communication preferences (language, format, tone)
- ✅ Your actual projects with status (so Claude doesn't ask "what are you working on?")
- ✅ Hard rules specific to your domain (medical, legal, financial, etc.)
- ✅ Goals (so Claude understands tradeoffs)
- ❌ Don't include code patterns or architecture — those go in project AGENTS.md
- ❌ Don't include task lists — those belong in memory files
- ❌ Don't make it more than ~60 lines — it loads every single turn

---

## Step 4 — Configure settings.json

```bash
cp path/to/global/settings.json.example ~/.claude/settings.json
```

Edit these key sections:

### Permissions
```json
"permissions": {
  "allow": ["Bash(*)", "Read", "Edit", "Write", "Glob", "Grep"]
}
```
`Bash(*)` means unrestricted bash execution. For experienced users this is fine — it enables fast, frictionless work. If you prefer safety over speed, replace with a specific allowlist.

### SessionStart hook — git sync
```json
"SessionStart": [{
  "hooks": [{
    "type": "command",
    "command": "cd ~ && git pull --rebase 2>/dev/null || true",
    "timeout": 30,
    "statusMessage": "Syncing memory..."
  }]
}]
```
This pulls your memory from your private git repo at session start. Set up the repo in Step 5.

### Observation hooks — target, don't blanket
```json
"PreToolUse": [{ "matcher": "Bash|Edit|Write", ... }],
"PostToolUse": [{ "matcher": "Bash|Edit|Write", ... }]
```
The matcher `"Bash|Edit|Write"` means the hook only fires on operations that change things — not on every Read/Glob/Grep. This avoids adding latency and noise to simple reads.

### SessionEnd hook — auto-commit memory
```json
"SessionEnd": [{
  "hooks": [{
    "type": "command",
    "command": "cd ~ && git add .claude/projects/memory/ && git diff --cached --quiet || git commit -m 'auto: session end' && git push 2>/dev/null || true",
    "async": true
  }]
}]
```

---

## Step 5 — Set up git sync (the "brain repo")

This gives your memory system persistence and backup across devices (Mac, VPS, etc.).

```bash
# 1. Initialize git in your home directory
cd ~
git init
echo "# Brain repo" > README.md

# 2. Create a .gitignore that only tracks Claude memory
cat > ~/.gitignore << 'EOF'
# Track only Claude memory and config
*
!.gitignore
!README.md
!.claude/
.claude/cache/
.claude/history.jsonl
.claude/sessions/
.claude/telemetry/
.claude/shell-snapshots/
.claude/ide/
.claude/debug/
.claude/downloads/
.claude/paste-cache/
.claude/file-history/
.claude/homunculus/
EOF

# 3. Create a PRIVATE repo on GitHub (github.com/new)
# Name it: alfred-brain (or yourname-brain)

# 4. Connect and push
git remote add origin https://github.com/YOURUSER/YOURNAME-brain.git
git add .claude/CLAUDE.md .claude/settings.json .claude/projects/
git commit -m "init: harness setup"
git push -u origin main
```

**Why private?** Your CLAUDE.md may contain personal info, your memory files contain project details and feedback. Keep it private.

**Multi-device sync:** On VPS or other machines, clone the brain repo to home directory. The SessionStart `git pull` hook keeps everything in sync automatically.

```bash
# On VPS:
cd ~
git clone https://github.com/YOURUSER/YOURNAME-brain.git .
```

---

## Step 6 — Set up the memory system

```bash
# Create the memory directory
MEMORY_PATH=~/.claude/projects/$(echo $HOME | sed 's|/|-|g' | sed 's/^-//')/memory
mkdir -p "$MEMORY_PATH"

# Create the index file
cat > "$MEMORY_PATH/MEMORY.md" << 'EOF'
# Memory Index

(Entries will be added automatically by Claude as you work)
EOF
```

The memory system works automatically once configured. Claude will:
- Save relevant information to individual `.md` files in `memory/`
- Keep `MEMORY.md` as a one-line-per-entry index
- Load relevant memories at the start of each session

**Memory types Claude uses:**
- `user_*.md` — your profile, preferences, expertise
- `feedback_*.md` — corrections and validated approaches
- `project_*.md` — state of ongoing projects
- `reference_*.md` — where to find external resources

See `docs/memory-system.md` for full details.

---

## Step 7 — Install the Superpowers plugin (recommended)

Superpowers adds advanced orchestration capabilities: sub-agents, parallel execution, brainstorming, systematic debugging, and more.

```bash
# In Claude Code, run:
/install-plugin superpowers
```

Or install manually by following instructions at the plugin's GitHub page.

After installation, you'll have access to skills like:
- `superpowers:brainstorming` — structured brainstorming before implementation
- `superpowers:systematic-debugging` — step-by-step debugging protocol
- `superpowers:dispatching-parallel-agents` — run multiple agents in parallel

---

## Step 8 — Curate your skills

Skills are loaded **on-demand** (not all at once), but the index of available skills appears in every session as a system reminder. A bloated index adds contextual noise.

```bash
# See how many skills you have
ls ~/.claude/skills/ | wc -l
```

**Target: 200–320 skills.** More than that starts degrading response quality.

**What to remove:** skills for domains you'll never work in.

```bash
# Example: remove bioinformatics skills if not relevant to you
cd ~/.claude/skills
rm -rf anndata biopython cellxgene deepchem deeptools \
       genomics lamindb molecular-dynamics qiskit rdkit \
       scvelo torch-geometric zarr-python
# (adjust based on your actual stack)
```

**What to keep:** everything relevant to your languages, frameworks, domains, and workflows.

See `docs/skills-guide.md` for a full categorized list.

---

## Step 9 — Verify your setup

Open a new Claude Code session. You should see:
- ✅ Session starts with a git pull
- ✅ Claude references your CLAUDE.md context (responds in your preferred language, knows your projects)
- ✅ Memory files appear in `~/.claude/projects/.../memory/`
- ✅ At session end, memory gets committed and pushed

**Test prompt:**
```
Who am I and what are my active projects?
```
Claude should answer accurately from your CLAUDE.md without you explaining anything.

---

## Checklist

- [ ] Claude Code installed and API key set
- [ ] `~/.claude/CLAUDE.md` written with profile, projects, goals, domain rules
- [ ] `~/.claude/settings.json` configured with all hooks
- [ ] Private git repo created for memory sync (the "brain repo")
- [ ] `.gitignore` configured to track only Claude files
- [ ] `memory/MEMORY.md` created as index
- [ ] First `git push` to brain repo done
- [ ] Superpowers plugin installed
- [ ] Skills list curated to relevant domains
- [ ] Test session confirms Claude reads your context correctly

---

## What's next

→ **Add your first project to the harness:** `docs/project-onboarding.md`
→ **Understand the memory system in depth:** `docs/memory-system.md`
→ **Curate your skills list:** `docs/skills-guide.md`
