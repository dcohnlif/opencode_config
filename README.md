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
