# Skills Guide — What to Install, What to Remove

## How skills work

Skills are markdown files that Claude Code loads **on-demand** when you invoke them with a slash command (e.g., `/tdd`, `/deep-research`). They're not loaded into context automatically — only when explicitly called.

**However:** The list of available skill names appears in a `system-reminder` block at the start of every session. This index is always in context, even if no skill is loaded. With 400+ skills, that index adds noise to every session and can cause Claude to suggest irrelevant skills.

**Target: 200–320 skills.** This range gives you broad coverage without index noise.

---

## Check your current count

```bash
ls ~/.claude/skills/ | wc -l
```

---

## Skills by category — what to keep or remove

### Always keep — Core workflows

```
tdd                     test-driven development
code-review             code review with effort levels
deep-research           multi-source research synthesis
plan                    implementation planning
brainstorming           structured ideation
verify                  manual verification of changes
simplify                code cleanup and refactoring
security-review         vulnerability detection
```

### Always keep — Your stack

Keep skills matching the languages and frameworks you actually use. Examples:

```
# If you use Python:
python-patterns, python-testing, django-patterns, fastapi (if exists)

# If you use TypeScript/JS:
typescript-reviewer, nextjs-turbopack, frontend-patterns, frontend-design

# If you use Go:
golang-patterns, golang-testing

# If you use Flutter/Dart:
flutter-reviewer, dart-flutter-patterns

# If you work with databases:
postgres-patterns, database-migrations, database-reviewer
```

### Keep if relevant to your domain

```
# Medical / Healthcare:
healthcare-emr-patterns, healthcare-phi-compliance, clinical-decision-support
pydicom, pyhealth   ← medical imaging and health data

# Finance / Trading:
iao-trading, iao-inversiones, pinescript-estrategias
hyperliquid-ccxt-python, defi-pools-liquidez

# AI/ML:
claude-api, pytorch-patterns, transformers, scikit-learn
statistical-analysis, statsmodels

# DevOps:
docker-patterns, deployment-patterns, database-migrations

# Data:
polars, pandas (if exists), matplotlib, seaborn
```

### Remove if not relevant — Common bloat categories

**Bioinformatics / Genomics** (remove unless you're a biologist):
```bash
rm -rf anndata arboreto biopython bioservices cellxgene-census cobrapy \
       deepchem deeptools depmap diffdock dnanexus-integration esm \
       geniml gget gtars histolab lamindb latchbio-integration matchms \
       medchem molfeat molecular-dynamics neuropixels-analysis omero-integration \
       pathml phylogenetics polars-bio primekg pydeseq2 pylabrobot pymatgen \
       pysam pytdc rdkit scvelo scvi-tools scikit-bio scikit-survival \
       tiledbvcf torch-geometric torchdrug umap-learn zarr-python \
       geopandas fluidsim
```

**Quantum computing** (remove unless relevant):
```bash
rm -rf qiskit qutip pennylane cirq
```

**Languages you don't use** (examples):
```bash
# If you don't use Swift/iOS:
rm -rf swift-actor-persistence swift-concurrency-6-2 swift-protocol-di-testing swiftui-patterns

# If you don't use Kotlin/Android:
rm -rf kotlin-patterns kotlin-testing kotlin-coroutines-flows compose-multiplatform-patterns

# If you don't use Java/Spring:
rm -rf java-coding-standards springboot-patterns springboot-tdd java-build-resolver

# If you don't use Rust:
rm -rf rust-patterns rust-testing rust-build-resolver rust-reviewer

# If you don't use C++:
rm -rf cpp-coding-standards cpp-testing cpp-build-resolver cpp-reviewer
```

**Niche tools you don't use:**
```bash
# Check each one — keep only if you actually use the tool
rm -rf benchling-integration ginkgo-cloud-lab opentrons-integration \
       labarchive-integration protocolsio-integration dnanexus-integration
```

---

## How to audit your skills list

```bash
# List all skills
ls ~/.claude/skills/ | sort

# Count by category (quick pattern match)
ls ~/.claude/skills/ | grep -c "python\|django\|fastapi"   # Python skills
ls ~/.claude/skills/ | grep -c "react\|vue\|next\|svelte"  # Frontend skills
```

For each skill you're unsure about:
```bash
# Read its description
head -10 ~/.claude/skills/skill-name/SKILL.md
```

---

## Installing new skills

Skills come from the Claude Code marketplace or can be written manually.

```bash
# Install via Claude Code (in a session):
/install-skill skill-name

# Or manually — copy a SKILL.md to the right directory:
mkdir -p ~/.claude/skills/my-custom-skill
cp /path/to/SKILL.md ~/.claude/skills/my-custom-skill/SKILL.md
```

---

## Writing a custom skill

Custom skills are the most powerful part of the system. A skill is a markdown file with frontmatter that Claude reads and follows.

Use case: encode your workflow, your team's conventions, your domain-specific process.

```markdown
---
name: my-workflow
description: My specific workflow for [task]. Invoke when [trigger condition].
---

# My Workflow

## When to use this skill
[Describe the trigger — what situation calls for this]

## Steps
1. [First step with specific action]
2. [Second step]
3. [Verification step]

## Rules
- [Hard rule 1]
- [Hard rule 2]

## Output format
[What should be produced at the end]
```

Save to `~/.claude/skills/my-workflow/SKILL.md` and invoke with `/my-workflow`.

---

## Skills vs. AGENTS.md vs. CLAUDE.md

Knowing where to put rules:

| Type of rule | Where it goes |
|---|---|
| "Always respond in Spanish" | CLAUDE.md |
| "In this project, never modify echo_rules.ts without ASE validation" | AGENTS.md |
| "When debugging, follow this 5-step process" | Skill |
| "When starting a new feature, always write tests first" | Skill (TDD) |
| "In this project, the verify.sh must pass before done" | AGENTS.md |
| "Never send patient data to external APIs" | CLAUDE.md |

**CLAUDE.md:** global identity and always-on rules  
**AGENTS.md:** project-specific rules and context  
**Skills:** reusable processes and workflows, invoked on demand
