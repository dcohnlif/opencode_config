---
description: Hands-free batch implementation of spec-kit tasks. Runs a full auto-dev cycle for each task, then performs integration testing.
---

# Auto-Dev Spec-Kit (Batch Task Runner)

This command reads spec-kit's `tasks.md` for the current feature, then iterates through each task and runs a full auto-dev cycle (plan, implement, auditor review, test, commit) for each one individually. After all tasks are completed, it performs a final integration/end-to-end test to verify everything works together.

This is designed to run after `/speckit.tasks` has generated the task list. It is fully hands-free -- the only case where it halts for human input is if a task's tests or the final integration test fail after 3 bug-fix attempts.

Execute every step in strict sequential order. Each task must fully complete its auto-dev cycle before the next task begins.

---

## Workflow Initialization

Before doing anything else, complete these steps:

1. Output this header exactly:
   ```
   ## WORKFLOW: AUTO-DEV-SPECKIT (BATCH TASK RUNNER)
   ```

2. **Locate the tasks file**: Run `.specify/scripts/bash/check-prerequisites.sh --json` from the workspace root to determine the current feature directory (FEATURE_DIR). Read `tasks.md` from that directory.

   If the script is not available or fails, fall back to scanning `.specify/features/` for the most recently modified feature directory and read its `tasks.md`.

3. **Parse all tasks**: Extract every task line matching the spec-kit format:
   ```
   - [ ] T### [P?] [US#?] Description with file path
   ```
   Preserve the task ID, parallelization flag, user story label, and description. Skip tasks already marked as complete (`- [x]`).

4. **Read supporting artifacts**: Read the following from the feature directory (if they exist) to provide full context to coding agents:
   - `spec.md` -- requirements and user stories
   - `plan.md` -- technical implementation plan

5. **Read project context**: Check if `AGENTS.md` and/or `README.md` exist in the workspace root. Read them if they exist.

6. **Detect tooling**: Use the `Task` tool to launch an `explore` subagent to detect:
   - Test command (e.g., `pytest`, `npm test`, `make test`)
   - Formatter/linter (e.g., `black`, `prettier`, `ruff`)
   - Project structure and coding patterns

7. **Create task tracker**: Use the `TodoWrite` tool to create a todo for each parsed task (using its task ID and description), all set to `pending`. Add a final todo: "Integration Test & Final Push".

8. **Write initial state**: Write the task list and status to `.auto-dev-speckit/state.json`:
   ```json
   {"current_task": null, "completed_tasks": [], "remaining_tasks": ["T001", "T002", ...], "integration_test": "pending"}
   ```

Only after all initialization steps are complete may you begin the task loop.

---

<task_loop>
## Task Loop

For each task (in order, respecting dependencies), execute the following auto-dev cycle. The task's description from `tasks.md` serves as the "user request" for the cycle.

### Step 1: Announce Task

Output the following:
```
## TASK [T###]: [Description]
```

Mark the corresponding todo as `in_progress`.

### Step 2: Plan

Using the task description, the spec-kit `spec.md`, `plan.md`, and the codebase context gathered during initialization:

1. **Classify Complexity**:
   - **Trivial**: Single-file change, config update, simple model/entity creation. Output `COMPLEXITY: trivial`. Skip the plan audit.
   - **Standard**: Multi-file changes, service implementation, endpoint wiring, integration logic. Output `COMPLEXITY: standard`. Run the plan audit.

2. **Draft plan**: Create a concrete implementation plan for this specific task. Reference the relevant section of `plan.md` and `spec.md`.

3. **Plan Audit** (standard only): Use the `Task` tool to launch the `auditor` subagent with the plan and full context. Auto-incorporate actionable suggestions. Limit to 2 iterations.

### Step 3: Implement

1. **Delegate to Coding Agent**: Use the `Task` tool to launch a `general` subagent with the task plan, full codebase context, and all spec-kit artifacts. The coding agent implements the changes for this task only.

2. **Auto-Format**: Run the project's formatter/linter if one was detected during initialization.

### Step 4: Code Review

1. **Prepare Code Briefing**: Capture `git diff` and full contents of all modified files.

2. **Code Audit**: Use the `Task` tool to launch the `auditor` subagent with the code briefing. Focus on bugs, edge cases, and correctness.

3. **Iterate on Feedback**: If the auditor returns actionable feedback, send it back to the coding agent (resume via `task_id`). Re-run the auditor. Repeat until LGTM or 3 rounds, whichever comes first.

