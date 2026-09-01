# Global Rules

## My Identity

- **Name**: David Cohn Lifshitz
- **Email**: dcohnlif@redhat.com
- **Location**: Israel
- **Role**: Principal Software Engineer at Red Hat, strong QE background
- **Preferred language**: English (non-native speaker)
- **Jira username**: dcohnlif@redhat.com
- **Team project**: AIPCC (board 3723)
- **Team field**: customfield_10001, value `702f36f3-00b7-4faf-b734-ea1b6fb6d097` (Yoni's Team) — set on all AIPCC issues
- **Bug project**: RHOAIENG

## Writing Messages on My Behalf

When asked to write a message, email, Slack post, or any communication for me to send:
- Use a natural, human tone — not formal, not LLM-polished.
- Write as a non-native English speaker: clear and professional, but without overly complex vocabulary, idioms, or perfect grammar. Occasional simple phrasing is fine.
- No bullet-point overload, no corporate speak, no "I hope this message finds you well."
- Keep it concise and direct, like a real person writing quickly.

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

## Jira Access

Jira is accessed via the **Atlassian MCP tools** (prefixed `atlassian_jira_`). The MCP server is pre-configured and authenticated as `dcohnlif@redhat.com`. No manual authentication or API tokens are needed — just call the tools directly.

- **Search issues**: `atlassian_jira_search` with a JQL query (e.g., `project = AIPCC AND assignee = currentUser()`)
- **Create issues**: `atlassian_jira_create_issue` — for AIPCC stories, always include `"customfield_10001": {"id": "702f36f3-00b7-4faf-b734-ea1b6fb6d097"}` in `additional_fields` to set the Team field.
- **Update issues**: `atlassian_jira_update_issue`
- **Transition issues**: `atlassian_jira_get_transitions` first to get transition IDs, then `atlassian_jira_transition_issue`
- **Sprint operations**: Board ID is `3723`. Use `atlassian_jira_get_sprints_from_board` to find sprints.

Do NOT use `curl`, the REST API directly, or any other method to access Jira. The MCP tools handle authentication automatically.

## GitLab Access

All workflow-validation and rhoai repos are hosted on **GitLab** (`gitlab.com` under `redhat/rhel-ai/workflow-validation/`). SSH access is pre-configured via `git@gitlab.com`.

- **Git operations**: Use standard `git` commands (`git clone`, `git pull`, `git fetch`, `git commit`). SSH keys are already configured.
- **GitLab CLI**: `glab` is installed and authenticated as `dcohnlif`. Use it for MR operations: `glab mr create`, `glab mr list`, `glab mr view`.
- **Never auto-push to GitLab** — see the "GitLab: Never Auto-Push" section below.
- **Internal GitLab** (`gitlab.cee.redhat.com`): SSH access also works. Used for `rhoai-docs-source` only.

Do NOT use WebFetch to access GitLab URLs — use `git clone` (SSH) for repo content, or `glab` for API operations.

## Slack Access

Slack is accessed via the **Slack MCP tools** (prefixed `slack_`). The MCP server is pre-configured and authenticated. No manual authentication needed — just call the tools directly.

- **Read a thread**: `slack_get_thread` with `channel_id` and `thread_ts`. Extract these from Slack URLs: `https://redhat-internal.slack.com/archives/<channel_id>/p<thread_ts>` (insert a `.` before the last 6 digits of the timestamp, e.g., `p1783898898889269` → `1783898898.889269`).
- **Read channel history**: `slack_get_channel_history` with `channel_id`
- **Search messages**: `slack_search_messages` with a query string
- **Post a message**: `slack_post_message` (requires explicit user permission — see External Actions rule below)
- **Find a channel**: `slack_get_channel_id_by_name` with the channel name

Do NOT use WebFetch to access Slack URLs — it cannot authenticate. Always use the Slack MCP tools.

## Google Workspace Access

When the user asks to access, read, or interact with Google Docs, Google Sheets, Google Drive, Gmail, or Google Calendar, NEVER use WebFetch. WebFetch cannot access Google Workspace content (it returns login pages or errors). Instead, always use the Google Workspace MCP tools (prefixed with `google-workspace` or `mcp__google-workspace__`). These tools authenticate via OAuth and provide direct access to the user's Google Workspace content.

If the Google Workspace MCP tools are not available in the current session, inform the user that the MCP server needs to be enabled. Do not silently fall back to WebFetch.

## External Actions Require Explicit Permission

Never modify external systems (Jira, GitHub, GitLab, Slack, email) without asking first. Present what you want to do and wait for confirmation. Exceptions: commands that explicitly instruct external actions (e.g., `/file-bug`) and read-only queries.

## GitLab: Never Auto-Push

**CRITICAL**: Never automatically push commits to GitLab remotes. GitLab repos require merge requests with pipeline runs and approvals before merging. The workflow for GitLab repos is:

1. **Commit locally** — commit changes to the local branch as usual.
2. **Summarize** — after committing, show a summary of all uncommitted changes in the repo.
3. **Ask** — ask the user: "Do you want me to push these commits and create a merge request?"
4. **Only push if the user confirms** — then push to a feature branch and create an MR.

This applies to ALL sessions and ALL commands (`/auto-dev`, `/parliament`, `/auto-dev-tdd`, `/speckit-auto-dev`, `/push`, and ad-hoc work). No exceptions.

**GitHub repos are exempt** — for GitHub remotes (e.g., this opencode config repo), commit and push immediately after any change.

To detect which remote type you're on: `git remote get-url origin`. If it contains `gitlab`, follow the GitLab rules. If it contains `github`, push immediately.

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

## Delegate to Subagents Aggressively

Use subagents (Task tool) for any work whose intermediate steps are not needed in the main session's context. The main session should stay focused on decisions, synthesis, and direct user interaction — not raw data gathering, file reading, or exploratory queries.

Delegate when:
- Exploring a codebase or gathering context (more than 3-5 files)
- Running database queries or API calls to collect data for analysis
- Reviewing artifacts or logs as a prerequisite for another task
- Any multi-step research where only the conclusion matters

Keep in the main session:
- File edits and code changes
- Direct user Q&A that needs conversational continuity
- Tool calls whose output the user needs to see immediately
- Decisions that depend on prior conversation context
- Multi-phase pipelines where raw data from early phases is composed verbatim into later output (version strings, error messages, field values flowing into Jira descriptions or reports)

## Don't Over-Engineer

Only make changes that are directly requested or clearly necessary. Don't add features, refactor surrounding code, introduce abstractions, or build in flexibility that wasn't asked for. A bug fix doesn't need the surrounding code cleaned up. A simple feature doesn't need extra configurability. The right amount of complexity is the minimum needed for the current task.

- Clean up only your own mess: remove imports, variables, and functions that your changes made unused. Don't remove pre-existing dead code unless asked — mention it instead.
- Match the existing code style even if you'd do it differently. Every changed line should trace directly to the user's request.

## Workflow Validation Credentials

The following environment variables are set globally and available in all sessions. Do not ask the user for these values — they are already configured.

- **`JIRA_TEAM_EMAIL`** — Email for Jira API access used by workflow-validation repos (distinct from the MCP-based Jira access above, which is for interactive use).
- **`JIRA_TEAM_PAT`** — Personal access token for Jira API access used by workflow-validation repos.
- **`JENKINS_TOKEN`** — Token for accessing the internal Jenkins instance (URL available via VPN/SSO).

These are used by the workflow-validation tooling (director, RCA agent, insights) for programmatic Jira and Jenkins access. When scripts or configs in those repos reference Jira credentials or Jenkins tokens, use these env vars — do not hardcode values or prompt the user.

- **Running workflows**: `~/GIT/scripts/run-journey.sh <journey-name> [journey-name...]`. Available journeys are in `~/GIT/rhoai-customer-workflows/tests/user-journeys/`.

## Python & LLM SDK Conventions

- When running Python scripts, always use `uv run` (not `python3` or `pip`). For one-off scripts with dependencies, use `uv run --with <package>`. For installed tools, use `uvx`.
- When making Anthropic API calls from Python, use the Anthropic SDK with Vertex AI backend (`from anthropic import AnthropicVertex`). The credentials are already configured via `GOOGLE_APPLICATION_CREDENTIALS` and `GOOGLE_CLOUD_PROJECT` environment variables.

## General Learnings

See `LEARNINGS.md` for accumulated cross-project knowledge covering AI-driven test spec generation, autonomous test execution, QE artifact review, MCP tool reliability, and infrastructure/environment pitfalls.
