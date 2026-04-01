---
description: Full parliament development loop with human gates (Maker vs. Checker). For trivial tasks use /auto-dev instead.
---

# Parliament Workflow

This command orchestrates a complete development loop using dedicated subagents: an explore agent for codebase mapping, the primary agent for planning, a coding agent for implementation, dual auditors as Checkers, and a git agent for commit/push.

Execute every phase in strict sequential order (Phase 0 through 4). Each phase must fully complete -- including all auditor invocations and user approvals -- before the next phase begins.

---

## Workflow Initialization

Before doing anything else, complete these two steps:

1. Output this header exactly:
   ```
   ## WORKFLOW: PARLIAMENT
   ```

2. Use the `TodoWrite` tool to create the following todos, all set to `pending`:
   - Phase 0: Codebase Reconnaissance
   - Phase 1: Planning & Architecture Review
   - Phase 2: Implementation & Code Review
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
   - Locate existing test files and test commands (e.g., `pytest`, `npm test`, `make test`).
   - Detect code formatters/linters in use (e.g., `black`, `prettier`, `ruff`, `gofmt`, `rustfmt`).
   - Note coding patterns and conventions used in the relevant areas.
   - Return a structured summary with: relevant files (with paths), key functions/classes, dependencies, test locations, detected test command, detected formatter/linter, and patterns to follow.

3. **Fallback Context**: If the explore agent returns fewer than 2 relevant files, the exploration was too narrow. Read the full project directory tree and any entry-point files (e.g., `main.py`, `index.ts`, `main.go`, `app.py`, `src/lib.rs`) to build broader context.

4. **Embed Context**: Carry the project context, exploration results, detected test command, and detected formatter forward into all subsequent phases.

**Self-Verification**: Before leaving this phase, confirm: Do you have at least 2 relevant files identified? Do you know the test command and formatter? If not, re-run exploration with broader scope.

Mark Phase 0 todo as `completed`. Write initial state to `.parliament/state.json`:
```json
{"phase_0": "completed", "phase_1": "pending", "phase_2": "pending", "phase_3": "pending", "phase_4": "pending"}
```
</phase_0>

---

<phase_1>
## Phase 1: Planning & Architecture Review

The purpose of this phase is to produce a reviewed, human-approved plan before any code is written. This prevents wasted implementation effort on a flawed approach.

**Transition Protocol**: Output the following, then mark Phase 1 todo as `in_progress`:
```
## ENTERING PHASE 1: Planning & Architecture Review

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
```

1. **Requirements Clarification**: If the user's request is vague, ambiguous, or could be interpreted multiple ways, ask up to 3 clarifying questions before drafting the plan. Use the `question` tool to present options when applicable. If the request is already clear and specific, skip this step.

2. **Analyze & Draft**: Using the codebase context from Phase 0, analyze the user's request and draft a concrete implementation plan.

3. **The Briefing**: Prepare a briefing for the auditor. Include:
   - The problem/request.
   - The proposed plan.
   - Codebase context from Phase 0 (project structure, relevant files, patterns).
   - Full contents of all relevant files directly in the briefing. Maximize context over brevity.
   - Specific areas of concern (e.g., security, edge cases, performance).

4. **Plan Audit**: Use the `Task` tool to launch the `auditor` subagent with the briefing. The auditor provides an independent check on the plan's soundness before implementation begins, catching architectural mistakes that are expensive to fix later.

5. **Human Control Gate 1**: Present the auditor's structured feedback (Assessment, Assumptions, Alternatives, Risks) to the user. STOP and WAIT for user input. Ask which suggestions to incorporate. Do not proceed until the user responds. Limit the plan review loop to a maximum of 3 iterations.

6. **Persist Plan**: Write the finalized plan to `.parliament/plan.md` in the workspace root. Include the original request, codebase context summary, the approved plan, and a summary of auditor feedback incorporated. This enables session resumability.

**Self-Verification**: Before leaving this phase, confirm: Did you run the auditor via the Task tool? Did the user explicitly approve? If either answer is no, do not proceed.

Mark Phase 1 todo as `completed`. Update `.parliament/state.json`:
```json
{"phase_0": "completed", "phase_1": "completed", "phase_2": "pending", "phase_3": "pending", "phase_4": "pending"}
```

**STOP: Do not begin Phase 2 until the user has approved the plan.**
</phase_1>

---

<phase_2>
## Phase 2: Implementation & Code Review

The purpose of this phase is to produce reviewed, high-quality code. The coding agent is a separate subagent so that the orchestrator retains a clean view of the overall workflow. The dual auditors catch different classes of bugs.

**Transition Protocol**: Output the following, then mark Phase 2 todo as `in_progress`:
```
## ENTERING PHASE 2: Implementation & Code Review

PRE-FLIGHT CHECK:
- [x] Phase 0: Codebase mapped
- [x] Phase 1: Plan drafted and auditor reviewed
- [x] Phase 1: User approved plan
```

1. **Implement via Coding Agent**: Use the `Task` tool to launch a `general` subagent (the "coding agent") with the approved plan and full codebase context from Phase 0. The coding agent implements the changes. Delegating to a subagent prevents the orchestrator from losing track of the overall workflow while deep in implementation details.

2. **Auto-Format**: After the coding agent completes, run the project's formatter/linter if one was detected during Phase 0 (e.g., `black .`, `prettier --write .`, `ruff format .`). This ensures the auditors focus on logic and correctness, not style. Skip if no formatter was detected.

