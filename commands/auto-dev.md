---
description: Hands-free development loop. Same quality gates as /parliament but no human intervention. For complex tasks use /parliament instead.
---

# Auto-Dev (Hands-Free)

This command is a hands-free development loop designed for tasks that do not require human review. It uses the same agent architecture as `/parliament` (planner, auditor, coding agent, git agent) and the same quality gates (auditor reviews plan and code), but removes all human control gates. Everything runs autonomously from start to finish.

**USE THIS ONLY FOR LOW-RISK CHANGES** (e.g., small bug fixes, typo corrections, adding a simple function, config changes). For anything complex or high-risk, use `/parliament` instead.

**CRITICAL: You MUST execute every phase in strict sequential order (Phase 0 -> 1 -> 2 -> 3 -> 4). You MUST NOT skip any phase. Under no circumstances may you skip the auditor steps or jump to git operations early.**

---

## Workflow Initialization (MANDATORY FIRST STEP)

Before doing ANYTHING else, you MUST complete these two steps:

1. **State Announcement**: Output the following header exactly:
   ```
   ## WORKFLOW: AUTO-DEV (HANDS-FREE)
   ```

2. **Create Phase Tracker**: Use the `TodoWrite` tool to create the following todos, ALL set to `pending`:
   - Phase 0: Codebase Reconnaissance
   - Phase 1: Planning & Automated Review
   - Phase 2: Implementation & Automated Code Review
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
   - Locate existing test files and test commands (e.g., `pytest`, `npm test`, `make test`, `go test`, build commands).
   - Detect code formatters/linters in use (e.g., `black`, `prettier`, `ruff`, `gofmt`, `rustfmt`).
   - Note coding patterns and conventions used in the relevant areas.
   - Return a structured summary with: relevant files (with paths), key functions/classes, dependencies, **detected test command** (if any), **detected formatter/linter** (if any), and patterns to follow.

3. **Fallback Context**: If the explore agent returns fewer than 2 relevant files, the exploration was too narrow. In this case, read the full project directory tree (use `Read` on the workspace root) and read any entry-point files (e.g., `main.py`, `index.ts`, `main.go`, `app.py`, `src/lib.rs`) to build broader context.

4. **Embed Context**: Carry the project context, exploration results, detected test command, and detected formatter forward into all subsequent phases.

Mark Phase 0 todo as `completed`.

---

## Phase 1: Planning & Automated Review

**Transition Protocol**: Output the following, then mark Phase 1 todo as `in_progress`:
```
## ENTERING PHASE 1: Planning & Automated Review

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
```

1. **Classify Complexity**: Before preparing the auditor briefing, assess the task complexity:
   - **Trivial**: Single-file typo fix, config value change, comment update, simple rename, adding a log line. Output `COMPLEXITY: trivial`.
   - **Standard**: Anything else (new features, multi-file changes, logic changes, refactoring). Output `COMPLEXITY: standard`.
   
   If `trivial`: skip the plan audit (steps 3-4) and proceed directly to step 5 (persist plan), then to Phase 2.
   If `standard`: proceed with the full audit below.

2. **Analyze & Draft**: Using the codebase context from Phase 0, analyze the user's request and draft a concrete implementation plan.

3. **The Briefing**: Prepare a briefing for the auditor. Include:
   - The problem/request.
   - The proposed plan.
   - **Codebase context** from Phase 0 (project structure, relevant files, patterns).
   - **FULL Context**: Embed the entire contents of all relevant files directly into the briefing. Do not worry about token limits; maximize context over brevity.
   - Specific areas of concern (e.g., security, edge cases, performance).

4. **MANDATORY (standard only) -- Audit**: You MUST use the `Task` tool to launch the `auditor` subagent with the briefing. Do NOT skip this step for standard-complexity tasks. Auto-incorporate ALL actionable suggestions into the plan. If the auditor and your plan fundamentally disagree on approach, prefer the auditor's recommendation. Limit the plan review loop to a maximum of **2 iterations**.

5. **Persist Plan**: Write the finalized plan to `.auto-dev/plan.md` in the workspace root. Include:
   - The original user request.
   - Complexity classification.
   - Codebase context summary from Phase 0.
   - The finalized plan.
   - Summary of auditor feedback incorporated (if applicable).
   This enables session resumability and creates a paper trail.

Mark Phase 1 todo as `completed`. Proceed immediately to Phase 2.

---

## Phase 2: Implementation & Automated Code Review

**Transition Protocol**: Output the following, then mark Phase 2 todo as `in_progress`:
```
## ENTERING PHASE 2: Implementation & Automated Code Review

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
- [x] Phase 1: Plan drafted and reviewed
```

1. **MANDATORY -- Implement**: You MUST use the `Task` tool to launch a `general` subagent (the "coding agent") with the finalized plan and full codebase context from Phase 0. The coding agent implements the changes. Do NOT implement the code yourself -- delegate to the subagent.

