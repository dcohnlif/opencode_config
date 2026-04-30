# OpenCode Configuration

Personal configuration for [OpenCode](https://opencode.ai), an open-source AI coding agent for the terminal.

This repo contains agent rules, custom slash commands, MCP server integrations, BMAD persona agents, spec-kit workflows, and permission settings. Clone it to set up OpenCode on a new machine with the same workflow. All commands are also mirrored for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/) compatibility.

## What's included

| File / Directory | Purpose |
|---|---|
| `AGENTS.md` | Global agent rules: model requirements, correctness-over-cost policy, test-before-push, external action permissions |
| `opencode.jsonc.example` | Main config template (providers, agents, MCP servers, permissions) with secrets redacted |
| `.claude/` | Claude Code settings and mirrored command definitions |
| `commands/` | All OpenCode custom slash commands |
| `_bmad/` | BMAD Method agent skill tree (MIT Licensed, see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)) |
| `scripts/` | Setup scripts (e.g., Google Workspace MCP) |

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
- `GITHUB_PERSONAL_ACCESS_TOKEN` -- your GitHub token (`gh auth token`)
- Update the `google-vertex-anthropic` project/location if your GCP setup differs

### 4. Install dependencies

```bash
cd ~/.config/opencode
npm install
```

### 5. Verify

Run `opencode` in any project directory. Type `/` to see all available commands.

---

## Commands

### Development workflows

| Command | Description |
|---|---|
| `/parliament` | Full dev loop with human gates: codebase recon -> plan -> dual auditor review -> implement -> dual code audit -> test -> push. 5 phases, 3 human gates. |
| `/auto-dev` | Hands-free dev loop for trivial tasks. Same quality gates as `/parliament` (auditor reviews plan + code) but no human intervention. Classifies task complexity to skip plan audit for trivial changes. |
| `/speckit-auto-dev` | Batch implementation of spec-kit tasks. Runs a full auto-dev cycle per task (plan, implement, review, test, commit), then final integration test before push. |
| `/push` | Conventional commit message generation and push to main |
| `/review-plan` | Architecture review of implementation plans via auditor subagent |
| `/review-code` | Pragmatic code review of uncommitted changes via auditor subagent |
| `/review-artifacts` | RHOAI QE artifact review workflow |
| `/explain` | Code explainer: takes a file/function/module, maps dependencies (callers, callees, imports), generates a Mermaid diagram, and produces a structured explanation with line references |

### Jira integration

| Command | Description |
|---|---|
| `/jira-story` | Create an AIPCC Story with auto-generated description, assigned to next sprint on board 3723 |
| `/file-bug` | File a verified RHOAIENG bug. Includes: Playwright UI reproduction, DOM snapshot capture, version-matched RHOAI doc verification, duplicate/history detection, impact analysis, and human approval gate. 12 phases. |

### BMAD agents (persona-driven)