### Step 5: Task Test

1. **Run tests**: Execute the test command detected during initialization.

2. **If tests pass**: Proceed to Step 6.

3. **If tests fail**: Enter the bug-fix loop:
   a. Launch a `general` subagent with the failure output to diagnose and fix.
   b. Re-run the test command.
   c. Repeat up to 3 times.
   d. If still failing after 3 attempts, STOP and present the failure to the user. Do not continue to the next task with broken tests.

### Step 6: Commit

Use the `Task` tool to launch a `general` subagent (git agent) to:
- `git add -A`
- Commit with a message referencing the task ID: `feat(T###): [description]` and include `Co-Authored-By: Claude <noreply@anthropic.com>`
- Do not push yet (push happens after integration test).

### Step 7: Update State

1. Mark the task's todo as `completed`.
2. Update the task line in the feature's `tasks.md` from `- [ ]` to `- [x]`.
3. Update `.auto-dev-speckit/state.json` to move the task from `remaining_tasks` to `completed_tasks`.
4. Output a progress summary:
   ```
   PROGRESS: [completed]/[total] tasks done
   ```

Proceed to the next task.

**Self-Verification**: Before moving to the next task, confirm: Did you delegate implementation to a coding subagent? Did you run the auditor? Did tests pass? Did you commit? If any answer is no, go back and correct.

<example_flow>
Correct tool call sequence for one task:

1. Task(subagent_type="general", prompt="Implement T005: Create User model...") -> task_id
2. Bash("black .") -> auto-format
3. Bash("git diff") -> capture diff
4. Read modified files -> full contents
5. Task(subagent_type="auditor", prompt="Review code for T005...") -> auditor
6. If feedback: Task(task_id=coding_agent_id, prompt="Fix: ...") -> resume
7. Bash("pytest") -> test
8. Task(subagent_type="general", prompt="Git commit T005...") -> git agent
9. Edit tasks.md: mark T005 as [x]
</example_flow>
</task_loop>

---

<integration_test>
## Integration Test & Final Push

After ALL tasks have been completed, perform a final integration validation.

Output the following:
```
## INTEGRATION TEST: All Tasks Complete

COMPLETED TASKS:
- [x] T001: ...
- [x] T002: ...
...
```

Mark the "Integration Test & Final Push" todo as `in_progress`.

### Step 1: Full Test Suite

Run the project's full test suite. If the project has an end-to-end or integration test command (separate from unit tests), run that as well.

### Step 2: If Tests Pass

1. Use the `Task` tool to launch a `general` subagent (git agent) to push all commits to the remote:
   - `git push origin [branch]`

2. **Memory Writeback**: Append learnings to the project's `AGENTS.md` (or create one):
   - Detected test command, formatter
   - Number of spec-kit tasks implemented
   - Key patterns discovered
   - 2-3 bullet points max

3. Output a final summary:
   ```
   ## AUTO-DEV-SPECKIT COMPLETE
   
   Tasks completed: [N]/[N]
   Commits: [N]
   Integration test: PASSED
   Pushed to: origin/[branch]
   ```

### Step 3: If Tests Fail

Enter the bug-fix loop:
1. Launch a `general` subagent with the full integration test failure, the complete diff across all commits, and relevant file contents. The bug-fix agent should look for cross-task interaction bugs.
2. Re-run the full test suite.
3. Repeat up to 3 times.
4. If still failing, STOP and present the failure to the user. Do not push broken code.

Mark the "Integration Test & Final Push" todo as `completed`.
</integration_test>

---

## Guidelines

- **One task at a time**. Each task gets its own complete auto-dev cycle. Do not batch multiple tasks into one implementation pass.
- **Commit after each task**. This creates an atomic, revertable history. Each commit references the spec-kit task ID.
- **Push only after integration test**. Individual tasks are committed locally but only pushed to remote after the final integration test passes.
- **Delegate everything**. Implementation goes to the coding subagent. Code review goes to the auditor. Git operations go to the git subagent. The orchestrator's job is to coordinate.
- **Respect task dependencies**. Process tasks in order. Tasks without the `[P]` flag may depend on prior tasks. Do not reorder.
- **Update tasks.md as you go**. Mark each task `[x]` in the feature's `tasks.md` after it passes its tests and is committed. This enables resumability if the session is interrupted.
- **Do not push broken code**. If any test fails after 3 bug-fix attempts, halt and ask the user.
