# Memory System — How It Works

Claude Code's default behavior: every session starts fresh. No memory of previous work, bugs you fixed, patterns you established, or feedback you gave.

The memory system solves this. It gives Claude persistent context across sessions, devices, and projects.

---

## Architecture

```
~/.claude/projects/
└── -Users-yourname/        ← derived from your home directory path
    └── memory/
        ├── MEMORY.md        ← INDEX ONLY — one line per memory file
        ├── user_role.md
        ├── user_preferences.md
        ├── feedback_testing.md
        ├── feedback_git_workflow.md
        ├── project_main_app.md
        ├── project_api_service.md
        └── reference_vps.md
```

**The rule:** `MEMORY.md` is an index — never write content there. Content lives in individual files.

---

## The 4 memory types

### `user_*.md` — Who you are
Information about your role, expertise, preferences, and knowledge level.

Claude reads these to calibrate: how to explain things, what to assume you already know, how much detail to give.

**When to save:** when Claude learns something about you that changes how it should respond.

```markdown
---
name: user-role
description: Alfredo is a cardiologist specializing in echocardiography — frame technical explanations accordingly
metadata:
  type: user
---

# User Profile

- Cardiologist and internist, 9 years experience
- Specialization: cardiovascular imaging (echo, ECG, Holter, MAPA)
- Technical level: intermediate-advanced with AI tools
- Deep clinical knowledge — no need to explain medical concepts
- Explain code/technical concepts in relation to medical analogies when helpful
```

### `feedback_*.md` — How to work with you
Corrections you've given (what NOT to do) and confirmed approaches (what works well).

This is the highest-value memory type. It prevents Claude from repeating the same mistakes session after session.

**Body structure:** Lead with the rule, then **Why:** (reason), then **How to apply:** (when it matters).

```markdown
---
name: feedback-testing-approach
description: Integration tests must hit real database — no mocks. Prior incident where mock tests passed but prod migration failed.
metadata:
  type: feedback
---

Integration tests must use a real database, never mocks.

**Why:** We got burned when mocked tests passed but a production migration failed — the mock was hiding a schema mismatch that only appeared with real data.

**How to apply:** Any time writing tests for database-touching code, use the test database (TEST_DB_URL), not in-memory mocks or sqlite substitutes.
```

### `project_*.md` — State of ongoing work
Facts about projects that aren't obvious from the code: current status, decisions made and why, who's working on what, upcoming deadlines.

**Body structure:** Lead with the fact, then **Why:** (motivation), then **How to apply:** (how it should shape suggestions).

```markdown
---
name: project-checkout-service
description: Checkout service — active refactor for Stripe v3 migration, deadline 2026-06-15
metadata:
  type: project
---

# Checkout Service

Migrating from Stripe v2 to v3 API. All new endpoints must use v3 SDK.

**Why:** Stripe is deprecating v2 on 2026-08-01. Legal requirement to migrate before then.

**How to apply:** Any code touching Stripe must use `stripe.v3.*` methods. Don't suggest v2 patterns even if they're simpler.

## Current state (2026-05-31)
- ✅ Payment intent flow: migrated
- 🔄 Refund flow: in progress
- ⏳ Webhook handlers: pending
```

### `reference_*.md` — Where things live
Pointers to external resources: VPS details, API docs, dashboards, tools.

```markdown
---
name: reference-vps
description: VPS SSH access and key services — Brasil region, Hostinger KVM2
metadata:
  type: reference
---

# VPS — Production Server

- **IP:** [your.vps.ip]
- **SSH:** `ssh root@[ip]`
- **Region:** Brazil (Hostinger KVM2)
- **Services:**
  - `main-api` — main application API
  - `bot-listener` — Telegram bot
- **Deploy:** `cd /root/app && git pull && systemctl restart main-api`
```

---

## MEMORY.md — The index

`MEMORY.md` is always loaded into every session. Keep it under 200 lines — lines beyond that get truncated.

**Format:** one line per memory, with a link and a hook describing why it matters.

```markdown
# Memory Index

- [User Role](user_role.md) — Cardiologist, 9yr experience, explains tech via medical analogies
- [Feedback: Testing](feedback_testing.md) — Integration tests hit real DB — burned by mock/prod divergence
- [Feedback: Git Workflow](feedback_git_workflow.md) — Bundled PRs preferred for refactors in this codebase
- [Project: Main App](project_main_app.md) — Vue3+FastAPI, v2.5.2 operativo, 107 tests
- [Project: API Service](project_api_service.md) — Stripe v3 migration, deadline 2026-06-15
- [Reference: VPS](reference_vps.md) — SSH, IP, key services, deploy commands
```

**Keep each line under ~150 characters.** The hook must be specific enough that Claude can decide if a memory is relevant without opening the file.

---

## Git sync — The "brain repo" pattern

Memory persists across devices through a private git repository.

**How it works:**
1. `SessionStart` hook: `git pull --rebase` — syncs latest memories from remote
2. `PostCompact` hook: `git commit` — saves after context compaction
3. `SessionEnd` hook: `git commit && git push` — saves and pushes at end of session

**Result:** work on your Mac → memory syncs to VPS → continue on VPS with full context. Same in reverse.

**Setup (if not done yet):**
```bash
cd ~
git init
git remote add origin https://github.com/YOURUSER/YOURNAME-brain.git
# See global-setup.md Step 5 for full setup
```

---

## What to save and what NOT to save

### Save in memory:
- ✅ Who you are and how to work with you
- ✅ Corrections to Claude's behavior ("don't do X because Y happened")
- ✅ Confirmed approaches that worked ("bundled PRs for this codebase")
- ✅ Project status that isn't in the code (current sprint, blockers, decisions made)
- ✅ Where external resources live (VPS, dashboards, issue trackers)
- ✅ Domain rules that aren't obvious (compliance requirements, clinical thresholds)

### Don't save in memory:
- ❌ Code patterns and conventions — that's what AGENTS.md is for
- ❌ Git history and recent changes — `git log` is authoritative
- ❌ Bug fixes and solutions — the fix is in the code; commit message has context
- ❌ Architecture and file structure — that goes in AGENTS.md
- ❌ Ephemeral task lists — use tasks/progress files instead
- ❌ Anything already in CLAUDE.md or AGENTS.md

---

## Before acting on a memory — verify it

A memory that mentions a specific file, function, or URL is a claim about the past. Things change.

**Before recommending based on a memory:**
- If it names a file path: check the file exists
- If it names a function: grep for it
- If it describes project status: verify against current state

Memory says X exists ≠ X exists now. Trust the current code over old memories when they conflict. Then update the stale memory.

---

## Monthly maintenance

Memory files can become outdated or misleading. Schedule a monthly review:

```bash
# List all memory files and their size
ls -la ~/.claude/projects/*/memory/*.md

# Open MEMORY.md and scan for stale entries
cat ~/.claude/projects/*/memory/MEMORY.md
```

**For each project memory:**
- Is the status still accurate?
- Are the "in progress" items still in progress or done?
- Are there decisions listed that were reversed?

**For feedback memories:**
- Is this feedback still the right approach?
- Did the project/codebase change enough that this no longer applies?

Update or delete stale memories rather than letting them accumulate. A small, accurate memory index is more valuable than a large, outdated one.
