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
| **reviewer** | Review diff for correctness and AGENTS.md compliance. |
| **verifier** | Run `verify.sh`. Must PASS before declaring done. |

### 3. Mandatory Verification
The AI cannot declare "I'm done" without proof. Every project needs a `verify.sh` that objectively validates the state — tests, type checks, service health, env vars.

---

## Repository Structure

```
claude-harness-template/
│
├── agents/                          ← 5 real agent files with protocols
│   ├── explorer.md                  # read-only codebase mapper
│   ├── planner.md                   # line-level implementation planner
│   ├── implementer.md               # focused executor, scope discipline
│   ├── reviewer.md                  # AGENTS.md compliance + correctness
│   └── verifier.md                  # binary quality gate sign-off
│
├── commands/                        ← 3 slash commands
│   ├── onboard-project.md           # /onboard-project — interactive project setup
│   ├── memory-review.md             # /memory-review — monthly memory audit
│   └── harness-check.md             # /harness-check — full health check
│
├── global/
│   ├── CLAUDE.md.example            # global system prompt template
│   ├── settings.fast.json.example   # unrestricted Bash — power users, solo devs
│   ├── settings.safe.json.example   # allowlist + security hooks — teams, sensitive data
│   └── hooks/
│       ├── protect-files.sh         # PreToolUse/Bash — blocks dangerous commands (exit 2)
│       └── protect-paths.sh         # PreToolUse/Read|Edit|Write|MultiEdit — blocks sensitive file paths
│
├── project/
│   ├── AGENTS.md.template           # per-project harness template
│   └── scripts/
│       ├── verify.python.sh         # pytest + syntax + env vars
│       ├── verify.node.sh           # vitest/jest + TypeScript + lint
│       ├── verify.fullstack.sh      # Python backend + Node frontend
│       ├── verify.vps.sh            # pytest + systemd + env vars
│       └── verify.minimal.sh        # syntax only — upgrade path included
│
├── examples/
│   ├── web-app/AGENTS.md            # full-stack example (Vue 3 + FastAPI)
│   ├── telegram-bot/AGENTS.md       # Python bot + Claude API + Drive
│   └── vps-service/verify.sh        # VPS quality gate example
│
├── skills/
│   └── harness-engineering/
│       └── SKILL.md                 # invocable Claude Code skill — full reference
│
├── scripts/
│   ├── install.sh                   # one-command automated setup
│   └── smoke-test.sh                # post-install verification with hook unit tests
│
└── docs/
    ├── philosophy.md                # why harnesses matter more than models
    ├── global-setup.md              # step-by-step from zero to working harness
    ├── project-onboarding.md        # how to add any project to the harness
    ├── memory-system.md             # memory types, git sync, maintenance
    └── skills-guide.md              # what to install, what to remove, how to curate
```

---

## Quick Start

### New to harnesses — start here

```bash
git clone https://github.com/alfremeza/claude-harness-template
bash claude-harness-template/scripts/install.sh
```

The install script will:
- Check prerequisites (Claude Code, git)
- Create `~/.claude/` structure
- Prompt you to choose **fast** (unrestricted) or **safe** (allowlist + security hooks) profile
- Install agents, commands, and the harness-engineering skill
- Set up the memory system
- Guide you through creating your brain repo

### Smoke test after install

Run the automated smoke test — it checks all components and runs unit tests for the security hooks:

```bash
bash claude-harness-template/scripts/smoke-test.sh
```

It verifies: Claude Code installed, security hooks working, agents present, brain repo initialized, memory system in place. Exit 0 = ready. Exit 1 = something needs fixing.

Then open Claude Code in any project and run:
```
/harness-check
```
It will audit the full harness and report what's working and what's missing.

---

### Already using Claude Code — upgrade your setup

1. Copy the relevant settings profile to `~/.claude/settings.json`
2. Install agents: copy `agents/*.md` → `~/.claude/agents/`
3. Install commands: copy `commands/*.md` → `~/.claude/commands/`
4. Install the skill: copy `skills/harness-engineering/SKILL.md` → `~/.claude/skills/harness-engineering/`
5. For each active project: add `AGENTS.md` and `scripts/verify.sh`

### Adding the harness to a project

```bash
# In your project root:
cp path/to/project/AGENTS.md.template ./AGENTS.md
mkdir -p scripts

# Choose the right verify.sh for your stack:
# Python:     verify.python.sh
# Node/TS:    verify.node.sh
# Full-stack: verify.fullstack.sh
# VPS:        verify.vps.sh
# No tests:   verify.minimal.sh

cp path/to/project/scripts/verify.YOURTYPE.sh ./scripts/verify.sh
chmod +x scripts/verify.sh

# Edit AGENTS.md and verify.sh for your project, then test:
bash scripts/verify.sh
```