3. **The Code Briefing**: Prepare an exhaustive briefing for the auditors. Include the complete `git diff` of all uncommitted changes, and the full contents of all modified files.

4. **Dual Code Audit**: Launch TWO `auditor` subagents in parallel using the `Task` tool (two Task calls in a single message). Running two auditors with different focuses catches more bugs than a single pass:
   - **Auditor A (Correctness)**: Focus on logic bugs, edge cases, error handling, off-by-one errors, unhandled exceptions, and functional correctness. Ignore styling.
   - **Auditor B (Security & Architecture)**: Focus on security vulnerabilities (path traversal, injection, resource leaks, auth bypasses), architectural concerns, performance issues, and API misuse.
   
   Merge both auditors' findings into a single consolidated review.

5. **Iterate on Feedback**: If either auditor returns actionable feedback (not LGTM), send the consolidated feedback to the coding agent (resume the same Task session using `task_id`) and have it apply fixes. Then re-run both auditors on the updated code. Repeat until both auditors respond LGTM or the loop has run 3 times, whichever comes first.

6. **Human Control Gate 2**: Present the consolidated code review feedback to the user. STOP and WAIT for user input. Ask which fixes to apply. Do not proceed until the user responds.

**Self-Verification**: Before leaving this phase, confirm: Did you delegate implementation to a coding subagent via the Task tool (not implement directly)? Did you run both auditors? Did the user approve? If any answer is no, go back and correct.

<example_flow>
Here is a concrete example of the correct Phase 2 tool call sequence:

1. Task(subagent_type="general", prompt="Implement the approved plan...") -> receives task_id
2. Bash("black .") -> auto-format
3. Bash("git diff") -> capture diff for briefing
4. Read modified files -> capture full contents
5. Task(subagent_type="auditor", prompt="[Correctness focus] ...") AND Task(subagent_type="auditor", prompt="[Security focus] ...") -> two parallel calls
6. If feedback: Task(task_id=coding_agent_id, prompt="Fix these issues...") -> resume coding agent
7. Repeat auditors if needed
8. Present results to user, wait for approval
</example_flow>

Mark Phase 2 todo as `completed`. Update `.parliament/state.json`:
```json
{"phase_0": "completed", "phase_1": "completed", "phase_2": "completed", "phase_3": "pending", "phase_4": "pending"}
```

**STOP: Do not begin Phase 3 until the user has approved the code review results.**
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
- [x] Phase 1: Plan drafted and auditor reviewed
- [x] Phase 1: User approved plan
- [x] Phase 2: Coding agent implemented changes
- [x] Phase 2: Dual auditor code review passed (LGTM or 3 rounds)
- [x] Phase 2: User approved code review
```

1. Apply any final approved fixes.

2. **Human Control Gate 3**: Ask the user what command to run to test the changes (e.g., a test suite, a script, a build command). STOP and WAIT for user input. Do not proceed until the user responds.

3. **Run the test**: Execute the test command provided by the user.

4. **If the test passes**: Proceed to Phase 4.

5. **If the test fails**: Enter the bug-fix loop:
   a. Use the `Task` tool to launch a `general` subagent (the "bug-fix agent") with the test failure output, the full diff, and the relevant file contents. The bug-fix agent diagnoses and fixes the issue.
   b. Re-run the same test command automatically (no need to ask the user).
   c. If the test passes, proceed to Phase 4.
   d. If the test fails again, repeat from step (a). Limit the bug-fix loop to 3 iterations.
   e. If after 3 iterations the test still fails, STOP and present the failure to the user. Ask how to proceed. Do not continue to Phase 4.

Mark Phase 3 todo as `completed`. Update `.parliament/state.json`:
```json
{"phase_0": "completed", "phase_1": "completed", "phase_2": "completed", "phase_3": "completed", "phase_4": "pending"}
```

**STOP: Do not begin Phase 4 until the test has passed.**
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
- [x] Phase 1: Plan drafted and auditor reviewed
- [x] Phase 1: User approved plan
- [x] Phase 2: Coding agent implemented changes
- [x] Phase 2: Dual auditor code review passed (LGTM or 3 rounds)
- [x] Phase 2: User approved code review
- [x] Phase 3: Tests passed
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

Mark Phase 4 todo as `completed`. Update `.parliament/state.json`:
```json
{"phase_0": "completed", "phase_1": "completed", "phase_2": "completed", "phase_3": "completed", "phase_4": "completed"}
```
</phase_4>

---

## Guidelines

The following guidelines explain the reasoning behind this workflow's structure. Understanding the "why" helps you follow it correctly:

- **Always map the codebase first** (Phase 0). Planning without context leads to flawed plans that waste implementation effort.
- **Delegate implementation to a coding subagent**. The orchestrator needs to maintain a high-level view of the workflow. Getting deep into code implementation causes it to lose track of remaining phases.
- **Run auditors before presenting to the user**. The auditors catch issues the coding agent missed. Skipping them means the user reviews unvetted code.
- **Do not combine phases**. Each phase has a distinct purpose. Merging them (e.g., implementing while still planning) undermines the quality gates.
- **Wait at STOP barriers**. The human gates exist because certain decisions (plan direction, which fixes to apply) require human judgment. Proceeding without input risks wasted work.
- **Delegate git operations to a git subagent**. This isolation prevents the orchestrator from accidentally modifying code while staging/committing.
- **Write state to `.parliament/state.json`**. This creates a verifiable record of phase completion that prevents phases from being skipped.
