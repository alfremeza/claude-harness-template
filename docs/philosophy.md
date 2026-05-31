# Harness Engineering — Philosophy

## Why harnesses matter more than models

When GPT-4 came out, then Claude 2, then Claude 3... each time developers expected everything to get dramatically better. Sometimes it did. Often it didn't. The reason: the model is only part of the equation.

The same model running inside a well-structured harness consistently outperforms a better model with no harness. This was confirmed empirically by Vercel when building their D0 agent (a data analysis agent):

> They gave Claude specialized tools for SQL, database connections, and structured reasoning paths. Performance was mediocre. They stripped it back to `ls`, `cat`, `grep`, and basic bash. **3x faster. 37% fewer tokens. Won on every single request.**

The model didn't change. The harness did.

## The three pillars in depth

### Pillar 1: Repository as system

The repository is not just where code lives. It's the interface between you and the AI.

When a developer opens Claude Code and types a prompt, they're thinking of that prompt as the instruction. But Claude is reading:
- Your global `CLAUDE.md` (who you are, how to respond)
- The project's `AGENTS.md` (what this project does, what rules apply)
- The memory index (what happened before)
- The git history (what changed recently)
- The file structure (where things live)

A prompt like "add validation to the form" means completely different things depending on whether Claude has read your AGENTS.md (and knows about your validation patterns, your form library, your test requirements) versus starting cold.

**The repository must be self-documenting for the AI.**

### Pillar 2: Multi-agent orchestration

The single-agent approach has a fundamental flaw: it tries to hold everything in context simultaneously. Understanding the codebase, planning the change, writing the code, reviewing the diff, running tests — all in one agent with one context window.

This is like asking one person to be the architect, contractor, QA engineer, and project manager on the same task simultaneously. They'll do each role worse because they're context-switching constantly.

The multi-agent approach separates concerns:
- **Explorer agent**: reads code, builds understanding — starts fresh, low context
- **Planner agent**: receives explorer's output, plans the change — focused context
- **Implementer agent**: receives the plan, executes — minimal context needed
- **Reviewer agent**: receives the diff, checks quality — independent perspective
- **Verifier agent**: runs the quality gate — deterministic, no ambiguity

Each agent starts with less context and does one thing well. The quality of the output compounds.

### Pillar 3: Verification

This is the most underimplemented pillar. And it's the most important.

Claude is trained to be helpful and to complete tasks. This creates a bias toward declaring success. If there's no external verification mechanism, Claude will tend to say things are done when they might not be.

The solution is simple but non-negotiable: **every project needs a `verify.sh`** that runs automatically after any implementation work. It's not Claude judging its own output. It's an external system — your tests, your linter, your type checker — making the call.

If `verify.sh` fails, the task is not done. Period.

## Context window management

Research and empirical evidence suggest that AI quality degrades at around 20-40% context window usage — well before the window fills. The longer a session runs without compaction, the more the quality of responses drifts.

Practical implications:
- Use `/compact` proactively, not reactively
- Keep `CLAUDE.md` tight — every line of the system prompt costs tokens every turn
- Store context in files (AGENTS.md, memory/, progress/) rather than in the conversation
- Sub-agents start with empty context by design — this is a feature, not a bug

## Memory architecture

The AI's in-context memory (the conversation history) is:
- Expensive (tokens)
- Volatile (resets every session)
- Degrading (quality drops as it fills)

External memory (files, databases) is:
- Cheap (disk space)
- Persistent (survives sessions)
- Stable (doesn't degrade)

The design principle: **pull information into context only when needed, from files where it lives permanently.**

This is why the memory system uses individual files per topic rather than one big memory dump, and why AGENTS.md files per project exist rather than one global file trying to cover everything.
