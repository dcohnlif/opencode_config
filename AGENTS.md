# Global Rules

## My Identity

- **Name**: David Cohn Lifshitz
- **Email**: dcohnlif@redhat.com
- **Location**: Israel
- **Role**: Principal Software Engineer at Red Hat, strong QE background
- **Preferred language**: English
- **Jira username**: dcohnlif@redhat.com
- **Team project**: AIPCC (board 3723)
- **Bug project**: RHOAIENG

**What I do**: I lead the AIPCC Workflow Validation team. We build an AI-driven testing platform for Red Hat OpenShift AI (RHOAI). The platform discovers customer usage patterns from Jira/support cases, generates test scenarios as prose Markdown specs, and executes them using an AI agent that drives a real browser via Playwright -- no selectors, no scripted clicks. We validate customer workflows, user journeys, new features, documentation accuracy, and tutorials. Key repos live under `~/GIT/` (workflow-validation-director, workflow-insights, rhoai-customer-workflows, rhoai-documentation-hub).

## Priority: Correctness Over Cost

I do not care about token cost, execution time, or convenience shortcuts. Always optimize for **robustness and correctness** above all else.

- Never take shortcuts to save tokens, time, or API calls. When multiple implementation paths exist, choose the most robust one, not the easiest or cheapest.
- Read all relevant files fully rather than skimming. Search thoroughly rather than guessing. When uncertain, investigate and verify rather than making assumptions.
- When making LLM API calls for one-time tasks (classification, analysis, generation), always use the most capable model available. Do not use cheaper/faster models to save tokens -- quality of output matters more than cost.

## Parallelize Independent Work

When launching multiple subagents or tasks that don't depend on each other, run them in parallel (multiple Task calls in a single message). Sequential execution wastes time when tasks are independent. For example: reading multiple files, running explore + reading AGENTS.md, or launching dual auditors.

## When in Doubt, Ask

If you are unsure about the user's intent, ask a clarifying question rather than guessing. This includes: which file to edit, what approach to take, whether to delete or modify, whether a change is in scope, and what the expected behavior should be. A 10-second question saves minutes of wasted work.

## Google Workspace Access

When the user asks to access, read, or interact with Google Docs, Google Sheets, Google Drive, Gmail, or Google Calendar, NEVER use WebFetch. WebFetch cannot access Google Workspace content (it returns login pages or errors). Instead, always use the Google Workspace MCP tools (prefixed with `google-workspace` or `mcp__google-workspace__`). These tools authenticate via OAuth and provide direct access to the user's Google Workspace content.

If the Google Workspace MCP tools are not available in the current session, inform the user that the MCP server needs to be enabled. Do not silently fall back to WebFetch.

## External Actions Require Explicit Permission

Never modify external systems (Jira, GitHub, GitLab, Slack, email) without asking first. Present what you want to do and wait for confirmation. Exceptions: commands that explicitly instruct external actions (e.g., `/file-bug`, `/auto-dev` Phase 4 git push) and read-only queries.

## Secrets Protection

Never read `~/.bashrc`, `~/.bash_profile`, `~/.zshrc`, `~/.profile`, or any shell config file unless the user explicitly asks. These files contain secrets (API tokens, passwords, PATs). The same applies to `~/.env`, `~/.netrc`, `~/.ssh/`, `~/.aws/`, and `~/.config/gcloud/`. If you need a specific value from one of these files, ask the user to provide it rather than reading the file directly.

## Test Before Push

Whenever you build a new feature, fix a bug, or make any code change that will be pushed to git, always ask the user if they want to run/test the feature before pushing. Run the test, fix failures, and repeat until passing. Only then commit and push. The `/parliament`, `/auto-dev`, and `/speckit-auto-dev` commands have their own built-in testing phases and are exempt from this rule.

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

## Python & LLM SDK Conventions

- When running Python scripts, always use `uv run` (not `python3` or `pip`). For one-off scripts with dependencies, use `uv run --with <package>`. For installed tools, use `uvx`.
- When making Anthropic API calls from Python, use the Anthropic SDK with Vertex AI backend (`from anthropic import AnthropicVertex`). The credentials are already configured via `GOOGLE_APPLICATION_CREDENTIALS` and `GOOGLE_CLOUD_PROJECT` environment variables.

## General Learnings

See `LEARNINGS.md` for accumulated cross-project knowledge covering AI-driven test spec generation, autonomous test execution, QE artifact review, MCP tool reliability, and infrastructure/environment pitfalls.
