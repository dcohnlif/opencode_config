---
description: Hands-free TDD development loop. Like /auto-dev but enforces test-first (red-green-refactor) per task. Best for implementing architecture docs and multi-task features.
---

# Auto-Dev TDD (Test-Driven, Hands-Free)

This command extends `/auto-dev` with BMAD-style test-driven development enforcement. Instead of implementing everything at once and testing at the end, it breaks the plan into ordered tasks and enforces a **red-green-refactor cycle per task**: write failing tests first, implement to make them pass, refactor, then move to the next task.

Use this for **medium-to-large implementations** where you have an architecture doc (TDD), PRD, or multi-task feature. For trivial changes, use `/auto-dev`. For complex work requiring human gates, use `/parliament`.

Execute every phase in strict sequential order (Phase 0 through 4). Each phase must fully complete before the next phase begins.

---

## Workflow Initialization

Before doing anything else, complete these two steps:

1. Output this header exactly:
   ```
   ## WORKFLOW: AUTO-DEV-TDD (TEST-DRIVEN, HANDS-FREE)
   ```

2. Use the `TodoWrite` tool to create the following todos, all set to `pending`:
   - Phase 0: Codebase Reconnaissance
   - Phase 1: Planning & Task Decomposition
   - Phase 2: Task-by-Task TDD Implementation
   - Phase 3: Integration Testing & Code Review
   - Phase 4: Commit & Push

Only after both steps are complete may you proceed to Phase 0.

---

<phase_0>
## Phase 0: Codebase Reconnaissance

The purpose of this phase is to build grounded context and locate any architecture/design documents that should guide implementation.

**Transition Protocol**: Output `## ENTERING PHASE 0: Codebase Reconnaissance` and mark the Phase 0 todo as `in_progress`.

1. **Read Project Context**: Check if `AGENTS.md` and/or `README.md` exist in the workspace root. If they do, read them.

2. **Read Architecture/Design Docs**: If the user referenced a TDD, PRD, or architecture document, read it in full. This document is the **authoritative source** for implementation decisions -- do not deviate from its architectural choices.

3. **Targeted Exploration**: Use the `Task` tool to launch an `explore` subagent to:
   - Find files, functions, and classes relevant to the requested change.
   - Identify dependencies and imports that will be affected.
   - Locate existing test files, test framework, and test commands.
   - Detect code formatters/linters in use.
   - Note coding patterns, naming conventions, and project structure.
   - Return a structured summary with all findings.

4. **Fallback Context**: If the explore agent returns fewer than 2 relevant files, read the full project directory tree and entry-point files.

5. **Embed Context**: Carry all context forward. The architecture doc, project patterns, test framework, and formatter are needed in every subsequent phase.

**Self-Verification**: Do you have the architecture/design doc loaded? Do you know the test framework and command? Do you know the project's naming conventions?

Mark Phase 0 todo as `completed`. Write initial state to `.auto-dev-tdd/state.json`:
```json
{"phase_0": "completed", "phase_1": "pending", "phase_2": "pending", "phase_3": "pending", "phase_4": "pending", "tasks": []}
```
</phase_0>

---

<phase_1>
## Phase 1: Planning & Task Decomposition

The purpose of this phase is to produce an **ordered list of implementation tasks** where each task is small enough for one red-green-refactor cycle. This is the key difference from `/auto-dev` -- the plan is not a high-level description but a concrete, ordered task list.

**Transition Protocol**: Output the following, then mark Phase 1 todo as `in_progress`:
```
## ENTERING PHASE 1: Planning & Task Decomposition

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped, architecture doc loaded
```

1. **Draft Task List**: Using the architecture/design doc and codebase context, decompose the implementation into ordered tasks. Each task must:
   - Be implementable in one focused coding session (1-3 files, one concern)
   - Have clear, testable acceptance criteria
   - Respect dependency ordering (foundations before features)
   - Follow the architecture doc's decisions and patterns

   Format each task as:
   ```
   ### T<N>: <Title>
   **Files**: <files to create/modify>
   **Depends on**: <T numbers or "none">
   **Acceptance Criteria**:
   - [ ] <specific, testable criterion>
   - [ ] <specific, testable criterion>
   **Test approach**: <what tests to write>
   ```

