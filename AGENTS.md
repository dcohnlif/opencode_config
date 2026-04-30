# Global Rules

## My Identity

- **Name**: David
- **Preferred language**: English
- **Jira username**: dcohnlif@redhat.com
- **Team project**: AIPCC (board 3723)
- **Bug project**: RHOAIENG
- **Reporter account**: workflow-validation@redhat.com

## Priority: Correctness Over Cost

I do not care about token cost, execution time, or convenience shortcuts. Always optimize for **robustness and correctness** above all else.

- Never take shortcuts to save tokens, time, or API calls.
- When multiple implementation paths exist, choose the most robust one, not the easiest or cheapest.
- Read all relevant files fully rather than skimming. Search thoroughly rather than guessing.
- When uncertain, investigate and verify rather than making assumptions.
- When making LLM API calls for one-time tasks (classification, analysis, generation), always use the most capable model available. Do not use cheaper/faster models to save tokens -- quality of output matters more than cost.

## Parallelize Independent Work

When launching multiple subagents or tasks that don't depend on each other, run them in parallel (multiple Task calls in a single message). Sequential execution wastes time when tasks are independent. For example: reading multiple files, running explore + reading AGENTS.md, or launching dual auditors.

## When in Doubt, Ask

If you are unsure about the user's intent, ask a clarifying question rather than guessing. This includes: which file to edit, what approach to take, whether to delete or modify, whether a change is in scope, and what the expected behavior should be. A 10-second question saves minutes of wasted work.

## Google Workspace Access

When the user asks to access, read, or interact with Google Docs, Google Sheets, Google Drive, Gmail, or Google Calendar, NEVER use WebFetch. WebFetch cannot access Google Workspace content (it returns login pages or errors). Instead, always use the Google Workspace MCP tools (prefixed with `google-workspace` or `mcp__google-workspace__`). These tools authenticate via OAuth and provide direct access to the user's Google Workspace content.

If the Google Workspace MCP tools are not available in the current session, inform the user that the MCP server needs to be enabled. Do not silently fall back to WebFetch.

## External Actions Require Explicit Permission

NEVER perform actions on external systems (Jira, GitHub, GitLab, Slack, email, or any API that posts/modifies data under the user's identity) without explicit permission. This includes:

- Creating, updating, or commenting on Jira issues
- Creating pull/merge requests
- Posting to any communication channel
- Modifying any resource outside the local filesystem and git

**Always ask first.** Present what you want to do and wait for confirmation. The only exceptions are:
- Commands that explicitly instruct external actions (e.g., `/file-bug`, `/auto-dev` Phase 4 git push)
- Read-only queries (searching Jira, fetching docs, reading GitHub code)

## Secrets Protection

Never read `~/.bashrc`, `~/.bash_profile`, `~/.zshrc`, `~/.profile`, or any shell config file unless the user explicitly asks. These files contain secrets (API tokens, passwords, PATs). The same applies to `~/.env`, `~/.netrc`, `~/.ssh/`, `~/.aws/`, and `~/.config/gcloud/`. If you need a specific value from one of these files, ask the user to provide it rather than reading the file directly.

## Test Before Push

Whenever you build a new feature, fix a bug, or make any code change that will be pushed to git, always ask the user if they want to run/test the feature before pushing. Follow this flow:

1. Implement the change.
2. Ask the user: "Want me to run this to test it before pushing?"
3. If yes: run the feature or test command and show the results.
4. If the results are not as expected: fix the issue, re-run, and repeat until it works.
5. Only after the user confirms the results are correct (or the tests pass), proceed with committing and pushing.

This applies to all workflows -- direct prompts, `/push`, and any other code change flow. The `/parliament`, `/auto-dev`, and `/speckit-auto-dev` commands have their own built-in testing phases and are exempt from this rule.

## Project vs Global Rules

If the current project has its own `AGENTS.md` (or `CLAUDE.md`), its rules take precedence over this global file for project-specific decisions (test commands, patterns, conventions, architecture). This global file provides defaults and cross-project behavioral rules.

## Available Commands

| Command | When to use |
|---|---|
| `/parliament` | Complex features requiring human review at each stage |
| `/auto-dev` | Trivial/small changes, hands-free |
| `/auto-dev-tdd` | Medium-to-large features with an architecture doc, test-driven |
| `/speckit-auto-dev` | Batch implementation of spec-kit task lists |
| `/file-bug` | File a verified RHOAIENG bug from test failure artifacts |
| `/jira-story` | Create an AIPCC story assigned to the next sprint |
| `/kvetch` | Fun code review by Rivka the Yiddishe Mame |
| `/explain` | Explain a file/function/module with dependency diagram |

When the user asks to build something and doesn't specify a workflow, suggest the appropriate command based on task complexity.

## Scope Investigations

When exploring a codebase to gather context or answer a question, scope the search narrowly or delegate to a subagent. Unscoped exploration (reading dozens of files) fills the context window with irrelevant content and degrades performance. If the investigation requires reading more than 5-10 files, use a subagent so the research runs in an isolated context and returns a summary.

## Don't Over-Engineer

Only make changes that are directly requested or clearly necessary. Don't add features, refactor surrounding code, introduce abstractions, or build in flexibility that wasn't asked for. A bug fix doesn't need the surrounding code cleaned up. A simple feature doesn't need extra configurability. The right amount of complexity is the minimum needed for the current task.

## General Learnings

See `LEARNINGS.md` for accumulated cross-project knowledge covering AI-driven test spec generation, autonomous test execution, QE artifact review, MCP tool reliability, and infrastructure/environment pitfalls.
