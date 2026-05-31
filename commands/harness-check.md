# /harness-check

Quick audit of the current harness state. Checks that all critical components are in place and working. Run when something feels off, after major changes, or when onboarding a new machine.

## Checks

### Global harness
- [ ] `~/.claude/CLAUDE.md` exists and has all sections (profile, stack, projects, rules)
- [ ] `~/.claude/settings.json` exists and has hooks (SessionStart, PreToolUse, PostToolUse, PostCompact, SessionEnd)
- [ ] Brain repo is configured (`git remote -v` in home shows a remote)
- [ ] Memory directory exists and MEMORY.md is present
- [ ] MEMORY.md is under 200 lines

### Current project
- [ ] `AGENTS.md` exists in project root
- [ ] `scripts/verify.sh` exists and is executable
- [ ] `bash scripts/verify.sh` passes right now
- [ ] Project is in the global CLAUDE.md projects table
- [ ] Project memory file exists

### Hooks
- [ ] SessionStart hook runs without error (check last session)
- [ ] PreToolUse/PostToolUse matchers are `"Bash|Edit|Write"`, not `"*"`
- [ ] SessionEnd commit+push runs without error

### Skills
- [ ] Skills count is reasonable (run: `ls ~/.claude/skills/ | wc -l`)
- [ ] `harness-engineering` skill is installed

## Run each check

```bash
# Global
ls ~/.claude/CLAUDE.md && echo "✓ CLAUDE.md" || echo "✗ missing CLAUDE.md"
ls ~/.claude/settings.json && echo "✓ settings.json" || echo "✗ missing settings.json"
cd ~ && git remote -v && echo "✓ brain repo" || echo "✗ no brain repo"
wc -l ~/.claude/projects/*/memory/MEMORY.md

# Current project
ls AGENTS.md && echo "✓ AGENTS.md" || echo "✗ missing AGENTS.md"
[ -x scripts/verify.sh ] && echo "✓ verify.sh executable" || echo "✗ missing or not executable"
bash scripts/verify.sh

# Skills
echo "Skills count: $(ls ~/.claude/skills/ | wc -l)"
ls ~/.claude/skills/harness-engineering/ && echo "✓ skill installed" || echo "✗ skill missing"
```

## Output format

```
Harness Check — [project name]
──────────────────────────────
Global:   ✓ CLAUDE.md  ✓ settings  ✓ brain repo  ✓ memory (N lines)
Project:  ✓ AGENTS.md  ✓ verify.sh
Gate:     ✓ PASSED / ✗ FAILED
Skills:   N installed  ✓/✗ harness-engineering
Hooks:    ✓/✗ matcher is Bash|Edit|Write

Overall: ✓ Harness OK / ⚠ Issues found (list below)
```