2. **Plan Audit**: Use the `Task` tool to launch the `auditor` subagent with the task list, the architecture doc, and the codebase context. The auditor should verify:
   - Tasks are in correct dependency order
   - Each task is small enough for one TDD cycle
   - Acceptance criteria are testable
   - The task list covers all architecture decisions
   
   Auto-incorporate actionable feedback. Limit to 2 iterations.

3. **Persist Plan**: Write the finalized task list to `.auto-dev-tdd/plan.md`. Include the architecture doc reference, task list, and auditor feedback.

4. **Create Task Tracker**: Use `TodoWrite` to add a todo for each task (T1, T2, ...), all set to `pending`.

5. **Update State**:
   ```json
   {"phase_0": "completed", "phase_1": "completed", "phase_2": "pending", "phase_3": "pending", "phase_4": "pending", "tasks": [{"id": "T1", "status": "pending"}, ...]}
   ```

Mark Phase 1 todo as `completed`. Proceed immediately to Phase 2.
</phase_1>

---

<phase_2>
## Phase 2: Task-by-Task TDD Implementation

The purpose of this phase is to implement each task following a strict red-green-refactor cycle. This is where the BMAD TDD enforcement happens -- no task is considered done until its tests exist and pass.

**Transition Protocol**: Output the following, then mark Phase 2 todo as `in_progress`:
```
## ENTERING PHASE 2: Task-by-Task TDD Implementation

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped, architecture doc loaded
- [x] Phase 1: Tasks decomposed and audited
```

For each task in order, execute the following TDD cycle:

<task_cycle>
### Task Cycle (repeat for each task T1, T2, ...)

**Announce**: Output `### TASK T<N>: <Title>` and mark the task todo as `in_progress`.

#### Step 1: RED -- Write Failing Tests

Use the `Task` tool to launch a `general` subagent (the "test agent") with:
- The task's acceptance criteria
- The architecture doc's relevant section
- The project's test framework and patterns
- Context from previously completed tasks