---

## Settings Profiles

Choose based on your context:

| Profile | When to use | Bash access | Security hooks |
|---|---|---|---|
| `settings.fast.json` | Solo developer, experienced, trusted environment | Unrestricted | Observation only |
| `settings.safe.json` | Teams, medical/financial data, beginners, VPS with sensitive credentials | Allowlist | protect-files.sh + protect-paths.sh |

**Recommendation:** If you work with patient data, API keys for financial services, or shared VPS credentials — use `settings.safe.json`. The friction is minimal; the protection is real.

### How the security hooks work

`protect-files.sh` (matcher: `Bash`) — blocks commands that touch:
- `.env`, `.pem`, `.key`, `credentials.json`, `id_rsa`
- `rm -rf`, `git reset --hard`, `git push --force`
- Pipe-to-shell patterns (`curl ... | bash`)
- Uses **exit 2** (Claude Code hook block code)

`protect-paths.sh` (matcher: `Read|Edit|Write|MultiEdit`) — blocks read and write access to:
- `.env`, `.pem`, `.key`, `credentials.json`, `secrets.*`
- Private key files, service account files
- Uses **exit 2**

Both hooks parse `tool_input.command` / `tool_input.file_path` with fallback to `input.*` for compatibility.

---

## Key Principles

### Less is more with tools
Give your AI simple, general tools — not hundreds of specialized ones. The index of available skills appears in every session. 200–320 skills is the sweet spot; 400+ adds noise. See `docs/skills-guide.md`.

### Context degrades at 40%
AI quality degrades well before the context window fills. Run `/compact` proactively around 40% context usage.

### Memory outside the window
Store context in files (`AGENTS.md`, `memory/`, `progress/`), not in the conversation. Files are cheap and persistent. The context window is expensive and volatile.

### Hooks: target, don't blanket
Use `"Bash|Edit|Write"` as the observation hook matcher, not `"*"`. Hooks on every Read/Glob/Grep add latency without value.

### Brain repo: dedicated directory, not $HOME
The memory sync pattern works best with a dedicated directory (e.g., `~/.claude-brain/`) rather than `git init` in `$HOME`. Git in home can cause unexpected behavior with other tools that check for `.git`. See `docs/global-setup.md` for the recommended approach.

### Verify, don't trust
A `verify.sh` is the only objective signal that something is done. Use **exit 2** in PreToolUse hooks to block — exit 1 signals an error but does not block in Claude Code.

---

## Project Types Covered

| Project Type | verify.sh |
|---|---|
| Python (Flask, FastAPI, scripts) | `verify.python.sh` |
| Node/TypeScript (Next.js, Express, etc.) | `verify.node.sh` |
| Full-stack (Vue/React + Python API) | `verify.fullstack.sh` |
| VPS-deployed service (systemd) | `verify.vps.sh` |
| No tests yet | `verify.minimal.sh` |

---

## Checklist — Harness at 100%

**Global harness:**
- [ ] `~/.claude/CLAUDE.md` — profile, stack, projects, domain rules
- [ ] `~/.claude/settings.json` — choose fast or safe profile, all hooks configured
- [ ] Security hooks installed: `~/.claude/hooks/protect-files.sh` + `protect-paths.sh`
- [ ] Brain repo set up (dedicated `~/.claude-brain/`, not `$HOME`)
- [ ] `memory/MEMORY.md` created as index
- [ ] Agents installed: `~/.claude/agents/` (5 role agents)
- [ ] Commands installed: `~/.claude/commands/`
- [ ] Skill installed: `~/.claude/skills/harness-engineering/`
- [ ] Skills curated to relevant domains (target: 200–320)

**Per project:**
- [ ] `AGENTS.md` in project root — all sections filled
- [ ] `scripts/verify.sh` created, executable, passes in clean state
- [ ] Project in global CLAUDE.md projects table
- [ ] Project memory file created and indexed

---

## Contributing

Contributions welcome. Most valuable:
- `verify.sh` variants for project types not covered
- `AGENTS.md` examples for specific frameworks
- Anti-patterns discovered in real use

---

## References

- [Harness Engineering series — Betta Tech](https://www.youtube.com/@betta-tech)
- [BYO Coding Agent (educational repo)](https://github.com/betta-tech/byo-coding-agent)
- [Anthropic multi-agent guide](https://docs.anthropic.com/en/docs/build-with-claude/agents)
- [Claude Code hooks documentation](https://docs.anthropic.com/en/docs/claude-code/hooks)
