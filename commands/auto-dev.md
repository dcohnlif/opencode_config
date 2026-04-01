---
description: Hands-free development loop. Same quality gates as /parliament but no human intervention. For complex tasks use /parliament instead.
---

# Auto-Dev (Hands-Free)

This command is a hands-free development loop for tasks that do not require human review. It uses the same agent architecture as `/parliament` (planner, auditor, coding agent, git agent) and the same quality gates (auditor reviews plan and code), but removes all human control gates. Everything runs autonomously from start to finish.

Use this for low-risk changes (e.g., small bug fixes, typo corrections, adding a simple function, config changes). For anything complex or high-risk, use `/parliament` instead.

Execute every phase in strict sequential order (Phase 0 through 4). Each phase must fully complete before the next phase begins.

---

## Workflow Initialization

Before doing anything else, complete these two steps:

1. Output this header exactly:
   ```
   ## WORKFLOW: AUTO-DEV (HANDS-FREE)
   ```

2. Use the `TodoWrite` tool to create the following todos, all set to `pending`:
   - Phase 0: Codebase Reconnaissance
   - Phase 1: Planning & Automated Review
   - Phase 2: Implementation & Automated Code Review
   - Phase 3: Validation & Testing
   - Phase 4: Commit & Push

Only after both steps are complete may you proceed to Phase 0.

---

<phase_0>
## Phase 0: Codebase Reconnaissance

The purpose of this phase is to build grounded context so that later phases operate on real project knowledge rather than assumptions.

**Transition Protocol**: Output `## ENTERING PHASE 0: Codebase Reconnaissance` and mark the Phase 0 todo as `in_progress`.

1. **Read Project Context**: Check if `AGENTS.md` and/or `README.md` exist in the workspace root. If they do, read them to understand the project's structure, conventions, tech stack, and patterns.

2. **Targeted Exploration**: Use the `Task` tool to launch an `explore` subagent scoped to the user's request. The explore agent should:
   - Find files, functions, and classes relevant to the requested change.
   - Identify dependencies and imports that will be affected.
   - Locate existing test files and test commands (e.g., `pytest`, `npm test`, `make test`, `go test`, build commands).
   - Detect code formatters/linters in use (e.g., `black`, `prettier`, `ruff`, `gofmt`, `rustfmt`).
   - Note coding patterns and conventions used in the relevant areas.
   - Return a structured summary with: relevant files (with paths), key functions/classes, dependencies, detected test command (if any), detected formatter/linter (if any), and patterns to follow.

3. **Fallback Context**: If the explore agent returns fewer than 2 relevant files, the exploration was too narrow. Read the full project directory tree and any entry-point files (e.g., `main.py`, `index.ts`, `main.go`, `app.py`, `src/lib.rs`) to build broader context.

4. **Embed Context**: Carry the project context, exploration results, detected test command, and detected formatter forward into all subsequent phases.

**Self-Verification**: Before leaving this phase, confirm: Do you have at least 2 relevant files identified? Do you know the test command and formatter? If not, re-run exploration with broader scope.

Mark Phase 0 todo as `completed`. Write initial state to `.auto-dev/state.json`:
```json
{"phase_0": "completed", "phase_1": "pending", "phase_2": "pending", "phase_3": "pending", "phase_4": "pending"}
```
</phase_0>

---

<phase_1>
## Phase 1: Planning & Automated Review

The purpose of this phase is to produce a reviewed plan before code is written. For trivial tasks, the plan audit is skipped because the overhead exceeds the benefit -- but the code audit in Phase 2 still catches implementation bugs.

**Transition Protocol**: Output the following, then mark Phase 1 todo as `in_progress`:
```
## ENTERING PHASE 1: Planning & Automated Review

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
```

1. **Classify Complexity**: Assess the task complexity before preparing the auditor briefing. This determines whether the plan audit is worthwhile:
   - **Trivial**: Single-file typo fix, config value change, comment update, simple rename, adding a log line. Output `COMPLEXITY: trivial`. Skip the plan audit (steps 3-4).
   - **Standard**: Anything else (new features, multi-file changes, logic changes, refactoring). Output `COMPLEXITY: standard`. Proceed with the full audit.