The test agent writes **tests that define the expected behavior** for this task. The tests must:
- Cover every acceptance criterion
- Follow the project's existing test patterns
- Import from the modules/files the task will create or modify
- **FAIL** when run (because the implementation doesn't exist yet)

Run the test command to confirm the tests fail. If they pass (meaning the functionality already exists), skip to the next task.

#### Step 2: GREEN -- Implement Minimally

Use the `Task` tool to launch a `general` subagent (the "coding agent") with:
- The failing tests (so it knows exactly what to satisfy)
- The task's acceptance criteria
- The architecture doc's patterns and decisions
- The codebase context

The coding agent implements the **minimum code to make the tests pass**. It must:
- Follow the architecture doc's decisions (naming, patterns, error handling)
- Not implement anything beyond what the tests require
- Not modify tests (only production code)

Run the test command. If tests pass, proceed to refactor. If they fail:
- Resume the coding agent (via `task_id`) with the failure output
- Re-run tests. Limit to 3 fix attempts per task.
- If still failing after 3 attempts, HALT and ask the user.

#### Step 3: REFACTOR

After tests pass, run the project's formatter/linter if detected. Review the implementation for:
- Code that can be simplified while keeping tests green
- Patterns from the architecture doc that should be applied
- Duplication that can be extracted

Run tests again after refactoring to confirm nothing broke.

#### Step 4: VALIDATE & ADVANCE

1. Verify all acceptance criteria for this task are met
2. Run the **full test suite** (not just this task's tests) to catch regressions
3. If regressions: fix them before proceeding (resume coding agent, limit 3 attempts)
4. Mark the task todo as `completed`
5. Update `.auto-dev-tdd/state.json` with the task status
6. Output progress: `TASK T<N> COMPLETE: [passed tests] / [total tests] passing`

Proceed to the next task.
</task_cycle>

**Self-Verification after all tasks**: Confirm every task todo is marked `completed`. Run the full test suite one final time.

<example_flow>
Correct task cycle sequence for one task:

1. Task(subagent_type="general", prompt="Write failing tests for T3...") -> test agent writes tests
2. Bash("pytest tests/") -> confirm tests FAIL (red)
3. Task(subagent_type="general", prompt="Implement T3 to pass these tests...") -> coding agent implements
4. Bash("pytest tests/") -> confirm tests PASS (green)
5. Bash("ruff format .") -> auto-format (refactor)
6. Bash("pytest tests/") -> confirm still passing after refactor
7. Bash("pytest") -> full suite, no regressions
8. TodoWrite: mark T3 completed
</example_flow>

Mark Phase 2 todo as `completed`. Update `.auto-dev-tdd/state.json`.

Proceed immediately to Phase 3.
</phase_2>

---

<phase_3>
## Phase 3: Integration Testing & Code Review

The purpose of this phase is to verify all tasks work together and catch cross-task bugs that per-task testing missed.

**Transition Protocol**: Output the following, then mark Phase 3 todo as `in_progress`:
```
## ENTERING PHASE 3: Integration Testing & Code Review

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
- [x] Phase 1: Tasks decomposed and audited
- [x] Phase 2: All tasks implemented via TDD (all tests passing)
```

1. **Full Test Suite**: Run the complete test suite one final time. All tests (existing + new) must pass.

2. **Code Audit**: Prepare the full `git diff` and all modified file contents. Use the `Task` tool to launch the `auditor` subagent focused on:
   - Cross-task integration issues (interfaces between tasks don't match)
   - Architecture doc compliance (implementation follows all decisions)
   - Missing edge cases not caught by per-task tests
   - Security concerns

3. **Iterate on Feedback**: If the auditor returns actionable feedback, resume the coding agent to apply fixes. Re-run full test suite. Re-run auditor. Limit to 3 rounds.

4. **If tests fail after auditor fixes**: Enter the bug-fix loop (launch bug-fix subagent, re-run tests, limit 3 attempts). If still failing, HALT and ask the user.

Mark Phase 3 todo as `completed`. Update `.auto-dev-tdd/state.json`.
</phase_3>

---

<phase_4>
## Phase 4: Commit & Push

The purpose of this phase is to safely commit and push all verified changes.

**Transition Protocol**: Output the following, then mark Phase 4 todo as `in_progress`:
```
## ENTERING PHASE 4: Commit & Push

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
- [x] Phase 1: Tasks decomposed and audited
- [x] Phase 2: All tasks implemented via TDD
- [x] Phase 3: Integration tests passed, code review passed
```

1. **Delegate to Git Agent**: Use the `Task` tool to launch a `general` subagent (the "git agent"). The git agent should:
   - Run `git status` and `git diff`.
   - Stage changes: `git add -A`.
   - Generate a commit message that references the architecture doc and lists completed tasks. Include `Co-Authored-By: Claude <noreply@anthropic.com>`.
   - Commit and push.

2. **Memory Writeback**: Append learnings to the project's `AGENTS.md` (or create one):
   - Test framework and command
   - Formatter/linter
   - Key patterns from the architecture doc
   - Number of tasks implemented
   - 2-3 bullet points max

**Self-Verification**: Did you delegate git operations to a subagent? If not, go back and correct.

Mark Phase 4 todo as `completed`. Update `.auto-dev-tdd/state.json`:
```json
{"phase_0": "completed", "phase_1": "completed", "phase_2": "completed", "phase_3": "completed", "phase_4": "completed", "tasks": [...all completed...]}
```
</phase_4>

---

## Guidelines

- **Architecture doc is authoritative**. If the user referenced a TDD, PRD, or design doc, follow its decisions exactly. Do not second-guess architectural choices during implementation.
- **Tests come first**. Never write production code before tests. The red-green-refactor cycle is the core discipline of this workflow.
- **One task at a time**. Complete each task's full TDD cycle before starting the next. This catches integration issues early.
- **Minimum code to pass tests**. During the GREEN phase, implement only what the tests require. Over-engineering is a bug.
- **Full suite after every task**. Regressions caught early are cheap to fix. Regressions caught at the end are expensive.
- **Delegate everything**. Test writing, implementation, review, and git -- all go to subagents.
- **Do not commit broken code**. If any test fails after 3 fix attempts, halt and ask the user.
- **Track state in `.auto-dev-tdd/state.json`**. Per-task status enables resumability if the session is interrupted.
