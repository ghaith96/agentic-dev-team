---
name: test-driven-development
description: Enforce RED-GREEN-REFACTOR cycle with hard gates. Use this skill whenever writing new code, fixing bugs, or adding features — any time implementation code will be written or modified. Prevents the common LLM failure mode of writing implementation first and tests later (or never). Also use when reviewing code to verify TDD discipline was followed.
role: worker
user-invocable: true
---

# Test-Driven Development

## Overview

Enforces strict RED-GREEN-REFACTOR discipline with verifiable gates. LLMs are especially prone to skipping tests or writing them after implementation — this skill exists because that tendency produces code that looks tested but isn't actually validated.

## Constraints
- Do not write implementation code without a failing test first
- Do not move to the next unit of work until all tests pass
- Do not skip the refactor step — it's where design quality happens
- Do not rationalize exceptions to the cycle (see Rationalization Prevention below)

## The Cycle

Each unit of work follows three phases with hard gates between them:

### 1. RED — Write a failing test
- Write the smallest test that describes the next behavior
- Run the test suite — **the new test must fail**
- **Hard gate**: paste the failing test output. No output = no proceeding.
- If the test passes without new code, the behavior already exists — pick a different test

### 2. GREEN — Make it pass
- Write the minimum implementation to make the failing test pass
- Run the test suite — **all tests must pass**
- **Hard gate**: paste the passing test output. No output = no proceeding.
- Do not add behavior beyond what the test requires
- Do not refactor yet

### 3. REFACTOR — Clean up
- Improve structure, naming, duplication — without changing behavior
- Run the test suite — **all tests must still pass**
- If tests break during refactor, undo and try a smaller change

Then return to RED for the next behavior.

## Rationalization Prevention

LLMs generate plausible excuses for skipping TDD. These are the common ones and why they're wrong:

| Excuse | Reality |
|--------|---------|
| "I'll add tests after the implementation" | You won't. And if you do, you'll write tests that pass by definition — they test what you wrote, not what should work. |
| "This is too simple to test" | Simple code breaks too. A one-line change caused the most expensive bug in your last project. |
| "Writing the test first would be slower" | Writing a bug is slower. TDD catches errors at the cheapest possible moment. |
| "I need to see the implementation shape first" | That's called a spike. Do the spike, throw it away, then TDD the real implementation. |
| "The test framework isn't set up yet" | Set it up. That's the first task, not a reason to skip testing. |
| "I'm just refactoring, not adding behavior" | Then existing tests should pass throughout. If there are no existing tests, write characterization tests first. |
| "This is glue code / config / boilerplate" | Glue code that breaks takes down the system. If it can break, it needs a test. |

If you catch yourself composing an excuse not on this list, it's still an excuse. Write the test first.

## Integration with Phases

- **Phase 2 (Plan)**: Test strategy is part of the plan — identify what tests will be written for each unit
- **Phase 3 (Implement)**: Every unit of work follows RED-GREEN-REFACTOR. The inline review checkpoint runs after GREEN, not during RED.
- **Acceptance tests**: Feature file scenarios (Gherkin) define the outer loop. TDD operates within each scenario's implementation.

## Output
Verified RED-GREEN-REFACTOR cycle evidence: failing test output, passing test output, and refactored code with passing tests for each unit of work.
