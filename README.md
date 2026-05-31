# Claude Code Harness Template

A complete, battle-tested template for structuring a production-grade Claude Code harness — built from real experience with medical automation, trading bots, and full-stack web applications.

## What is a harness?

The harness is everything surrounding the AI model: the context it receives, the tools it can use, the memory it holds, and the rules it follows. The model is the brain. The harness is the nervous system that controls it.

> "The most impactful improvements in AI-assisted development come not from better models, but from better harnesses around those models."

Vercel confirmed this empirically: removing 80% of specialized tools from their AI agent produced **3x faster execution with 37% fewer tokens**. The model didn't change. The harness did.

---

## The 3 Pillars

### 1. Repository as System
The files in your repo define how the AI behaves. Not the chat prompt — the files.
- `~/.claude/CLAUDE.md` → global identity, preferences, domain rules
- `AGENTS.md` per project → architecture, rules, known bugs, work pipeline
- `settings.json` → hooks, permissions, plugins

### 2. Multi-Agent Orchestration
Never use a single agent for everything. Use focused roles with minimal context each:

| Role | Responsibility |
|---|---|
| **explorer** | Read-only. Understand the codebase before touching anything. |
| **planner** | Propose changes with exact files and line numbers. |
| **implementer** | Apply the change. Nothing else. |
| **reviewer** | Review diff for correctness and risks. |
| **verifier** | Run `verify.sh`. Must PASS before declaring done. |

### 3. Mandatory Verification
The AI cannot declare "I'm done" without proof. Every project needs a `verify.sh` that objectively validates the state — tests, type checks, service health, env vars.

---

## Repository Contents

```
claude-harness-template/
│
├── global/
│   ├── CLAUDE.md.example        # Global system prompt template
│   └── settings.json.example    # Hooks configuration (SessionStart, PostCompact, SessionEnd)
│
├── project/
│   ├── AGENTS.md.template       # Per-project harness template (fill in for every project)
│   └── scripts/
│       └── verify.sh.template   # Quality gate template (Python + Node + VPS variants)
│
├── examples/
│   ├── web-app/
│   │   └── AGENTS.md            # Full-stack app example (Vue 3 + FastAPI + WeasyPrint)
│   ├── telegram-bot/
│   │   └── AGENTS.md            # Telegram bot example (Python + Claude API + Drive)
│   └── vps-service/
│       └── verify.sh            # VPS service quality gate (pytest + systemd + env vars)
│
├── skills/
│   └── harness-engineering/
│       └── SKILL.md             # Invocable Claude Code skill — full reference guide
│
└── docs/
    ├── philosophy.md            # Deep dive: why harnesses matter more than models
    ├── global-setup.md          # Step-by-step: set up your global harness from scratch
    ├── project-onboarding.md    # How to onboard any project to the harness
    ├── memory-system.md         # Memory architecture, types, git sync, maintenance
    └── skills-guide.md          # What skills to install, what to remove, how to curate
```

---

## Quick Start

### New to harnesses — start here

1. Read `docs/philosophy.md` — understand why this works (10 min)
2. Follow `docs/global-setup.md` — set up your global harness step by step
3. Add your first project: `docs/project-onboarding.md`

### Already using Claude Code — upgrade your setup

1. Check your `~/.claude/CLAUDE.md` against `global/CLAUDE.md.example` — fill gaps
2. Configure hooks: copy relevant sections from `global/settings.json.example`
3. For each active project: create `AGENTS.md` and `scripts/verify.sh`

### Adding the harness to a specific project

```bash
# In your project root:
cp path/to/project/AGENTS.md.template ./AGENTS.md
mkdir -p scripts
cp path/to/project/scripts/verify.sh.template ./scripts/verify.sh
chmod +x scripts/verify.sh

# Edit both files for your project, then test:
bash scripts/verify.sh
```

### Installing the Claude Code skill

```bash
mkdir -p ~/.claude/skills/harness-engineering
cp skills/harness-engineering/SKILL.md ~/.claude/skills/harness-engineering/SKILL.md
```

Invoke in Claude Code with `/harness-engineering` whenever you need the full reference.

---

## Key Principles

### Less is more with tools
Give your AI simple, general tools — not hundreds of specialized ones. The index of available skills appears in every session. 200–320 skills is the sweet spot; 400+ adds noise. See `docs/skills-guide.md`.

### Context degrades at 40%
AI quality degrades well before the context window fills. Run `/compact` proactively around 40% context usage, not reactively when things go wrong.

### Memory outside the window
Store context in files (`AGENTS.md`, `memory/`, `progress/`), not in the conversation. The conversation window is expensive and volatile. Files are cheap and persistent.

### Hooks: target, don't blanket
Use `"Bash|Edit|Write"` as the hook matcher, not `"*"`. Observation hooks on every Read/Glob/Grep add latency without value — only changes matter.

### Verify, don't trust
Claude is trained to be helpful and complete tasks — it will tend to declare success. A `verify.sh` is the only objective signal that something is actually done.

---

## Project Types Covered

| Project Type | Template Location |
|---|---|
| Full-stack web app (Vue/React + FastAPI/Django) | `examples/web-app/AGENTS.md` |
| Telegram/WhatsApp automation bot | `examples/telegram-bot/AGENTS.md` |
| VPS-deployed Python service | `examples/vps-service/verify.sh` |
| Generic project | `project/AGENTS.md.template` |

---

## The Memory System

The harness includes a persistent memory system that survives across sessions and devices:

```
~/.claude/projects/memory/
├── MEMORY.md            ← index (one line per memory, max 200 lines)
├── user_*.md            ← who you are, your expertise, preferences
├── feedback_*.md        ← corrections and confirmed approaches
├── project_*.md         ← state of ongoing projects
└── reference_*.md       ← where external resources live
```

Memory syncs across devices via a private git repo (the "brain repo" pattern). See `docs/memory-system.md` for full setup.

---

## Checklist — Harness at 100%

**Global harness:**
- [ ] `~/.claude/CLAUDE.md` — profile, stack, projects, domain rules
- [ ] `~/.claude/settings.json` — SessionStart, PreToolUse (Bash|Edit|Write), PostCompact, SessionEnd hooks
- [ ] Private git repo ("brain repo") for memory sync
- [ ] `memory/MEMORY.md` created as index
- [ ] Superpowers plugin installed
- [ ] Skills curated to 200–320 relevant to your stack

**Per project:**
- [ ] `AGENTS.md` in project root with all sections filled
- [ ] `scripts/verify.sh` created, executable, passes in clean state
- [ ] Project in global CLAUDE.md projects table
- [ ] Project memory file created and indexed

---

## Contributing

Contributions welcome. Most valuable:
- `verify.sh` templates for project types not covered
- `AGENTS.md` examples for specific frameworks (Next.js, NestJS, Laravel, etc.)
- Documented anti-patterns discovered in real use

---

## References

- [Harness Engineering series — Betta Tech](https://www.youtube.com/@betta-tech)
- [BYO Coding Agent (educational repo)](https://github.com/betta-tech/byo-coding-agent)
- [Anthropic multi-agent guide](https://docs.anthropic.com/en/docs/build-with-claude/agents)
- [Claude Code hooks documentation](https://docs.anthropic.com/en/docs/claude-code/hooks)
