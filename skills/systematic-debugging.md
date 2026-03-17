---
name: systematic-debugging
description: Four-phase debugging protocol (reproduce, investigate, root-cause, fix) that prevents guess-and-fix thrashing. Use this skill whenever a test fails, a bug is reported, an error occurs during implementation, or any unexpected behavior is encountered. Prevents the common LLM failure mode of guessing at fixes without understanding the problem.
role: worker
user-invocable: true
---

# Systematic Debugging

## Overview

When LLMs hit failures, they tend to guess at fixes — changing code, re-running, changing more code. This thrashing wastes context and often makes things worse. This skill enforces a four-phase protocol that requires understanding before action.

## Constraints
- Do not change code until you have a root cause hypothesis
- Do not apply more than one fix at a time
- Do not skip the reproduction step — a bug you can't reproduce is a bug you can't verify as fixed
- Do not guess. Investigate.

## The Four Phases

### Phase 1: Reproduce
**Goal**: See the failure with your own eyes (tool output).

1. Run the failing test or trigger the error condition
2. Capture the exact error message, stack trace, or unexpected output
3. Identify the minimal reproduction — strip away everything unrelated
4. **Gate**: paste the reproduction output. If you can't reproduce it, investigate why before proceeding.

### Phase 2: Investigate
**Goal**: Gather facts about what's happening and why.

Techniques (use as many as needed):
- **Read the error**: Parse the stack trace. What file, line, and function? What's the actual error type?
- **Trace the data flow**: Follow the input from entry point to failure point. Where does the actual value diverge from the expected value?
- **Check recent changes**: What changed since this last worked? (`git diff`, `git log`)
- **Add observation points**: Temporary logging or print statements at key points to see actual values
- **Bisect**: If the failure surface is large, narrow it down by testing midpoints

**Gate**: state what you know and don't know. List the facts, not guesses.

### Phase 3: Root Cause
**Goal**: Identify the single underlying cause.

1. Form a hypothesis that explains **all** observed symptoms
2. Predict what you would see if the hypothesis is correct (a test you haven't run yet)
3. Run that prediction test
4. If the prediction fails, your hypothesis is wrong — return to Phase 2
5. **Gate**: state the root cause in one sentence. If you can't, you don't have it yet.

### Phase 4: Fix
**Goal**: Make the smallest change that addresses the root cause.

1. Write or modify a test that captures the bug (it should fail now)
2. Apply the fix — one change, targeting the root cause
3. Run the test — it should pass
4. Run the full suite — no regressions
5. **Gate**: paste the test output showing the fix works and nothing else broke

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I think I know what's wrong, let me just try this" | That's guessing. Investigate first — it takes less time than three wrong guesses. |
| "The fix is obvious from the error message" | Then it'll be fast to verify your hypothesis before coding. Do it. |
| "I'll just try a few things and see what sticks" | Each attempt burns context and may introduce new bugs. One investigated fix beats five guesses. |
| "This is probably a race condition / timing issue" | "Probably" isn't a root cause. Add observation points and prove it. |
| "Let me revert everything and start over" | You'll hit the same bug again. Understand it first, then decide whether to revert. |

## When to Use This Skill
- A test that was passing now fails
- An error occurs during implementation
- Unexpected behavior is observed
- A bug report comes in
- A fix you applied didn't work (re-enter at Phase 2)

## Output
Root cause analysis with evidence: reproduction output, investigation findings, root cause statement, fix applied, and verification output showing the fix works without regressions.
