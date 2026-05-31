# Claude Code Harness Template

Templates and guides for structuring a production-grade Claude Code harness — built from real experience with medical automation, trading bots, and web applications.

## What is a harness?

The harness is everything surrounding the AI model: the context it receives, the tools it can use, the memory it holds, and the rules it follows. The model is the brain. The harness is the nervous system that controls it.

> "The most impactful improvements in AI-assisted development come not from better models, but from better harnesses around those models." — Betta Tech

## The 3 Pillars

### 1. Repository as System
The files in your repo define how the AI behaves. Not the chat prompt — the files.
- `~/.claude/CLAUDE.md` → global identity, preferences, domain rules
- `AGENTS.md` per project → architecture, rules, known bugs, pipeline
- `settings.json` → hooks, permissions, plugins

### 2. Multi-Agent Orchestration
Never use a single agent for everything. Use focused roles with minimal context:

| Role | Responsibility |
|---|---|
| **explorer** | Read-only. Understand the codebase before touching anything. |
| **planner** | Propose changes with exact files and line numbers. |
| **implementer** | Apply the change. Nothing else. |
| **reviewer** | Review diff for correctness and risks. |
| **verifier** | Run `verify.sh`. Must pass before declaring done. |

### 3. Mandatory Verification
The AI cannot declare "I'm done" without proof. Every project needs a `verify.sh` that objectively validates the state.

---

## Repository Structure

```
claude-harness-template/
├── global/
│   ├── CLAUDE.md.example        # Global system prompt template
│   └── settings.json.example    # Hooks configuration template
├── project/
│   ├── AGENTS.md.template       # Per-project harness template
│   └── scripts/
│       └── verify.sh.template   # Quality gate template (Python + Node variants)
├── skills/
│   └── harness-engineering/
│       └── SKILL.md             # Invocable skill for Claude Code
└── docs/
    ├── philosophy.md            # Deep dive on the 3 pillars
    ├── global-setup.md          # Step-by-step global harness setup
    └── project-onboarding.md   # How to onboard a new project
```

---

## Quick Start

### 1. Global harness setup

```bash
# Copy the global CLAUDE.md template
cp global/CLAUDE.md.example ~/.claude/CLAUDE.md

# Edit with your profile, stack, and preferences
# Then configure hooks:
cp global/settings.json.example ~/.claude/settings.json
```

### 2. Add a project to the harness

```bash
# In your project root:
cp path/to/project/AGENTS.md.template ./AGENTS.md
cp path/to/project/scripts/verify.sh.template ./scripts/verify.sh
chmod +x ./scripts/verify.sh

# Edit AGENTS.md with your project's architecture, rules, known bugs
# Edit verify.sh with your test commands

# Test it:
bash scripts/verify.sh
```

### 3. Install the skill (Claude Code)

```bash
# Copy the skill to your Claude Code skills directory
mkdir -p ~/.claude/skills/harness-engineering
cp skills/harness-engineering/SKILL.md ~/.claude/skills/harness-engineering/SKILL.md
```

Then invoke with `/harness-engineering` in Claude Code.

---

## Key Principles

### Less is more with tools
Vercel removed 80% of their AI agent tools and saw a 3x speed improvement with 37% fewer tokens. Give your AI simple, general tools — not hundreds of specialized ones.

### Context degrades at 40%
Research shows AI quality degrades well before the context window fills. Start a new session or run `/compact` proactively around 40% context usage.

### Memory outside the window
Save important context to external files (memory/, progress/, specs/). The AI's in-context window is precious — don't fill it with things that can live in files.

### Hooks: target, don't blanket
Running observation hooks on every single tool call (including reads) adds latency and noise. Target `Bash|Edit|Write` — the operations that actually change things.

---

## Project Types Supported

This template includes examples for:

- **Python API (FastAPI/Flask)** — pytest + systemctl service check
- **Full-stack (Vue/React + FastAPI)** — vitest + pytest + TypeScript check
- **Telegram Bot (Python)** — pytest + env var check + service status
- **VPS-deployed services** — SSH-compatible verify.sh

---

## Contributing

If you've built a harness pattern that works well, open a PR. The most valuable contributions are:
- `verify.sh` templates for new project types
- `AGENTS.md` templates for specific frameworks
- Anti-patterns discovered in real use

---

## References

- [Harness Engineering video series by Betta Tech](https://www.youtube.com/@betta-tech) — the concept explained
- [BYO Coding Agent repo](https://github.com/betta-tech/byo-coding-agent) — build your own agent from scratch
- [Anthropic multi-agent guide](https://docs.anthropic.com/en/docs/build-with-claude/agents)
- [Claude Code hooks documentation](https://docs.anthropic.com/en/docs/claude-code/hooks)
