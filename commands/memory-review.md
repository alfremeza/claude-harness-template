# /memory-review

Audit the memory system. Find stale entries, update outdated project states, and clean up the index. Run monthly or before starting a major new phase of work.

## Steps

1. **Read MEMORY.md index**
   List all memory files and their descriptions.

2. **For each `project_*.md`:**
   - Read the file
   - Compare "current state" with what's actually in the codebase (quick check)
   - Flag as: ✓ Current | ⚠ Possibly stale | ✗ Outdated

3. **For each `feedback_*.md`:**
   - Read the rule
   - Ask: is this still the right approach? Has the project/codebase changed enough to invalidate it?
   - Flag as: ✓ Still valid | ⚠ Review needed | ✗ No longer applies

4. **For each `reference_*.md`:**
   - Check if the referenced resource still exists (VPS IP, dashboard URL, tool name)
   - Flag as: ✓ Valid | ✗ Resource changed or removed

5. **Cleanup**
   - Update stale project memory files with current state
   - Remove entries that no longer apply
   - Ensure MEMORY.md index is under 200 lines
   - Ensure each index entry has a specific one-line hook (not generic descriptions)

6. **Report**
   ```
   Memory Review Summary
   ─────────────────────
   Total files: N
   ✓ Current: N
   ⚠ Updated: N
   ✗ Removed: N

   Index size: N lines (target: under 200)
   ```