2. **Auto-Format**: After the coding agent completes, run the project's formatter/linter if one was detected during Phase 0 (e.g., `black .`, `prettier --write .`, `ruff format .`, `gofmt -w .`). If no formatter was detected, skip this step. This ensures the auditor focuses on logic, not style.

3. **The Code Briefing**: After implementation and formatting, prepare an exhaustive briefing for the auditor. Include:
   - The complete `git diff` of all uncommitted changes.
   - The **FULL contents** of all modified files (so the auditor has perfect context of the new state).
   - Explicit instructions to prioritize deep bug hunting and security flaw identification. Ignore styling and pedantry. Do not worry about token length.

4. **MANDATORY -- Code Audit**: You MUST use the `Task` tool to launch the `auditor` subagent with the code briefing and diff. This is NOT optional. Do NOT skip this step.

5. **Iterate on Feedback**: If the auditor returns actionable feedback (not LGTM), send the feedback back to the coding agent (resume the same `Task` session using `task_id`) and have it apply ALL fixes. Then re-run the auditor on the updated code. Repeat until the auditor responds LGTM or the loop has run **3 times**, whichever comes first.

Mark Phase 2 todo as `completed`. Proceed immediately to Phase 3.

---

## Phase 3: Validation & Testing

**Transition Protocol**: Output the following, then mark Phase 3 todo as `in_progress`:
```
## ENTERING PHASE 3: Validation & Testing

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
- [x] Phase 1: Plan drafted and reviewed
- [x] Phase 2: Coding agent implemented changes
- [x] Phase 2: Auditor code review passed (LGTM or 3 rounds)
```

1. **Determine Test Command**: Use the test command detected during Phase 0. If no test command was detected, attempt the following in order:
   - Look for a `Makefile` with a `test` target -> `make test`
   - Look for `pytest.ini`, `pyproject.toml` with `[tool.pytest]`, or a `tests/` directory -> `pytest`
   - Look for `package.json` with a `test` script -> `npm test`
   - Look for `go.mod` -> `go test ./...`
   - If none of the above apply, **skip testing** and proceed to Phase 4 with a note that no tests were found.

2. **Run the test**: Execute the detected/determined test command.
3. **If the test PASSES**: Proceed to Phase 4.
4. **If the test FAILS**: Enter the bug-fix loop:
   a. Use the `Task` tool to launch a `general` subagent (the "bug-fix agent") with the test failure output, the full diff, and the relevant file contents. The bug-fix agent diagnoses and fixes the issue.
   b. Re-run the same test command automatically.
   c. If the test **passes**, proceed to Phase 4.
   d. If the test **fails again**, repeat from step (a). Limit the bug-fix loop to a maximum of **3 iterations**.
   e. If after 3 iterations the test still fails, **STOP and present the failure to the user**. This is the ONE case where the hands-free workflow halts for human input. Do NOT commit broken code.

Mark Phase 3 todo as `completed`.

---

## Phase 4: Commit & Push

**Transition Protocol**: Output the following, then mark Phase 4 todo as `in_progress`:
```
## ENTERING PHASE 4: Commit & Push

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
- [x] Phase 1: Plan drafted and reviewed
- [x] Phase 2: Coding agent implemented changes
- [x] Phase 2: Auditor code review passed (LGTM or 3 rounds)
- [x] Phase 3: Tests passed (or no tests found)
```

1. **MANDATORY -- Delegate to Git Agent**: You MUST use the `Task` tool to launch a `general` subagent (the "git agent") to handle all git operations. Provide it with the full context of what was changed and why. The git agent MUST:
   - Run `git status` and `git diff`.
   - Stage changes: `git add -A`.
   - Generate a detailed commit message including:
     - `Co-Authored-By: Claude <noreply@anthropic.com>`
   - Commit: `git commit -m "[Message]"`
   - Push: Run `git push origin [branch]`. This will execute automatically based on your config unless a destructive flag is passed.

2. **Memory Writeback**: After the git agent completes successfully:
   - If the project has an `AGENTS.md` file, append a brief section with learnings from this session (e.g., detected test command, formatter, key patterns discovered, architecture decisions made).
   - If no `AGENTS.md` exists, create one with these learnings.
   - Keep entries concise -- 2-3 bullet points max per session.
   - This builds institutional memory for future sessions.

Mark Phase 4 todo as `completed`.

---

## Prohibited Shortcuts

The following are EXPLICIT VIOLATIONS of this workflow. You MUST NOT do any of these under any circumstances:

- **Do NOT skip Phase 0** and go straight to planning. Always map the codebase first.
- **Do NOT implement code yourself** -- always delegate to the coding subagent via the `Task` tool.
- **Do NOT skip the auditor** -- even for trivial tasks, the code audit in Phase 2 is mandatory (only the plan audit can be skipped for trivial tasks).
- **Do NOT combine phases** -- each phase is a distinct step. Do not merge planning with implementation, or code review with testing.
- **Do NOT commit broken code** -- if tests fail after 3 bug-fix attempts, STOP and ask the user. This is the only human gate.
- **Do NOT skip the pre-flight checklist** -- you must output it before entering each phase.
