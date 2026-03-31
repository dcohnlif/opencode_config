---
description: Fully automated Actor-Critic development loop (Maker vs. Checker).
---

# Auto-Dev Workflow

This command orchestrates a complete development loop using dedicated subagents: a planning agent (primary), a coding agent (`general` subagent), an auditor (`auditor` subagent) as the Checker, and a git agent (`general` subagent) for commit/push.

**CRITICAL: You MUST execute every phase in order. You MUST NOT skip any phase. You MUST NOT proceed to the next phase until the current phase is fully complete, including all auditor invocations and user approvals. Under no circumstances may you skip the auditor steps or jump to git operations early.**

## Phase 1: Planning & Architecture Review

1. **Analyze & Draft**: Analyze the user's request and the codebase. Draft a concrete implementation plan.
2. **The Briefing**: Prepare a briefing for the auditor. Include:
   - The problem/request.
   - The proposed plan.
   - **FULL Context**: Embed the entire contents of all relevant files directly into the briefing. Do not worry about token limits; maximize context over brevity.
   - Specific areas of concern (e.g., security, edge cases, performance).
3. **MANDATORY -- Audit**: You MUST use the `Task` tool to launch the `auditor` subagent with the briefing. Do NOT skip this step. Do NOT proceed without running the auditor.
4. **MANDATORY -- Human Control Gate 1**: Present the auditor's structured feedback (Assessment, Assumptions, Alternatives, Risks) to the user. STOP and WAIT for user input. Ask which suggestions to incorporate. Do NOT proceed until the user responds.
   *Note: Limit the plan review loop to a maximum of 3 iterations to prevent pedantry.*

**STOP: Do NOT begin Phase 2 until the user has approved the plan.**

## Phase 2: Implementation & Code Review

1. **MANDATORY -- Implement**: You MUST use the `Task` tool to launch a `general` subagent (the "coding agent") with the approved plan and full codebase context. The coding agent implements the changes. Do NOT implement the code yourself — delegate to the subagent.
2. **The Code Briefing**: After the coding agent has completed implementation, prepare an exhaustive briefing for the auditor. Include:
   - The complete `git diff` of all uncommitted changes.
   - The **FULL contents** of all modified files (so the auditor has perfect context of the new state).
   - Explicit instructions to prioritize deep bug hunting and security flaw identification. Ignore styling and pedantry. Do not worry about token length.
3. **MANDATORY -- Code Audit**: You MUST use the `Task` tool to launch the `auditor` subagent with the code briefing and diff. This is NOT optional. Do NOT skip this step. Do NOT proceed to Phase 3 without completing this audit.
4. **Iterate on Feedback**: If the auditor returns actionable feedback (not LGTM), send the feedback back to the coding agent (resume the same `Task` session using `task_id`) and have it apply fixes. Then re-run the auditor on the updated code. Repeat until the auditor responds LGTM or the loop has run **3 times**, whichever comes first.
5. **MANDATORY -- Human Control Gate 2**: Present the code review feedback to the user. STOP and WAIT for user input. Ask which fixes to apply. Do NOT proceed until the user responds.

**STOP: Do NOT begin Phase 3 until the user has approved the code review results.**

## Phase 3: Validation & Testing

**You may ONLY reach this phase after BOTH auditor reviews have been completed and the user has approved the results.**

1. Apply any final approved fixes.
2. **MANDATORY -- Human Control Gate 3**: Ask the user what command to run to test the changes (e.g., a test suite, a script, a build command, a specific function). STOP and WAIT for user input. Do NOT proceed until the user responds.
3. **Run the test**: Execute the test command provided by the user.
4. **If the test PASSES**: Proceed to Phase 4.
5. **If the test FAILS**: Enter the bug-fix loop:
   a. Use the `Task` tool to launch a `general` subagent (the "bug-fix agent") with the test failure output, the full diff, and the relevant file contents. The bug-fix agent diagnoses and fixes the issue.
   b. Re-run the same test command automatically (no need to ask the user).
   c. If the test **passes**, proceed to Phase 4.
   d. If the test **fails again**, repeat from step (a). Limit the bug-fix loop to a maximum of **3 iterations**.
   e. If after 3 iterations the test still fails, STOP and present the failure to the user. Ask how to proceed. Do NOT continue to Phase 4.

**STOP: Do NOT begin Phase 4 until the test has passed.**

## Phase 4: Commit & Push

**You may ONLY reach this phase after all tests have passed.**

1. **MANDATORY -- Delegate to Git Agent**: You MUST use the `Task` tool to launch a `general` subagent (the "git agent") to handle all git operations. Provide it with the full context of what was changed and why. The git agent MUST:
   - Run `git status` and `git diff`.
   - Stage changes: `git add -A`.
   - Generate a detailed commit message including:
     - `Co-Authored-By: Claude <noreply@anthropic.com>`
   - Commit: `git commit -m "[Message]"`
   - Push: Run `git push origin [branch]`. This will execute automatically based on your config unless a destructive flag is passed.
