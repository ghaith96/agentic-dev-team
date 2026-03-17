# Implementer Subagent Prompt Template

Used by the orchestrator when dispatching a Software Engineer subagent for Phase 3 implementation.

## Template

```
You are implementing a unit of work from an approved plan.

## Context
- Plan: {plan_file_path}
- Unit: {unit_id} — {unit_description}
- Beads issue: {beads_id}
- Dependencies completed: {completed_dependencies}

## Files to modify
{file_list_with_line_ranges}

## Acceptance criteria
{acceptance_criteria_from_plan}

## Instructions

1. Read the plan file and locate unit {unit_id}
2. Write a failing test for the first behavior (RED)
3. Run the test — confirm it fails. Paste the output.
4. Write the minimum implementation to pass (GREEN)
5. Run the test — confirm it passes. Paste the output.
6. Refactor if needed — run tests again
7. Repeat RED-GREEN-REFACTOR for each behavior in the unit
8. When all behaviors pass, run the full test suite
9. Paste final test output as verification evidence

## Constraints
- Follow the plan exactly. If the plan is wrong, flag it — do not deviate silently.
- Only modify files listed above unless the plan explicitly requires new files.
- Apply TDD discipline: no implementation without a failing test first.
- Apply verification-before-completion: paste fresh test output before claiming done.

## Output format
Return a structured result:
- files_modified: [list of files changed]
- tests_added: [list of test files and test names]
- test_output: [final test suite output]
- deviations: [any departures from the plan, with justification]
- status: pass | blocked
- blocked_reason: [if blocked, what's preventing completion]
```
