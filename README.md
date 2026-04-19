# OpenCode Configuration

Personal configuration for [OpenCode](https://opencode.ai), an open-source AI coding agent for the terminal.

This repo contains agent rules, custom slash commands, MCP server definitions, and permission settings. Clone it to set up OpenCode on a new machine with the same workflow.

## What's included

| File / Directory | Purpose |
|---|---|
| `AGENTS.md` | Global agent rules: model requirements (Claude Opus 4.6, adaptive thinking), correctness-over-cost policy |
| `opencode.jsonc.example` | Main config template (providers, agents, MCP servers, permissions) with secrets redacted |
| `.claude/settings.local.json` | Claude permission settings |
| `commands/auto-dev.md` | Automated dev loop: plan -> review -> implement -> code review -> commit & push |
| `commands/push.md` | Commit and push workflow with conventional commit messages |
| `commands/review-plan.md` | Architecture review of implementation plans via auditor subagent |
| `commands/review-code.md` | Pragmatic code review of uncommitted changes via auditor subagent |
| `commands/review-artifacts.md` | RHOAI QE artifact review workflow |

## Setup on a new machine

### 1. Install OpenCode

```bash
curl -fsSL https://opencode.ai/install | bash
```

### 2. Clone this repo into the OpenCode config directory

```bash
git clone git@github.com:dcohnlif/opencode_config.git ~/.config/opencode
```

If SSH isn't configured, use HTTPS:

```bash
git clone https://github.com/dcohnlif/opencode_config.git ~/.config/opencode
```

### 3. Create your config from the template

```bash
cp ~/.config/opencode/opencode.jsonc.example ~/.config/opencode/opencode.jsonc
```

Edit `opencode.jsonc` and fill in your secrets:

- `JIRA_USERNAME` -- your Jira email
- `JIRA_API_TOKEN` -- your Jira API token ([generate one here](https://id.atlassian.com/manage-profile/security/api-tokens))
- Update the `google-vertex-anthropic` project/location if your GCP setup differs

### 4. Install dependencies

The config uses an OpenCode plugin that needs to be installed:

```bash
cd ~/.config/opencode
npm install
```

### 5. Verify

Run `opencode` in any project directory. Your custom commands should be available via `/auto-dev`, `/push`, `/review-plan`, `/review-code`, and `/review-artifacts`.

## Keeping configs in sync

After making changes on any machine:

```bash
cd ~/.config/opencode
git add -A && git commit -m "update config" && git push
```

On other machines:

```bash
cd ~/.config/opencode && git pull
```

Note: `opencode.jsonc` is gitignored because it contains secrets. Changes to the main config must be manually mirrored via `opencode.jsonc.example`.

## Available commands

### Development workflows

| Command | Description |
|---|---|
| `/parliament` | Full dev loop with human gates: plan -> auditor review -> implement -> dual code audit -> test -> push |
| `/auto-dev` | Hands-free dev loop for trivial tasks (same quality gates, no human intervention) |
| `/speckit-auto-dev` | Batch implementation of spec-kit tasks with per-task auto-dev cycles |
| `/push` | Conventional commit and push to main |
| `/review-plan` | Architecture review of implementation plans |
| `/review-code` | Code review of uncommitted changes |

### Jira integration

| Command | Description |
|---|---|
| `/jira-story` | Create an AIPCC Story with auto-generated description, assigned to next sprint |
| `/file-bug` | File a verified RHOAIENG bug with Playwright reproduction, version-matched doc verification, duplicate detection, and impact analysis |

### BMAD agents (persona-driven)

These agents are from the [BMAD Method](https://github.com/bmadcode/BMAD-METHOD) project (MIT License, see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)). Not affiliated with or endorsed by BMad Code, LLC.

| Command | Agent | Role |
|---|---|---|
| `/bmad-analyst` | Noa | Business Analyst: market research, competitive analysis, requirements |
| `/bmad-pm` | Omer | Product Manager: PRD creation, epics & stories, implementation readiness |
| `/bmad-architect` | Itai | System Architect: technical design, cloud infrastructure |
| `/bmad-ux` | Shira | UX Designer: interaction design, experience strategy |
| `/bmad-writer` | Yael | Tech Writer: documentation, diagrams, doc validation |
| `/bmad-init` | -- | Initialize BMAD project configuration |

### Spec Kit (requirements)

| Command | Description |
|---|---|
| `/speckit.specify` | Define what to build |
| `/speckit.plan` | Create technical plan |
| `/speckit.tasks` | Generate task list |
| `/speckit.implement` | Execute tasks |

## Google Workspace setup

To set up Google Workspace integration (Gmail, Drive, Calendar, Docs, Sheets):

```bash
bash ~/.config/opencode/scripts/setup-google-workspace.sh
```

This interactive script handles prerequisites, OAuth credentials, and config for both OpenCode and Claude Code.
