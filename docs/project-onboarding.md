# Project Onboarding — Adding a Project to the Harness

Do this for every project where you want Claude to work with context and quality guarantees.

---

## When to onboard a project

Onboard a project when:
- You're actively developing or maintaining it
- Claude makes recurring mistakes because it lacks project context
- You want quality gates (tests must pass before Claude declares "done")
- Multiple sessions will touch the same codebase

You don't need AGENTS.md for one-off scripts or experiments.

---

## Step 1 — Understand your project structure

Before writing anything, run this in the project root:

```bash
find . -maxdepth 3 -type f | grep -v node_modules | grep -v __pycache__ | grep -v .git | sort
```

Identify:
- Entry points (main.py, main.go, index.ts, app.py)
- Key business logic files
- Test files and how to run them
- Configuration files (.env, config.yaml)
- Deployment scripts

---

## Step 2 — Create AGENTS.md

```bash
# In your project root:
cp path/to/project/AGENTS.md.template ./AGENTS.md
```

Fill in each section. This is the most important file — it tells Claude:
- What the project does (prevents generic responses)
- What the architecture looks like (prevents wrong file edits)
- What rules cannot be broken (prevents regressions)
- What bugs were already fixed (prevents re-introducing them)

### Section: Project description
One paragraph maximum. Tech stack. Production URL if applicable. Deploy command.

```markdown
## Project
E-commerce checkout service. Node.js + Stripe + PostgreSQL.
- Production: https://checkout.yourapp.com
- Deploy: `npm run deploy:prod`
- Tests: 45 unit tests (Jest) + 12 integration tests
```

### Section: Architecture tree
Annotate the tree — don't just list files. Claude uses this to know where to look without reading everything.

```markdown
## Architecture
project-root/
├── src/
│   ├── checkout.ts          # main checkout flow — entry point
│   ├── stripe.ts            # Stripe API wrapper — handles retries
│   ├── inventory.ts         # stock check before charge — CRITICAL
│   └── email.ts             # confirmation emails via SendGrid
├── tests/
│   ├── unit/                # Jest unit tests
│   └── integration/         # needs TEST_DB_URL env var
└── scripts/
    └── verify.sh            # quality gate
```

### Section: Critical rules
This is where you save the most time. Think about:
- Business rules that cannot break (pricing logic, validation, permissions)
- Domain-specific requirements (clinical fields, compliance, required outputs)
- Configuration traps (environment variables, file paths, numeric thresholds)

```markdown
## Critical Rules
- inventory.ts MUST run before stripe.ts charges — never reorder this
- All prices stored as integers (cents), never floats — float math bugs = wrong charges
- Required in every receipt: order_id, timestamp, amount_cents, currency
- Never log credit card numbers, even partially — compliance requirement
- Test database: use TEST_DB_URL, never the production DATABASE_URL
```

### Section: Known bugs table
Every bug you've fixed is a potential re-introduction. Document them.

```markdown
## Known Historical Bugs
| Bug | Cause | Fix |
|---|---|---|
| Double charge on retry | no idempotency key | Stripe idempotency_key = order_id |
| Stock not reserved | async race condition | use DB transaction for check+reserve |
| Email sent before charge | wrong await | await stripe.charge() before sendEmail() |
```

### Section: Pipeline
Always include this — it sets the workflow expectation.

```markdown
## Work Pipeline
1. **explorer** — read relevant code, understand what the task touches
2. **planner** — propose change with exact files and line numbers
3. **implementer** — apply the change
4. **verifier** — `bash scripts/verify.sh` → must PASS before marking done
```

---

## Step 3 — Create verify.sh

```bash
mkdir -p scripts
cp path/to/project/scripts/verify.sh.template ./scripts/verify.sh
chmod +x scripts/verify.sh
```

Adapt it to your project type:

### Python project (pytest)
```bash
echo "→ Tests..."
if ./venv/bin/python3 -m pytest tests/ --tb=short -q; then
  echo "✓ Tests OK"; PASS=$((PASS+1))
else
  echo "✗ Tests FAILED"; FAIL=$((FAIL+1))
fi
```

