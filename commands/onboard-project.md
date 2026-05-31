# /onboard-project

Guide the user through adding a new project to the harness. Walk through each step interactively, create the files, and verify the result.

## Steps

1. **Understand the project**
   Ask the user:
   - What does this project do? (one sentence)
   - What's the tech stack? (Python / Node / Full-stack / Other)
   - Where does it live? (local path or VPS path)
   - Does it have tests? If yes, how do you run them?
   - What are the most critical rules or constraints for this project?

2. **Read the codebase**
   ```bash
   find . -maxdepth 3 -type f | grep -v node_modules | grep -v __pycache__ | grep -v .git | sort
   ```
   Identify: entry points, key business logic, test files, config files.

3. **Create AGENTS.md**
   Fill in all sections based on what you learned:
   - Project description
   - Architecture tree (annotated)
   - Critical rules
   - Work pipeline (always: explorer → planner → implementer → reviewer → verifier)
   - Known historical bugs (empty table if none yet)

4. **Create scripts/verify.sh**
   Choose the right template based on tech stack:
   - Python only → `verify.python.sh`
   - Node/TypeScript only → `verify.node.sh`
   - Full-stack (Python + Node) → `verify.fullstack.sh`
   - VPS service → `verify.vps.sh`
   - No tests yet → `verify.minimal.sh`

   Adapt the template: set the correct test commands, service name, required env vars.

   ```bash
   mkdir -p scripts
   chmod +x scripts/verify.sh
   ```

5. **Test the quality gate**
   ```bash
   bash scripts/verify.sh
   ```
   Must pass in clean state before the project is considered onboarded.

6. **Update global CLAUDE.md**
   Add the project to the active projects table.

7. **Create project memory file**
   Create `~/.claude/projects/.../memory/project_PROJECTNAME.md` and add a pointer to MEMORY.md.

8. **Confirm**
   Ask Claude: "What is this project and what are its critical rules?"
   It should answer correctly from AGENTS.md.

## Output

Report what was created:
- ✓ AGENTS.md created
- ✓ scripts/verify.sh created and passes
- ✓ Project added to CLAUDE.md
- ✓ Memory file created
