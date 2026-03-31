---
description: Fully automated Actor-Critic development loop (Maker vs. Checker) with structured phase gates.
---

# Auto-Dev Workflow

This command orchestrates a complete development loop using dedicated subagents: an explore agent for codebase mapping, the primary agent for planning, a coding agent (`general` subagent) for implementation, an auditor (`auditor` subagent) as the Checker, and a git agent (`general` subagent) for commit/push.

**CRITICAL: You MUST execute every phase in strict sequential order (Phase 0 -> 1 -> 2 -> 3 -> 4). You MUST NOT skip any phase. You MUST NOT proceed to the next phase until the current phase is fully complete, including all auditor invocations and user approvals. Under no circumstances may you skip the auditor steps or jump to git operations early.**

---

## Workflow Initialization (MANDATORY FIRST STEP)

Before doing ANYTHING else, you MUST complete these two steps:

1. **State Announcement**: Output the following header exactly:
   ```
   ## WORKFLOW: AUTO-DEV
   ```

2. **Create Phase Tracker**: Use the `TodoWrite` tool to create the following todos, ALL set to `pending`:
   - Phase 0: Codebase Reconnaissance
   - Phase 1: Planning & Architecture Review
   - Phase 2: Implementation & Code Review
   - Phase 3: Validation & Testing
   - Phase 4: Commit & Push

Only after both steps are complete may you proceed to Phase 0.

---

## Phase 0: Codebase Reconnaissance

**Transition Protocol**: Output `## ENTERING PHASE 0: Codebase Reconnaissance` and mark the Phase 0 todo as `in_progress`.

1. **Read Project Context**: Check if `AGENTS.md` and/or `README.md` exist in the workspace root. If they do, read them to understand the project's structure, conventions, tech stack, and patterns.

2. **Targeted Exploration**: Use the `Task` tool to launch an `explore` subagent scoped to the user's request. The explore agent MUST:
   - Find files, functions, and classes relevant to the requested change.
   - Identify dependencies and imports that will be affected.
   - Locate existing test files and test commands (e.g., `pytest`, `npm test`, `make test`).
   - Note coding patterns and conventions used in the relevant areas.
   - Return a structured summary with: relevant files (with paths), key functions/classes, dependencies, test locations, and patterns to follow.

3. **Embed Context**: Carry the project context and exploration results forward -- they MUST be included in the Phase 1 planning briefing.

Mark Phase 0 todo as `completed`.

---

## Phase 1: Planning & Architecture Review

**Transition Protocol**: Output the following, then mark Phase 1 todo as `in_progress`:
```
## ENTERING PHASE 1: Planning & Architecture Review

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
```

1. **Analyze & Draft**: Using the codebase context from Phase 0, analyze the user's request and draft a concrete implementation plan.
2. **The Briefing**: Prepare a briefing for the auditor. Include:
   - The problem/request.
   - The proposed plan.
   - **Codebase context** from Phase 0 (project structure, relevant files, patterns).
   - **FULL Context**: Embed the entire contents of all relevant files directly into the briefing. Do not worry about token limits; maximize context over brevity.
   - Specific areas of concern (e.g., security, edge cases, performance).
3. **MANDATORY -- Audit**: You MUST use the `Task` tool to launch the `auditor` subagent with the briefing. Do NOT skip this step. Do NOT proceed without running the auditor.
4. **MANDATORY -- Human Control Gate 1**: Present the auditor's structured feedback (Assessment, Assumptions, Alternatives, Risks) to the user. STOP and WAIT for user input. Ask which suggestions to incorporate. Do NOT proceed until the user responds.
   *Note: Limit the plan review loop to a maximum of 3 iterations to prevent pedantry.*

Mark Phase 1 todo as `completed`.

**STOP: Do NOT begin Phase 2 until the user has approved the plan.**

---

## Phase 2: Implementation & Code Review

**Transition Protocol**: Output the following, then mark Phase 2 todo as `in_progress`:
```
## ENTERING PHASE 2: Implementation & Code Review

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
- [x] Phase 1: Plan drafted and auditor reviewed
- [x] Phase 1: User approved plan
```