### Node/TypeScript project (Jest or Vitest)
```bash
echo "→ Tests..."
if npm run test -- --run 2>&1; then
  echo "✓ Tests OK"; PASS=$((PASS+1))
else
  echo "✗ Tests FAILED"; FAIL=$((FAIL+1))
fi

echo "→ TypeScript..."
if npm run type-check 2>&1; then
  echo "✓ TypeScript OK"; PASS=$((PASS+1))
else
  echo "⚠ Type errors"; FAIL=$((FAIL+1))
fi
```

### VPS service (systemd + env vars)
```bash
echo "→ Service running..."
if systemctl is-active --quiet your-service-name; then
  echo "✓ Service OK"; PASS=$((PASS+1))
else
  echo "✗ Service down — run: systemctl restart your-service-name"; FAIL=$((FAIL+1))
fi

echo "→ Required env vars..."
source .env 2>/dev/null || true
for var in ANTHROPIC_API_KEY BOT_TOKEN DATABASE_URL; do
  if [ -z "${!var:-}" ]; then
    echo "✗ Missing: $var in .env"; FAIL=$((FAIL+1))
  fi
done
```

### No tests yet (minimum viable gate)
If you have no tests, the minimum viable verify.sh checks that the project at least runs:

```bash
echo "→ Syntax check..."
if python3 -m py_compile main.py 2>&1; then
  echo "✓ Syntax OK"; PASS=$((PASS+1))
else
  echo "✗ Syntax errors"; FAIL=$((FAIL+1))
fi

echo "→ Import check..."
if python3 -c "import main" 2>&1; then
  echo "✓ Imports OK"; PASS=$((PASS+1))
else
  echo "✗ Import errors"; FAIL=$((FAIL+1))
fi
```

---

## Step 4 — Test the quality gate

Run it in a clean state. It must pass before you start working.

```bash
bash scripts/verify.sh
```

Expected output:
```
=== Your Project — Quality Gate ===
→ Tests...        ✓ Tests OK
→ TypeScript...   ✓ TypeScript OK
=================================
✓ Quality Gate PASSED (2/2 checks)
```

If it fails in clean state, fix the underlying issue before adding it to the harness.

---

## Step 5 — Update global CLAUDE.md

Add the project to your active projects table:

```markdown
## Active projects
| Project | Status |
|---|---|
| [New Project] | In development |    ← add this line
```

---

## Step 6 — Create a project memory file

```bash
# Path varies by OS — replace the path accordingly
cat > ~/.claude/projects/YOURPATH/memory/project_yourproject.md << 'EOF'
---
name: project-yourproject
description: [one line: what the project does and its current state]
metadata:
  type: project
---

# [Project Name]

[Key facts about the project that would be useful across sessions]

## Stack
- [tech stack]

## Key files
- [most important files and what they do]

## Current state
- [what's working, what's in progress]

## Important decisions made
- [architectural decisions and why]
EOF
```

Add a pointer to `MEMORY.md`:
```bash
echo "- [Your Project](project_yourproject.md) — [one-line description]" >> ~/.claude/projects/YOURPATH/memory/MEMORY.md
```

---

## Step 7 — Verify the harness loads correctly

Open Claude Code in the project directory and run:

```bash
What is this project and what are the critical rules I should know before making any changes?
```

Claude should answer from your AGENTS.md without reading the codebase first. If it doesn't, check that AGENTS.md is in the project root.

---

## Checklist

- [ ] `AGENTS.md` created in project root with all sections filled
- [ ] Architecture tree annotated with what each file does
- [ ] Critical rules section includes domain/business rules
- [ ] Known bugs table populated (even if empty, add the table)
- [ ] `scripts/verify.sh` created and executable
- [ ] `bash scripts/verify.sh` passes in clean state
- [ ] Project added to `~/.claude/CLAUDE.md` projects table
- [ ] Project memory file created and indexed in MEMORY.md
- [ ] Test: Claude answers "what are the critical rules?" from AGENTS.md

---

## Maintenance

**After fixing a bug:** add it to the Known Historical Bugs table in AGENTS.md immediately.

**When architecture changes:** update the architecture tree in AGENTS.md.

**When critical rules change:** update the Critical Rules section.

**Monthly:** review the project memory file — update status, archive completed work.

The value of AGENTS.md compounds over time. The more bugs and decisions you document, the less you explain to Claude in every session.
