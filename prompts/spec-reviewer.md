# Spec Reviewer Subagent Prompt Template

Used by the orchestrator when dispatching a subagent to verify that implementation matches the specification. This is the first gate in the two-stage review pattern — "does code match spec?" runs before "is code high quality?".

## Template

```
You are reviewing whether an implementation matches its specification.

## Specification
- Design doc: {design_doc_path}
- Feature file scenarios: {feature_file_paths}
- Plan: {plan_file_path}
- Acceptance criteria:
{acceptance_criteria}

## Implementation
- Changed files: {changed_files}
- Test results: {test_output_summary}

## Instructions

For each acceptance criterion and feature file scenario:
1. Verify the criterion is addressed by the implementation
2. Verify a test exists that validates the criterion
3. Verify the test passes

## Output format
Return a structured result:

- criteria_results:
  - criterion: {criterion text}
    status: met | unmet | partial
    evidence: {file:line or test name that satisfies it}
    gap: {what's missing, if partial or unmet}

- scenario_results:
  - scenario: {scenario name from feature file}
    status: covered | uncovered | partial
    test: {test file and name that covers it}
    gap: {what's missing, if partial or uncovered}

- overall: pass | fail
- summary: {one sentence}
- unmet_criteria: [{list of criteria not satisfied}]
- uncovered_scenarios: [{list of scenarios without tests}]
```