1. **MANDATORY -- Implement**: You MUST use the `Task` tool to launch a `general` subagent (the "coding agent") with the approved plan and full codebase context from Phase 0. The coding agent implements the changes. Do NOT implement the code yourself -- delegate to the subagent.
2. **The Code Briefing**: After the coding agent has completed implementation, prepare an exhaustive briefing for the auditor. Include:
   - The complete `git diff` of all uncommitted changes.
   - The **FULL contents** of all modified files (so the auditor has perfect context of the new state).
   - Explicit instructions to prioritize deep bug hunting and security flaw identification. Ignore styling and pedantry. Do not worry about token length.
3. **MANDATORY -- Code Audit**: You MUST use the `Task` tool to launch the `auditor` subagent with the code briefing and diff. This is NOT optional. Do NOT skip this step. Do NOT proceed to Phase 3 without completing this audit.
4. **Iterate on Feedback**: If the auditor returns actionable feedback (not LGTM), send the feedback back to the coding agent (resume the same `Task` session using `task_id`) and have it apply fixes. Then re-run the auditor on the updated code. Repeat until the auditor responds LGTM or the loop has run **3 times**, whichever comes first.
5. **MANDATORY -- Human Control Gate 2**: Present the code review feedback to the user. STOP and WAIT for user input. Ask which fixes to apply. Do NOT proceed until the user responds.

Mark Phase 2 todo as `completed`.

**STOP: Do NOT begin Phase 3 until the user has approved the code review results.**

---

## Phase 3: Validation & Testing

**Transition Protocol**: Output the following, then mark Phase 3 todo as `in_progress`:
```
## ENTERING PHASE 3: Validation & Testing

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
- [x] Phase 1: Plan drafted and auditor reviewed
- [x] Phase 1: User approved plan
- [x] Phase 2: Coding agent implemented changes
- [x] Phase 2: Auditor code review passed (LGTM or 3 rounds)
- [x] Phase 2: User approved code review
```

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

Mark Phase 3 todo as `completed`.

**STOP: Do NOT begin Phase 4 until the test has passed.**

---

## Phase 4: Commit & Push

**Transition Protocol**: Output the following, then mark Phase 4 todo as `in_progress`:
```
## ENTERING PHASE 4: Commit & Push

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
- [x] Phase 1: Plan drafted and auditor reviewed
- [x] Phase 1: User approved plan
- [x] Phase 2: Coding agent implemented changes
- [x] Phase 2: Auditor code review passed (LGTM or 3 rounds)
- [x] Phase 2: User approved code review
- [x] Phase 3: Tests passed
```

1. **MANDATORY -- Delegate to Git Agent**: You MUST use the `Task` tool to launch a `general` subagent (the "git agent") to handle all git operations. Provide it with the full context of what was changed and why. The git agent MUST:
   - Run `git status` and `git diff`.
   - Stage changes: `git add -A`.
   - Generate a detailed commit message including:
     - `Co-Authored-By: Claude <noreply@anthropic.com>`
   - Commit: `git commit -m "[Message]"`
   - Push: Run `git push origin [branch]`. This will execute automatically based on your config unless a destructive flag is passed.

Mark Phase 4 todo as `completed`.

---

## Prohibited Shortcuts

The following are EXPLICIT VIOLATIONS of this workflow. You MUST NOT do any of these under any circumstances:

- **Do NOT skip Phase 0** and go straight to planning. Always map the codebase first.
- **Do NOT implement code yourself** -- always delegate to the coding subagent via the `Task` tool.
- **Do NOT skip the auditor** -- even if the change seems trivial. The auditor MUST review both the plan and the code.
- **Do NOT combine phases** -- each phase is a distinct step. Do not merge planning with implementation, or code review with testing.
- **Do NOT proceed past a STOP barrier** without explicit user input. If the user hasn't responded, WAIT.
- **Do NOT start git operations** before tests pass. Phase 4 requires Phase 3 completion.
- **Do NOT assume a phase is complete** if you haven't performed all its steps. When in doubt, ask the user.
- **Do NOT skip the pre-flight checklist** -- you must output it before entering each phase.
