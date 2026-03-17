---
name: branch-workflow
description: Clean branch completion workflow — PR creation, merge strategy, and cleanup. Use this skill when implementation is complete and it's time to ship — after Phase 3 human gate passes. Also use when the user says "create a PR", "merge this", "ship it", "finish this branch", or asks about merge strategy.
role: worker
user-invocable: true
---

# Branch Workflow

## Overview

The three-phase workflow ends at the Phase 3 human gate. This skill formalizes what happens after approval: PR creation, merge decision, and branch cleanup. Without this, branches linger and merge conflicts accumulate.

## Constraints
- Do not push to main/master directly — always use a PR
- Do not force-push unless the human explicitly requests it
- Do not delete branches that have unmerged work
- Do not merge without a passing CI check (if CI is configured)

## Workflow

### 1. Pre-PR Checklist
Before creating the PR, verify:
- [ ] All tests pass (fresh run, not cached)
- [ ] `/code-review --changed` passed or warnings are documented
- [ ] Documentation is current (tech-writer verified in Phase 3)
- [ ] Beads issues are marked done (`bd update <id> --status done`)
- [ ] Branch is rebased on latest main (resolve conflicts if needed)

### 2. Create the PR
- Title: concise, under 70 characters, describes the change
- Body: Summary (what and why), test plan, link to design doc if one exists
- Labels: add relevant labels (bug, feature, refactor, docs)
- Reviewers: assign based on who should review (human decides)

### 3. Merge Strategy Decision

| Situation | Strategy | Why |
|-----------|----------|-----|
| Single logical change, clean history | Squash merge | One commit tells the story |
| Multiple logical changes that should stay separate | Merge commit | Preserves the history of each change |
| Long-lived branch with many commits | Squash merge | Reduces noise in main history |
| Experimental/spike work | Squash merge | The journey doesn't matter, only the result |

Default: **squash merge** unless the human specifies otherwise.

### 4. Post-Merge Cleanup
- Delete the feature branch (remote and local)
- Close related Beads issues if not auto-closed
- Verify the merge didn't break main (CI should catch this)

## Integration
- Triggered after Phase 3 human gate approval
- Uses Beads for issue lifecycle (`bd update --status done`)
- PR creation follows the git commit conventions in the project

## Output
A merged PR with clean branch history, closed issues, and deleted feature branch.