2. **Analyze & Draft**: Using the codebase context from Phase 0, draft a concrete implementation plan.

3. **The Briefing** (standard only): Prepare a briefing for the auditor including the problem/request, the proposed plan, codebase context from Phase 0, full contents of all relevant files, and specific areas of concern.

4. **Plan Audit** (standard only): Use the `Task` tool to launch the `auditor` subagent with the briefing. Auto-incorporate all actionable suggestions. If the auditor and your plan fundamentally disagree on approach, prefer the auditor's recommendation. Limit the plan review loop to 2 iterations.

5. **Persist Plan**: Write the finalized plan to `.auto-dev/plan.md` in the workspace root. Include the original request, complexity classification, codebase context summary, the finalized plan, and auditor feedback incorporated (if applicable). This enables session resumability.

**Self-Verification**: Before leaving this phase, confirm: Did you classify the complexity? For standard tasks, did you run the auditor via the Task tool? If not, go back and correct.

Mark Phase 1 todo as `completed`. Update `.auto-dev/state.json`:
```json
{"phase_0": "completed", "phase_1": "completed", "phase_2": "pending", "phase_3": "pending", "phase_4": "pending"}
```

Proceed immediately to Phase 2.
</phase_1>

---

<phase_2>
## Phase 2: Implementation & Automated Code Review

The purpose of this phase is to produce reviewed, high-quality code. The coding agent is a separate subagent so that the orchestrator retains a clean view of the overall workflow. The auditor catches bugs the coding agent missed.

**Transition Protocol**: Output the following, then mark Phase 2 todo as `in_progress`:
```
## ENTERING PHASE 2: Implementation & Automated Code Review

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
- [x] Phase 1: Plan drafted and reviewed
```

1. **Implement via Coding Agent**: Use the `Task` tool to launch a `general` subagent (the "coding agent") with the finalized plan and full codebase context from Phase 0. Delegating to a subagent prevents the orchestrator from losing track of the overall workflow while deep in implementation details.

2. **Auto-Format**: After the coding agent completes, run the project's formatter/linter if one was detected during Phase 0. This ensures the auditor focuses on logic, not style. Skip if no formatter was detected.

3. **The Code Briefing**: Prepare an exhaustive briefing for the auditor including the complete `git diff` of all uncommitted changes and the full contents of all modified files.

4. **Code Audit**: Use the `Task` tool to launch the `auditor` subagent with the code briefing and diff. The auditor provides an independent check that catches bugs the coding agent missed.

5. **Iterate on Feedback**: If the auditor returns actionable feedback (not LGTM), send the feedback to the coding agent (resume the same Task session using `task_id`) and have it apply all fixes. Then re-run the auditor on the updated code. Repeat until the auditor responds LGTM or the loop has run 3 times, whichever comes first.

**Self-Verification**: Before leaving this phase, confirm: Did you delegate implementation to a coding subagent via the Task tool (not implement directly)? Did you run the auditor? If either answer is no, go back and correct.

<example_flow>
Correct Phase 2 tool call sequence:

1. Task(subagent_type="general", prompt="Implement the approved plan...") -> receives task_id
2. Bash("ruff format .") -> auto-format (if detected)
3. Bash("git diff") -> capture diff for briefing
4. Read modified files -> capture full contents
5. Task(subagent_type="auditor", prompt="Review this code...") -> auditor review
6. If feedback: Task(task_id=coding_agent_id, prompt="Fix these issues...") -> resume coding agent
7. Repeat auditor if needed
</example_flow>

Mark Phase 2 todo as `completed`. Update `.auto-dev/state.json`:
```json
{"phase_0": "completed", "phase_1": "completed", "phase_2": "completed", "phase_3": "pending", "phase_4": "pending"}
```

Proceed immediately to Phase 3.
</phase_2>

---

<phase_3>
## Phase 3: Validation & Testing

The purpose of this phase is to verify the implementation actually works before committing. Testing catches runtime errors that static review misses.