These agents are from the [BMAD Method](https://github.com/bmadcode/BMAD-METHOD) project (MIT License, see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)). Not affiliated with or endorsed by BMad Code, LLC.

| Command | Role |
|---|---|
| `/bmad-analyst` | Business Analyst (Mary): brainstorming, market research, competitive analysis, requirements elicitation |
| `/bmad-pm` | Product Manager (John): PRD creation/validation, epics & stories, implementation readiness |
| `/bmad-architect` | System Architect (Winston): technical design, distributed systems, cloud infrastructure, architecture decisions |
| `/bmad-ux` | UX Designer (Sally): interaction design, experience strategy, user research |
| `/bmad-writer` | Tech Writer (Paige): documentation, Mermaid diagrams, concept explanations, doc validation |
| `/bmad-validate-prd` | Validate a PRD against BMAD standards through comprehensive review |
| `/bmad-init` | Initialize BMAD project configuration |

### Spec Kit (requirements-driven development)

From [GitHub Spec Kit](https://github.com/github/spec-kit). Run `specify init . --ai opencode` per project for templates.

| Command | Description |
|---|---|
| `/speckit.constitution` | Define project principles and guidelines |
| `/speckit.specify` | Define what to build (requirements and user stories) |
| `/speckit.clarify` | Clarify ambiguities in the spec |
| `/speckit.plan` | Create technical implementation plan |
| `/speckit.analyze` | Cross-artifact consistency check |
| `/speckit.tasks` | Generate actionable task list |
| `/speckit.implement` | Execute all tasks |

---

## MCP Servers

| Server | Package | Purpose | Requires setup? |
|---|---|---|---|
| **RHOAI Docs** | local (`rhoai-documentation-hub`) | Search, read, and verify Red Hat OpenShift AI documentation by version | Requires local clone of rhoai-documentation-hub |
| **Playwright** | `@playwright/mcp` | Browser automation: UI testing, screenshots, DOM inspection, form filling | No |
| **Jira (Atlassian)** | `mcp-atlassian` | Create/search/update Jira issues, sprints, boards, worklogs | Jira API token |
| **Memory** | `@modelcontextprotocol/server-memory` | Persistent knowledge graph across sessions: stores project patterns, decisions, relationships | No |
| **Sequential Thinking** | `@modelcontextprotocol/server-sequentialthinking` | Structured multi-step reasoning for complex analysis and planning | No |
| **Kubernetes** | `mcp-server-kubernetes` | Cluster inspection: pods, deployments, logs, events, operator status via kubectl/oc | `kubeconfig` configured |
| **GitHub** | `@modelcontextprotocol/server-github` | PR reviews, issue management, code search, repository operations | GitHub token |
| **Google Workspace** | `workspace-mcp` | Gmail, Drive, Calendar, Docs, Sheets, Slides (disabled by default) | Google OAuth credentials |

---

## Additional Setup

### Google Workspace

Interactive setup script for Fedora and macOS:

```bash
bash ~/.config/opencode/scripts/setup-google-workspace.sh
```

Handles prerequisites, Google Cloud OAuth credentials, access level (read-only vs full), and configures both OpenCode and Claude Code.

### GitHub MCP

Uses your `gh` CLI token by default. To update:

```bash
gh auth token  # copy the output into opencode.jsonc GITHUB_PERSONAL_ACCESS_TOKEN
```

### Kubernetes MCP

Requires a working `kubeconfig`. If you use OpenShift:

```bash
oc login <cluster-url> -u <user> -p <password>
```

---

## Claude Code Compatibility

All commands are mirrored in `~/.claude/commands/` for Claude Code. The following are available in both OpenCode and Claude Code:

`/parliament`, `/auto-dev`, `/speckit-auto-dev`, `/file-bug`, `/jira-story`, `/push`, `/review-code`, `/review-plan`

---

## Global Agent Rules (`AGENTS.md`)

The following rules apply to every OpenCode session:

- **Identity**: user is David, English, Jira: dcohnlif@redhat.com, team project AIPCC, bug project RHOAIENG
- **Correctness over cost**: never take shortcuts; prefer thorough approaches
- **When in doubt, ask**: clarify intent before guessing
- **Google Workspace**: always use MCP tools, never WebFetch; inform user if MCP unavailable
- **External actions require permission**: never modify Jira/GitHub/Slack without asking first
- **Secrets protection**: never read `.bashrc`, `.env`, `.ssh/`, or shell config files unless asked
- **Test before push**: always ask user to test/run changes before committing
- **Project vs global**: project `AGENTS.md`/`CLAUDE.md` takes precedence over global rules
- **Available commands**: agent suggests `/parliament`, `/auto-dev`, `/auto-dev-tdd`, etc. based on task complexity

See also: [`LEARNINGS.md`](LEARNINGS.md) for accumulated cross-project knowledge.

---

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

---

## Third-Party Notices

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for licensing and attribution for BMAD Method and Spec Kit.