**Transition Protocol**: Output the following, then mark Phase 3 todo as `in_progress`:
```
## ENTERING PHASE 3: Validation & Testing

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
- [x] Phase 1: Plan drafted and reviewed
- [x] Phase 2: Coding agent implemented changes
- [x] Phase 2: Auditor code review passed (LGTM or 3 rounds)
```

1. **Determine Test Command**: Use the test command detected during Phase 0. If none was detected, attempt the following in order:
   - Look for a `Makefile` with a `test` target -> `make test`
   - Look for `pytest.ini`, `pyproject.toml` with `[tool.pytest]`, or a `tests/` directory -> `pytest`
   - Look for `package.json` with a `test` script -> `npm test`
   - Look for `go.mod` -> `go test ./...`
   - If none of the above apply, skip testing and proceed to Phase 4 with a note that no tests were found.

2. **Run the test**: Execute the detected/determined test command.

3. **If the test passes**: Proceed to Phase 4.

4. **If the test fails**: Enter the bug-fix loop:
   a. Use the `Task` tool to launch a `general` subagent (the "bug-fix agent") with the test failure output, the full diff, and the relevant file contents.
   b. Re-run the same test command automatically.
   c. If the test passes, proceed to Phase 4.
   d. If the test fails again, repeat from step (a). Limit the bug-fix loop to 3 iterations.
   e. If after 3 iterations the test still fails, STOP and present the failure to the user. This is the one case where the hands-free workflow halts for human input. Do not commit broken code.

Mark Phase 3 todo as `completed`. Update `.auto-dev/state.json`:
```json
{"phase_0": "completed", "phase_1": "completed", "phase_2": "completed", "phase_3": "completed", "phase_4": "pending"}
```
</phase_3>

---

<phase_4>
## Phase 4: Commit & Push

The purpose of this phase is to safely commit and push the verified changes. The git agent is a separate subagent to prevent the orchestrator from accidentally modifying code during git operations.

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

1. **Delegate to Git Agent**: Use the `Task` tool to launch a `general` subagent (the "git agent") to handle all git operations. Provide it with the full context of what was changed and why. The git agent should:
   - Run `git status` and `git diff`.
   - Stage changes: `git add -A`.
   - Generate a detailed commit message including `Co-Authored-By: Claude <noreply@anthropic.com>`.
   - Commit and push.

2. **Memory Writeback**: After the git agent completes successfully:
   - If the project has an `AGENTS.md` file, append a brief section with learnings from this session (e.g., detected test command, formatter, key patterns, architecture decisions).
   - If no `AGENTS.md` exists, create one with these learnings.
   - Keep entries concise -- 2-3 bullet points max per session.

**Self-Verification**: Before marking this phase complete, confirm: Did you delegate git operations to a subagent via the Task tool (not run git commands directly)? If not, go back and do it correctly.

Mark Phase 4 todo as `completed`. Update `.auto-dev/state.json`:
```json
{"phase_0": "completed", "phase_1": "completed", "phase_2": "completed", "phase_3": "completed", "phase_4": "completed"}
```
</phase_4>

---

## Guidelines

The following guidelines explain the reasoning behind this workflow's structure. Understanding the "why" helps you follow it correctly:

- **Always map the codebase first** (Phase 0). Planning without context leads to flawed plans that waste implementation effort.
- **Delegate implementation to a coding subagent**. The orchestrator needs to maintain a high-level view of the workflow. Getting deep into code implementation causes it to lose track of remaining phases.
- **Run the auditor even for trivial tasks**. The plan audit can be skipped for trivial changes, but the code audit in Phase 2 always runs. Static review catches bugs the coding agent missed.
- **Do not combine phases**. Each phase has a distinct purpose. Merging them undermines the quality gates.
- **Do not commit broken code**. If tests fail after 3 bug-fix attempts, stop and ask the user. This is the only human gate.
- **Delegate git operations to a git subagent**. This isolation prevents the orchestrator from accidentally modifying code while staging/committing.
- **Write state to `.auto-dev/state.json`**. This creates a verifiable record of phase completion that prevents phases from being skipped.
